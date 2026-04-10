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

  /// True for only ~120ms after shutter tap — drives the black blink overlay.
  /// Independent of isCapturing so it dismisses instantly regardless of how
  /// long background processing takes.
  final bool showCaptureOverlay;

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

  const CameraState({
    this.isLoading = false,
    this.isCapturing = false,
    this.showCaptureOverlay = false,
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
  });

  CameraState copyWith({
    bool? isLoading,
    bool? isCapturing,
    bool? showCaptureOverlay,
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
  }) {
    return CameraState(
      isLoading: isLoading ?? this.isLoading,
      isCapturing: isCapturing ?? this.isCapturing,
      showCaptureOverlay: showCaptureOverlay ?? this.showCaptureOverlay,
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

  /// Tracks in-flight background tasks so dispose can wait for them.
  final List<Future<void>> _pendingProcessing = [];

  /// Timer that auto-clears the capture overlay after a short blink.
  Timer? _overlayTimer;

  // ─── Duration constants ────────────────────────────────────────────────────

  /// How long the black blink overlay stays visible. 120ms feels like a
  /// real shutter; shorter feels broken, longer feels slow.
  static const _overlayDuration = Duration(milliseconds: 120);

  // ─── Location bootstrap ────────────────────────────────────────────────────

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
    _overlayTimer?.cancel();
    _location.stopWatching();
    super.dispose();
  }

  // ─── Simple toggles ────────────────────────────────────────────────────────

  void toggleFlash() => state = state.copyWith(flashOn: !state.flashOn);

  void toggleCamera() => state = state.copyWith(frontCamera: !state.frontCamera);

  void toggleGrid() => state = state.copyWith(gridEnabled: !state.gridEnabled);

  void toggleSaveToGallery() => state = state.copyWith(saveToGallery: !state.saveToGallery);

  void updateStampConfig(StampConfig config) => state = state.copyWith(stampConfig: config);

  // ─── Capture ───────────────────────────────────────────────────────────────

  Future<void> capturePhoto() async {
    // Debounce: ignore taps while a capture is already in progress.
    if (state.isCapturing) return;

    final native = _ref.read(nativeCameraControllerProvider);
    if (native == null || !native.value.isInitialized) {
      debugPrint('capturePhoto: camera not ready');
      return;
    }

    // ── Show overlay blink immediately on tap ────────────────────────────────
    // Fires a 120ms black flash that feels like a real shutter click,
    // completely independent of how long the actual capture + processing takes.
    _overlayTimer?.cancel();
    state = state.copyWith(isCapturing: true, showCaptureOverlay: true);
    _overlayTimer = Timer(_overlayDuration, () {
      if (mounted) state = state.copyWith(showCaptureOverlay: false);
    });

    try {
      // ── Step 1: Hardware capture — minimum blocking work ─────────────────
      final xfile = await native.takePicture();
      final capturedAt = DateTime.now();

      // ── Step 2: Release shutter UI immediately ───────────────────────────
      // Overlay is already auto-dismissing via the timer above.
      // isCapturing flips false so the shutter button is re-enabled.
      state = state.copyWith(isCapturing: false);

      // ── Step 3: Snapshot mutable state BEFORE any async gap ─────────────
      // State can change (e.g. GPS update) while background work is running,
      // so capture all needed values into locals right now.
      final loc = state.currentLocation;
      final address = state.currentAddress;
      final frontCamera = state.frontCamera;
      final altitude = state.altitude;
      final accuracy = state.accuracy;
      final compassBearing = state.compassBearing;
      final stampConfig = state.stampConfig;
      final saveToGallery = state.saveToGallery;

      // ── Step 4: Fire-and-forget all heavy file I/O ───────────────────────
      final task = _processAndSavePhoto(
        xfilePath: xfile.path,
        capturedAt: capturedAt,
        loc: loc,
        address: address,
        frontCamera: frontCamera,
        altitude: altitude,
        accuracy: accuracy,
        compassBearing: compassBearing,
        stampConfig: stampConfig,
        saveToGallery: saveToGallery,
      );

      // Track the task so dispose can wait for it if needed.
      _pendingProcessing.add(task);
      unawaited(task.whenComplete(() => _pendingProcessing.remove(task)));
    } catch (e, st) {
      debugPrint('capturePhoto failed: $e\n$st');
      state = state.copyWith(isCapturing: false, showCaptureOverlay: false);
      _overlayTimer?.cancel();
    }
  }

  // ─── Background processing ─────────────────────────────────────────────────
  // Runs entirely after the shutter has already been released to the user.
  // Takes only plain values (no Ref / state access) to be safe across async gaps.

  Future<void> _processAndSavePhoto({
    required String xfilePath,
    required DateTime capturedAt,
    required GpsCoordinate? loc,
    required String address,
    required bool frontCamera,
    required double? altitude,
    required double? accuracy,
    required double? compassBearing,
    required StampConfig stampConfig,
    required bool saveToGallery,
  }) async {
    try {
      // 1. Copy raw capture out of the camera temp directory.
      final savedPath = await GalleryLocalStorage.copyCaptureToAppDirectory(xfilePath);

      // 2. Composite the GPS stamp onto the JPEG (the slowest step).
      if (loc != null) {
        await PhotoGpsStampCompositor.compositeOntoFileIfPossible(
          jpegPath: savedPath,
          location: loc,
          address: address,
          capturedAt: capturedAt,
          stampConfig: stampConfig,
          altitude: altitude,
          accuracy: accuracy,
          compassBearing: compassBearing,
          // Front camera outputs a mirrored JPEG; flip back so the saved
          // selfie is not mirrored.
          flipHorizontally: frontCamera,
        );
      }

      // 3. Register in the in-app gallery.
      final id = 'photo_${capturedAt.millisecondsSinceEpoch}';
      final coord = loc ?? const GpsCoordinate(latitude: 0, longitude: 0);
      final photo = GeoPhoto(
        id: id,
        filePath: savedPath,
        coordinate: coord,
        address: address,
        capturedAt: capturedAt,
        stampConfig: stampConfig,
        compassBearing: compassBearing,
      );
      await _ref.read(galleryControllerProvider.notifier).addPhoto(photo);

      // 4. Optionally back up to the system photo gallery (also fire-and-forget).
      if (saveToGallery) {
        unawaited(GalleryLocalStorage.backupToSystemGallery(savedPath));
      }
    } catch (e, st) {
      debugPrint('_processAndSavePhoto failed: $e\n$st');
      // Non-fatal: the shutter has already been released. The user can retake
      // if the image does not appear in the gallery.
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

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
