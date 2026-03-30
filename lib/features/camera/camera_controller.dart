import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../services/gallery_local_storage.dart';
import '../../services/photo_gps_stamp_compositor.dart';
import '../../services/location_sevice.dart';
import '../gallery/gallery_controller.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CameraState {
  final bool isLoading;
  final bool isCapturing;
  final bool flashOn;
  final bool frontCamera;
  final bool mirrorEnabled;
  final bool gridEnabled;
  final bool timerEnabled;
  final int timerSeconds;
  final int timerCountdown;
  final bool isCounting;
  final CameraMode mode;
  final GpsCoordinate? currentLocation;
  final String currentAddress;
  final double? compassBearing;
  final double? altitude;
  final double? accuracy;
  final StampConfig stampConfig;
  final String? lastCapturedPath;

  const CameraState({
    this.isLoading = false,
    this.isCapturing = false,
    this.flashOn = false,
    this.frontCamera = false,
    this.mirrorEnabled = false,
    this.gridEnabled = false,
    this.timerEnabled = false,
    this.timerSeconds = 3,
    this.timerCountdown = 0,
    this.isCounting = false,
    this.mode = CameraMode.photo,
    this.currentLocation,
    this.currentAddress = 'Fetching location...',
    this.compassBearing,
    this.altitude,
    this.accuracy,
    this.stampConfig = const StampConfig(),
    this.lastCapturedPath,
  });

  CameraState copyWith({
    bool? isLoading,
    bool? isCapturing,
    bool? flashOn,
    bool? frontCamera,
    bool? mirrorEnabled,
    bool? gridEnabled,
    bool? timerEnabled,
    int? timerSeconds,
    int? timerCountdown,
    bool? isCounting,
    CameraMode? mode,
    GpsCoordinate? currentLocation,
    String? currentAddress,
    double? compassBearing,
    double? altitude,
    double? accuracy,
    StampConfig? stampConfig,
    String? lastCapturedPath,
  }) {
    return CameraState(
      isLoading: isLoading ?? this.isLoading,
      isCapturing: isCapturing ?? this.isCapturing,
      flashOn: flashOn ?? this.flashOn,
      frontCamera: frontCamera ?? this.frontCamera,
      mirrorEnabled: mirrorEnabled ?? this.mirrorEnabled,
      gridEnabled: gridEnabled ?? this.gridEnabled,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerCountdown: timerCountdown ?? this.timerCountdown,
      isCounting: isCounting ?? this.isCounting,
      mode: mode ?? this.mode,
      currentLocation: currentLocation ?? this.currentLocation,
      currentAddress: currentAddress ?? this.currentAddress,
      compassBearing: compassBearing ?? this.compassBearing,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      stampConfig: stampConfig ?? this.stampConfig,
      lastCapturedPath: lastCapturedPath ?? this.lastCapturedPath,
    );
  }
}

enum CameraMode { photo, video }

// ─── Controller ───────────────────────────────────────────────────────────────

class CameraController extends StateNotifier<CameraState> {
  CameraController(this._ref, this._location) : super(const CameraState()) {
    _bootstrapLocation();
  }

  final Ref _ref;
  final LocationService _location;

  Future<void> _bootstrapLocation() async {
    final cached = await _location.loadCachedSnapshot();
    if (cached != null) {
      state = _applySnapshot(cached, state);
    }

    final result = await _location.fetchCurrentLocation();
    if (result.snapshot != null) {
      state = _applySnapshot(result.snapshot!, state);
    } else if (cached == null) {
      state = state.copyWith(currentAddress: result.errorMessage ?? 'Location unavailable', currentLocation: null);
    } else if (result.errorMessage != null) {
      state = state.copyWith(currentAddress: result.errorMessage!);
    }

    _location.startWatching((snap) => state = _applySnapshot(snap, state), onError: (_) {});
  }

  CameraState _applySnapshot(LocationSnapshot snap, CameraState base) {
    return base.copyWith(
      currentLocation: snap.coordinate,
      currentAddress: snap.address,
      compassBearing: snap.compassBearing,
      altitude: snap.coordinate.altitude,
      accuracy: snap.coordinate.accuracy,
    );
  }

  @override
  void dispose() {
    _location.stopWatching();
    super.dispose();
  }

  void toggleFlash() => state = state.copyWith(flashOn: !state.flashOn);
  void toggleCamera() => state = state.copyWith(frontCamera: !state.frontCamera);
  void toggleMirror() => state = state.copyWith(mirrorEnabled: !state.mirrorEnabled);
  void toggleGrid() => state = state.copyWith(gridEnabled: !state.gridEnabled);
  void toggleTimer() => state = state.copyWith(timerEnabled: !state.timerEnabled);
  void setMode(CameraMode mode) => state = state.copyWith(mode: mode);
  void setTimerSeconds(int seconds) => state = state.copyWith(timerSeconds: seconds);
  void updateStampConfig(StampConfig config) => state = state.copyWith(stampConfig: config);

  Future<void> capturePhoto() async {
    if (state.isCapturing || state.mode != CameraMode.photo) return;
    final native = _ref.read(nativeCameraControllerProvider);
    if (native == null || !native.value.isInitialized) {
      debugPrint('capturePhoto: camera not ready');
      return;
    }
    state = state.copyWith(isCapturing: true);
    try {
      final xfile = await native.takePicture();
      final savedPath = await GalleryLocalStorage.copyCaptureToAppDirectory(xfile.path);
      final capturedAt = DateTime.now();
      final loc = state.currentLocation;
      if (loc != null) {
        await PhotoGpsStampCompositor.compositeOntoFileIfPossible(
          jpegPath: savedPath,
          location: loc,
          address: state.currentAddress,
          capturedAt: capturedAt,
          stampConfig: state.stampConfig,
          altitude: state.altitude,
          accuracy: state.accuracy,
          compassBearing: state.compassBearing,
        );
      }
      final id = 'photo_${DateTime.now().millisecondsSinceEpoch}';
      final coord = loc ?? const GpsCoordinate(latitude: 0, longitude: 0);
      final photo = GeoPhoto(
        id: id,
        filePath: savedPath,
        coordinate: coord,
        address: state.currentAddress,
        capturedAt: capturedAt,
        stampConfig: state.stampConfig,
        compassBearing: state.compassBearing,
      );
      await _ref.read(galleryControllerProvider.notifier).addPhoto(photo);
      state = state.copyWith(isCapturing: false, lastCapturedPath: savedPath);
    } catch (e, st) {
      debugPrint('capturePhoto failed: $e\n$st');
      state = state.copyWith(isCapturing: false);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  final s = LocationService();
  ref.onDispose(s.dispose);
  return s;
});

final nativeCameraControllerProvider = StateProvider<cam.CameraController?>((ref) => null);

final cameraControllerProvider = StateNotifierProvider<CameraController, CameraState>((ref) {
  final loc = ref.watch(locationServiceProvider);
  return CameraController(ref, loc);
});
