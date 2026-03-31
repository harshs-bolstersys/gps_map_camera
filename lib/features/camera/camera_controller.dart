import 'package:camera/camera.dart' as cam;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'package:gps_map_camera/services/gallery_local_storage.dart';
import 'package:gps_map_camera/services/photo_gps_stamp_compositor.dart';
import 'package:gps_map_camera/services/location_sevice.dart';
import 'package:gps_map_camera/features/gallery/gallery_controller.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class CameraState {
  final bool isLoading;
  final bool isCapturing;
  final bool flashOn;
  final bool frontCamera;
  final bool gridEnabled;
  final bool saveToGallery;
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
    this.gridEnabled = false,
    this.saveToGallery = true,
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
    bool? gridEnabled,
    bool? saveToGallery,
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
      gridEnabled: gridEnabled ?? this.gridEnabled,
      saveToGallery: saveToGallery ?? this.saveToGallery,
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

  void toggleFlash() {
    state = state.copyWith(flashOn: !state.flashOn);
  }

  void toggleCamera() {
    final nextFront = !state.frontCamera;
    state = state.copyWith(frontCamera: nextFront);
  }

  void toggleGrid() => state = state.copyWith(gridEnabled: !state.gridEnabled);
  void toggleSaveToGallery() => state = state.copyWith(saveToGallery: !state.saveToGallery);
  void updateStampConfig(StampConfig config) => state = state.copyWith(stampConfig: config);

  Future<void> capturePhoto() async {
    if (state.isCapturing) return;
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
          // Front camera outputs a mirrored JPEG in this pipeline; flip back so the saved selfie is not mirrored.
          flipHorizontally: state.frontCamera,
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
      if (state.saveToGallery) {
        unawaited(GalleryLocalStorage.backupToSystemGallery(savedPath));
      }
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
