import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/features/camera/camera_view.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/core/utils/snackbar_helper.dart';
import 'package:gps_map_camera/widgets/custom_button.dart';
import 'package:gps_map_camera/widgets/toggle_permission_tile.dart';
import 'permission_controller.dart';

class PermissionView extends ConsumerWidget {
  const PermissionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionControllerProvider);
    final controller = ref.read(permissionControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 30),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Title
              const Text(
                'Permissions Required\nto Continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.25),
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'These permissions enable capturing photos and videos with GPS location, date, and time stamps.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Camera permission tile
              TogglePermissionTile(
                icon: _PermissionIcon(emoji: '📷', color: const Color(0xFFFFF3E0)),
                title: 'Camera Access',
                subtitle: 'Allows the app to capture photos and record videos',
                value: state.cameraEnabled,
                onChanged: (val) async {
                  if (val) {
                    final granted = await controller.requestCameraPermission();
                    if (!granted && context.mounted) {
                      SnackbarHelper.showError(context, 'Camera permission denied. Please allow access in settings.');
                    }
                  } else {
                    controller.setCameraEnabled(false);
                  }
                },
              ),

              // Location permission tile
              TogglePermissionTile(
                icon: _PermissionIcon(emoji: '🖼️', color: const Color(0xFFE8F5E9)),
                title: 'Location Access',
                subtitle: 'Used to add GPS location details and map stamps to captured photos and videos.',
                value: state.locationEnabled,
                onChanged: (val) async {
                  if (val) {
                    final granted = await controller.requestLocationPermission();
                    if (!granted && context.mounted) {
                      SnackbarHelper.showError(context, 'Location permission denied. Please allow access in settings.');
                    }
                  } else {
                    controller.setLocationEnabled(false);
                  }
                },
              ),

              // Gallery permission tile
              TogglePermissionTile(
                icon: _PermissionIcon(emoji: '📍', color: const Color(0xFFFCE4EC)),
                title: 'Photo Library Access',
                subtitle: 'Allows saving captured photos and videos to your device gallery.',
                value: state.galleryEnabled,
                onChanged: (val) async {
                  if (val) {
                    final granted = await controller.requestGalleryPermission();
                    if (!granted && context.mounted) {
                      SnackbarHelper.showError(context, 'Photo library permission denied. Please allow access in settings.');
                    }
                  } else {
                    controller.setGalleryEnabled(false);
                  }
                },
              ),

              const Spacer(),

              // Next button
              CustomButton(
                label: 'Continue',
                isEnabled: state.allPermissionsEnabled,
                onPressed: state.allPermissionsEnabled
                    ? () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraView()),
                        (route) => false,
                      )
                    : () {
                        SnackbarHelper.showInfo(context, 'Please enable all permissions to continue');
                      },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionIcon extends StatelessWidget {
  final String emoji;
  final Color color;
  const _PermissionIcon({required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 26, color: AppColors.textPrimary)),
      ),
    );
  }
}
