import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'package:gps_map_camera/services/storage_services.dart';

// ─── Cache keys (same idea as previous app; namespaced for this project) ─────

const _latitudeKey = 'location_svc_latitude';
const _longitudeKey = 'location_svc_longitude';
const _addressKey = 'location_svc_address';
const _altitudeKey = 'location_svc_altitude';
const _accuracyKey = 'location_svc_accuracy';
const _headingKey = 'location_svc_heading';

/// One resolved GPS + address snapshot for the camera stamp.
class LocationSnapshot {
  final GpsCoordinate coordinate;
  final String address;
  final double? compassBearing;

  const LocationSnapshot({required this.coordinate, required this.address, this.compassBearing});
}

/// Why live GPS could not be used (no [BuildContext] — UI can map this to dialogs).
enum LocationAccessIssue { none, serviceDisabled, denied, deniedForever }

/// Fetches GPS, reverse-geocodes via [placemarkFromCoordinates], caches last good fix.
class LocationService {
  StreamSubscription<Position>? _positionSub;
  Timer? _geocodeDebounce;
  double? _lastGeocodeLat;
  double? _lastGeocodeLng;
  DateTime? _lastGeocodeAt;
  String _lastResolvedAddress = '';

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _positionTimeout = Duration(seconds: 20);
  static const Duration _geocodeTimeout = Duration(seconds: 10);
  static const Duration _minGeocodeGap = Duration(seconds: 45);
  static const double _minGeocodeMoveMeters = 75;

