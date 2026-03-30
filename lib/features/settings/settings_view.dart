import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'settings_controller.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Camera ───────────────────────────────────────────────────
          _Section(
            title: 'Camera',
            children: [
              _SettingsTile(icon: Icons.flash_on_rounded, title: 'Flash', value: state.flashEnabled, onChanged: ctrl.toggleFlash),
              _SettingsTile(
                icon: Icons.flip_camera_android_rounded,
                title: 'Front Camera',
                value: state.frontCamera,
                onChanged: ctrl.toggleFrontCamera,
              ),
              _SettingsTile(
                icon: Icons.flip_rounded,
                title: 'Mirror Mode',
                value: state.mirrorEnabled,
                onChanged: ctrl.toggleMirror,
              ),
              _SettingsTile(
                icon: Icons.grid_on_rounded,
                title: 'Grid Lines',
                value: state.gridEnabled,
                onChanged: ctrl.toggleGrid,
              ),
              _SettingsTile(
                icon: Icons.volume_up_rounded,
                title: 'Capture Sound',
                value: state.soundEnabled,
                onChanged: ctrl.toggleSound,
              ),
            ],
          ),

          // ── About ─────────────────────────────────────────────────────
          _Section(
            title: 'About',
            children: [
              _InfoTile(icon: Icons.info_outline_rounded, title: 'Version', value: '1.0.0'),
              _InfoTile(icon: Icons.star_rate_rounded, title: 'Rate Us', value: '⭐⭐⭐⭐⭐'),
              _InfoTile(icon: Icons.share_rounded, title: 'Share App', value: ''),
              _InfoTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', value: ''),
              _InfoTile(icon: Icons.description_outlined, title: 'Terms of Service', value: ''),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(children: [e.value, if (!isLast) const Divider(height: 0, indent: 56, endIndent: 0)]);
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
  const _SettingsTile({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: value ? AppColors.primary : AppColors.textSecondary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.divider,
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return Colors.transparent;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: value.isNotEmpty
          ? Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}
