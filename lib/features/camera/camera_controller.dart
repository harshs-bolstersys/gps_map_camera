import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';

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
  CameraController() : super(const CameraState()) {
    _initMockLocation();
  }

  void _initMockLocation() {
    // Simulated location — replace with geolocator in production
    state = state.copyWith(
      currentLocation: const GpsCoordinate(
        latitude: 28.608537,
        longitude: -80.603999,
        altitude: 12.5,
        accuracy: 4.2,
      ),
      currentAddress: 'West Hollywood, Florida, USA',
      compassBearing: 245.0,
      altitude: 12.5,
      accuracy: 4.2,
    );
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
    if (state.isCapturing) return;
    state = state.copyWith(isCapturing: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isCapturing: false,
      lastCapturedPath: 'captured_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cameraControllerProvider =
    StateNotifierProvider<CameraController, CameraState>(
  (ref) => CameraController(),
);
