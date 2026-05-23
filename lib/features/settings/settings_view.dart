import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/features/camera/camera_controller.dart';
import 'package:gps_map_camera/features/privacy_policy/privacy_policy_view.dart';
import 'package:gps_map_camera/features/term_of_service/term_of_service_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraControllerProvider);
    final cameraCtrl = ref.read(cameraControllerProvider.notifier);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          /// Camera Section
          _Section(
            title: 'Camera',
            width: width,
            children: [
              _SettingsTile(
                icon: Icons.flash_on_rounded,
                title: 'Flash',
                value: cameraState.flashOn,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.flashOn) {
                    cameraCtrl.toggleFlash();
                  }
                },
              ),

              _SettingsTile(
                icon: Icons.flip_camera_android_rounded,
                title: 'Front Camera',
                value: cameraState.frontCamera,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.frontCamera) {
                    cameraCtrl.toggleCamera();
                  }
                },
              ),

              _SettingsTile(
                icon: Icons.grid_on_rounded,
                title: 'Grid Lines',
                value: cameraState.gridEnabled,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.gridEnabled) {
                    cameraCtrl.toggleGrid();
                  }
                },
              ),

              _SettingsTile(
                icon: Icons.photo,
                title: 'Saved to Gallery',
                value: cameraState.saveToGallery,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.saveToGallery) {
                    cameraCtrl.toggleSaveToGallery();
                  }
                },
              ),
            ],
          ),

          /// About Section
          _Section(
            title: 'About',
            width: width,
            children: [
              _InfoTile(icon: Icons.info_outline_rounded, title: 'Version', value: '1.0.0', width: width),

              _InfoTile(icon: Icons.star_rate_rounded, title: 'Rate Us', value: '', width: width),

              _InfoTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                value: '',
                width: width,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyView()));
                },
              ),

              _InfoTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                value: '',
                width: width,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TermsOfServiceView()));
                },
              ),
            ],
          ),

          SizedBox(height: height * 0.05),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double width;

  const _Section({required this.title, required this.children, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(width * 0.04, width * 0.05, width * 0.04, width * 0.02),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: width * 0.03,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),

        Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width * 0.035),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;

              return Column(
                children: [
                  e.value,

                  if (!isLast) Divider(height: 0, indent: width * 0.14, endIndent: 0),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: width * 0.09,
        height: width * 0.09,
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(width * 0.022),
        ),
        child: Icon(icon, size: width * 0.045, color: value ? AppColors.primary : AppColors.textSecondary),
      ),

      title: Text(
        title,
        style: TextStyle(fontSize: width * 0.037, fontWeight: FontWeight.w600),
      ),

      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.divider,
        trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),

      contentPadding: EdgeInsets.symmetric(horizontal: width * 0.035, vertical: width * 0.01),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final double width;

  const _InfoTile({required this.icon, required this.title, required this.value, required this.width, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      leading: Container(
        width: width * 0.09,
        height: width * 0.09,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(width * 0.022)),
        child: Icon(icon, size: width * 0.045, color: AppColors.textSecondary),
      ),

      title: Text(
        title,
        style: TextStyle(fontSize: width * 0.037, fontWeight: FontWeight.w600),
      ),

      trailing: value.isNotEmpty
          ? Text(
              value,
              style: TextStyle(color: AppColors.textSecondary, fontSize: width * 0.032),
            )
          : Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: width * 0.055),

      contentPadding: EdgeInsets.symmetric(horizontal: width * 0.035),
    );
  }
}
