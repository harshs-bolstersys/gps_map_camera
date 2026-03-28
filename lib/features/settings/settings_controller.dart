// settings_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings());

  void toggleSaveOriginal(bool v) => state = state.copyWith(saveOriginalPhoto: v);
  void toggleAutoSave(bool v) => state = state.copyWith(autoSaveToGallery: v);
  void setFolder(String v) => state = state.copyWith(defaultFolderName: v);
  void toggleSound(bool v) => state = state.copyWith(soundEnabled: v);
  void toggleTimer(bool v) => state = state.copyWith(timerEnabled: v);
  void setTimerSeconds(int v) => state = state.copyWith(timerSeconds: v);
  void toggleGrid(bool v) => state = state.copyWith(gridEnabled: v);
  void toggleFrontCamera(bool v) => state = state.copyWith(frontCamera: v);
  void toggleFlash(bool v) => state = state.copyWith(flashEnabled: v);
  void toggleMirror(bool v) => state = state.copyWith(mirrorEnabled: v);
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(),
);
