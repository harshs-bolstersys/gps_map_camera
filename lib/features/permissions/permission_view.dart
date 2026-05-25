import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/features/camera/camera_view.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/core/utils/snackbar_helper.dart';
import 'package:gps_map_camera/services/storage_services.dart';
import 'package:gps_map_camera/widgets/custom_button.dart';
import 'package:gps_map_camera/widgets/toggle_permission_tile.dart';
import 'permission_controller.dart';

class PermissionView extends ConsumerWidget {
  const PermissionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionControllerProvider);
    final controller = ref.read(permissionControllerProvider.notifier);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: width * 0.08),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - MediaQuery.of(context).padding.top - kToolbarHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: height * 0.012),

                    /// Title
                    Text(
                      'Permissions Required\nto Continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.065,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.25,
                      ),
                    ),

                    SizedBox(height: height * 0.025),

                    /// Description
                    Text(
                      'These permissions enable capturing photos and videos with GPS location, date, and time stamps.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.038,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: height * 0.04),

                    /// Camera Permission
                    TogglePermissionTile(
                      icon: _PermissionIcon(
                        icon: Icons.camera_alt,
                        iconColor: const Color(0xFF3949AB),
                        bgColor: const Color(0xFFE3F2FD),
                        size: width,
                      ),
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

                    SizedBox(height: height * 0.005),

                    /// Location Permission
                    TogglePermissionTile(
                      icon: _PermissionIcon(
                        icon: Icons.location_on,
                        iconColor: const Color(0xFF1B5E20),
                        bgColor: const Color(0xFFE8F5E9),
                        size: width,
                      ),
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

                    SizedBox(height: height * 0.005),

                    /// Gallery Permission
                    TogglePermissionTile(
                      icon: _PermissionIcon(
                        icon: Icons.photo_library,
                        iconColor: const Color(0xFF880E4F),
                        bgColor: const Color(0xFFFCE4EC),
                        size: width,
                      ),
                      title: 'Photo Library Access',
                      subtitle: 'Allows saving captured photos and videos to your device gallery.',
                      value: state.galleryEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final granted = await controller.requestGalleryPermission();

                          if (!granted && context.mounted) {
                            SnackbarHelper.showError(
                              context,
                              'Photo library permission denied. Please allow access in settings.',
                            );
                          }
                        } else {
                          controller.setGalleryEnabled(false);
                        }
                      },
                    ),

                    const Spacer(),

                    /// Continue Button
                    CustomButton(
                      label: 'Continue',
                      isEnabled: state.allPermissionsEnabled,
                      onPressed: state.allPermissionsEnabled
                          ? () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const CameraView()),
                                (route) => false,
                              );

                              SharedPrefHelper.setBool('has_seen_permissions', true);
                            }
                          : () {
                              SnackbarHelper.showInfo(context, 'Please enable all permissions to continue');
                            },
                    ),

                    SizedBox(height: height * 0.06),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double size;

  const _PermissionIcon({required this.icon, required this.iconColor, required this.bgColor, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.11,
      height: size * 0.11,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Icon(icon, color: iconColor)),
    );
  }
}
