import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:gps_map_camera/models/app_models.dart';
import 'package:gps_map_camera/services/storage_services.dart';

// IMPORTANT: Use restricted API key
const _googleApiKey = "AIzaSyBdWFYZ_l85RzP0Kgjinf2MiOqfQ0XW-cs";

// ─── Cache keys ─────────────────────────────────────────────

const _latitudeKey = 'location_svc_latitude';
const _longitudeKey = 'location_svc_longitude';
const _addressKey = 'location_svc_address';

class LocationSnapshot {
  final GpsCoordinate coordinate;
  final String address;
  final double? compassBearing;

  const LocationSnapshot({required this.coordinate, required this.address, this.compassBearing});
}

enum LocationAccessIssue { none, serviceDisabled, denied, deniedForever }

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

  // ─────────────────────────────────────────────

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
        return 'Enable location in settings';
      case LocationAccessIssue.none:
        return '';
    }
  }

  // ─────────────────────────────────────────────
  // GOOGLE GEOCODING (PRIMARY)

  Future<String> _reverseGeocodeGoogle(double lat, double lng) async {
    final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleApiKey";

    try {
      final res = await http.get(Uri.parse(url)).timeout(_geocodeTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          return data["results"][0]["formatted_address"] ?? '';
        }
      }
    } catch (_) {}

    return '';
  }

  // ─────────────────────────────────────────────
  // FALLBACK (OLD METHOD)

  String _formatAddress(Placemark p) {
    final parts = <String?>[
      p.name,
      p.subThoroughfare,
      p.thoroughfare,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return parts.join(', ');
  }

  Future<String> _reverseGeocodeFallback(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng).timeout(_geocodeTimeout);
      if (list.isEmpty) return '';
      return _formatAddress(list.first);
    } catch (_) {
      return '';
    }
  }

  // ─────────────────────────────────────────────
  // 🔥 HYBRID GEOCODE (BEST)

  Future<String> _reverseGeocode(double lat, double lng) async {
    // 1️⃣ Try Google API
    final googleAddress = await _reverseGeocodeGoogle(lat, lng);
    if (googleAddress.isNotEmpty) return googleAddress;

    // 2️⃣ Fallback
    return await _reverseGeocodeFallback(lat, lng);
  }

  // ─────────────────────────────────────────────

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
      address = '${pos.latitude}, ${pos.longitude}';
    }

    return LocationSnapshot(coordinate: coord, address: address, compassBearing: bearing);
  }

  // ─────────────────────────────────────────────

  Future<LocationSnapshot?> loadCachedSnapshot() async {
    final latStr = await SharedPrefHelper.getString(_latitudeKey);
    final lngStr = await SharedPrefHelper.getString(_longitudeKey);

    if (latStr == null || lngStr == null) return null;

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);

    if (lat == null || lng == null) return null;

    final address = await SharedPrefHelper.getString(_addressKey) ?? '';

    return LocationSnapshot(
      coordinate: GpsCoordinate(latitude: lat, longitude: lng),
      address: address,
    );
  }

  Future<void> _persistSnapshot(LocationSnapshot s) async {
    await SharedPrefHelper.setString(_latitudeKey, s.coordinate.latitude.toString());
    await SharedPrefHelper.setString(_longitudeKey, s.coordinate.longitude.toString());
    await SharedPrefHelper.setString(_addressKey, s.address);
  }

  // ─────────────────────────────────────────────

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
    } catch (_) {
      if (retryCount < _maxRetries) {
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

  // ─────────────────────────────────────────────

  void startWatching(void Function(LocationSnapshot s) onData, {void Function(String message)? onError}) {
    stopWatching();

    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
        ).listen((pos) {
          _geocodeDebounce?.cancel();

          _geocodeDebounce = Timer(const Duration(milliseconds: 800), () async {
            try {
              final snap = await _snapshotFromPosition(pos);
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
    _positionSub?.cancel();
  }

  void dispose() => stopWatching();
}
