// settings_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/models/app_models.dart';

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings());

  void toggleSaveOriginal(bool v) => state = state.copyWith(saveOriginalPhoto: v);
  void toggleAutoSave(bool v) => state = state.copyWith(autoSaveToGallery: v);
  void setFolder(String v) => state = state.copyWith(defaultFolderName: v);
  void toggleGrid(bool v) => state = state.copyWith(gridEnabled: v);
  void toggleFrontCamera(bool v) => state = state.copyWith(frontCamera: v);
  void toggleFlash(bool v) => state = state.copyWith(flashEnabled: v);
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, AppSettings>((ref) => SettingsController());