  /// Check device location service + app permission (does not show dialogs).
  Future<LocationAccessIssue> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccessIssue.serviceDisabled;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied) return LocationAccessIssue.denied;
    if (p == LocationPermission.deniedForever) return LocationAccessIssue.deniedForever;
    return LocationAccessIssue.none;
  }

  String _accessMessage(LocationAccessIssue issue) {
    switch (issue) {
      case LocationAccessIssue.serviceDisabled:
        return 'Turn on location services';
      case LocationAccessIssue.denied:
        return 'Location permission denied';
      case LocationAccessIssue.deniedForever:
        return 'Location blocked — enable in Settings';
      case LocationAccessIssue.none:
        return '';
    }
  }

  /// Last saved snapshot from disk (no GPS).
  Future<LocationSnapshot?> loadCachedSnapshot() async {
    final latStr = await SharedPrefHelper.getString(_latitudeKey);
    final lngStr = await SharedPrefHelper.getString(_longitudeKey);
    if (latStr == null || lngStr == null) return null;
    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    if (lat == null || lng == null) return null;

    final altStr = await SharedPrefHelper.getString(_altitudeKey);
    final accStr = await SharedPrefHelper.getString(_accuracyKey);
    final hStr = await SharedPrefHelper.getString(_headingKey);
    final address = await SharedPrefHelper.getString(_addressKey) ?? '';
    _lastResolvedAddress = address;

    return LocationSnapshot(
      coordinate: GpsCoordinate(
        latitude: lat,
        longitude: lng,
        altitude: altStr != null ? double.tryParse(altStr) : null,
        accuracy: accStr != null ? double.tryParse(accStr) : null,
      ),
      address: address.isEmpty ? 'Cached coordinates (no address)' : address,
      compassBearing: hStr != null ? double.tryParse(hStr) : null,
    );
  }

  Future<void> _persistSnapshot(LocationSnapshot s) async {
    await SharedPrefHelper.setString(_latitudeKey, s.coordinate.latitude.toString());
    await SharedPrefHelper.setString(_longitudeKey, s.coordinate.longitude.toString());
    await SharedPrefHelper.setString(_addressKey, s.address);
    if (s.coordinate.altitude != null) {
      await SharedPrefHelper.setString(_altitudeKey, s.coordinate.altitude!.toString());
    }
    if (s.coordinate.accuracy != null) {
      await SharedPrefHelper.setString(_accuracyKey, s.coordinate.accuracy!.toString());
    }
    if (s.compassBearing != null) {
      await SharedPrefHelper.setString(_headingKey, s.compassBearing!.toString());
    }
  }

  String _formatAddress(Placemark p) {
    final parts = <String?>[
      p.thoroughfare != null && p.subThoroughfare != null ? '${p.subThoroughfare} ${p.thoroughfare}' : p.street ?? p.thoroughfare,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.join(', ');
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng).timeout(_geocodeTimeout);
      if (list.isEmpty) return '';
      return _formatAddress(list.first);
    } catch (_) {
      return '';
    }
  }

  bool _shouldGeocodeAgain(double lat, double lng) {
    final now = DateTime.now();
    if (_lastGeocodeAt == null || _lastGeocodeLat == null || _lastGeocodeLng == null) {
      return true;
    }
    if (now.difference(_lastGeocodeAt!) < _minGeocodeGap) {
      final moved = Geolocator.distanceBetween(_lastGeocodeLat!, _lastGeocodeLng!, lat, lng);
      if (moved < _minGeocodeMoveMeters) return false;
    }
    return true;
  }

  Future<LocationSnapshot> _snapshotFromPosition(Position pos, {bool forceGeocode = false}) async {
    final coord = GpsCoordinate(latitude: pos.latitude, longitude: pos.longitude, altitude: pos.altitude, accuracy: pos.accuracy);
    double? bearing;
    if (pos.heading >= 0 && pos.speed > 0.5) {
      bearing = pos.heading;
    }

    var address = _lastResolvedAddress;
    if (forceGeocode || _shouldGeocodeAgain(pos.latitude, pos.longitude)) {
      final g = await _reverseGeocode(pos.latitude, pos.longitude);
      if (g.isNotEmpty) {
        address = g;
        _lastResolvedAddress = g;
      }
      _lastGeocodeLat = pos.latitude;
      _lastGeocodeLng = pos.longitude;
      _lastGeocodeAt = DateTime.now();
    }
    if (address.isEmpty) {
      address = '${pos.latitude.toStringAsFixed(6)}°, ${pos.longitude.toStringAsFixed(6)}°';
    }

    return LocationSnapshot(coordinate: coord, address: address, compassBearing: bearing);
  }

  /// Single high-accuracy fix + geocode + cache (with retries like the old controller).
  Future<({LocationSnapshot? snapshot, String? errorMessage})> fetchCurrentLocation({int retryCount = 0}) async {
    final access = await checkAccess();
    if (access != LocationAccessIssue.none) {
      return (snapshot: null, errorMessage: _accessMessage(access));
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(_positionTimeout);

      final snapshot = await _snapshotFromPosition(pos, forceGeocode: true);
      await _persistSnapshot(snapshot);
      return (snapshot: snapshot, errorMessage: null);
    } catch (e) {
      final msg = e.toString();
      final recoverable = msg.contains('TimeoutException') || msg.contains('IO_ERROR') || msg.contains('Service not available');

      if (recoverable && retryCount < _maxRetries) {
        await Future<void>.delayed(_retryDelay);
        return fetchCurrentLocation(retryCount: retryCount + 1);
      }

      final cached = await loadCachedSnapshot();
      if (cached != null) {
        return (snapshot: cached, errorMessage: null);
      }
      return (snapshot: null, errorMessage: 'Could not get location');
    }
  }

  /// Live updates: moves coordinates often; reverse-geocode is debounced / distance-throttled.
  void startWatching(void Function(LocationSnapshot s) onData, {void Function(String message)? onError}) {
    stopWatching();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
        ).listen((pos) {
          _geocodeDebounce?.cancel();
          _geocodeDebounce = Timer(const Duration(milliseconds: 800), () async {
            try {
              final snap = await _snapshotFromPosition(pos, forceGeocode: false);
              await _persistSnapshot(snap);
              onData(snap);
            } catch (e) {
              onError?.call(e.toString());
            }
          });
        }, onError: (e) => onError?.call(e.toString()));
  }

  void stopWatching() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  void dispose() => stopWatching();
}
