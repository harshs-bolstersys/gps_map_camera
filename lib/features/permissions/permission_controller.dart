import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

// --------------- State ---------------

class PermissionState {
  final bool cameraEnabled;
  final bool locationEnabled;
  final bool galleryEnabled;

  const PermissionState({
    this.cameraEnabled = false,
    this.locationEnabled = false,
    this.galleryEnabled = false,
  });

  bool get allPermissionsEnabled =>
      cameraEnabled && locationEnabled && galleryEnabled;

  PermissionState copyWith({
    bool? cameraEnabled,
    bool? locationEnabled,
    bool? galleryEnabled,
  }) {
    return PermissionState(
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      galleryEnabled: galleryEnabled ?? this.galleryEnabled,
    );
  }
}

// --------------- Controller ---------------

class PermissionController extends StateNotifier<PermissionState> {
  PermissionController() : super(const PermissionState());

  /// Safely requests a permission. Returns true if granted.
  /// Falls back to `true` on MissingPluginException (e.g. emulators / unit tests).
  Future<bool> _safeRequest(Permission permission) async {
    try {
      final status = await permission.request();
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    } on MissingPluginException {
      // permission_handler native plugin not wired up (emulator / test env)
      // Grant optimistically so the UI flow can still be tested.
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestCameraPermission() async {
    final granted = await _safeRequest(Permission.camera);
    state = state.copyWith(cameraEnabled: granted);
    return granted;
  }

  Future<bool> requestLocationPermission() async {
    final granted = await _safeRequest(Permission.locationWhenInUse);
    state = state.copyWith(locationEnabled: granted);
    return granted;
  }

  Future<bool> requestGalleryPermission() async {
    // Android 13+ → READ_MEDIA_IMAGES, older → READ_EXTERNAL_STORAGE, iOS → photos
    bool granted = await _safeRequest(Permission.photos);
    if (!granted) {
      granted = await _safeRequest(Permission.storage);
    }
    state = state.copyWith(galleryEnabled: granted);
    return granted;
  }

  void setCameraEnabled(bool value) {
    state = state.copyWith(cameraEnabled: value);
  }

  void setLocationEnabled(bool value) {
    state = state.copyWith(locationEnabled: value);
  }

  void setGalleryEnabled(bool value) {
    state = state.copyWith(galleryEnabled: value);
  }
}

// --------------- Provider ---------------

final permissionControllerProvider =
    StateNotifierProvider<PermissionController, PermissionState>(
  (ref) => PermissionController(),
);
