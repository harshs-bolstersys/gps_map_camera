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

          // ── Timer ─────────────────────────────────────────────────────
          _Section(
            title: 'Timer',
            children: [
              _SettingsTile(
                icon: Icons.timer_rounded,
                title: 'Self Timer',
                value: state.timerEnabled,
                onChanged: ctrl.toggleTimer,
              ),
              if (state.timerEnabled)
                _SliderTile(
                  icon: Icons.hourglass_bottom_rounded,
                  title: 'Timer Duration',
                  value: state.timerSeconds.toDouble(),
                  min: 3,
                  max: 15,
                  suffix: 's',
                  onChanged: (v) => ctrl.setTimerSeconds(v.toInt()),
                ),
            ],
          ),

          // ── Storage ───────────────────────────────────────────────────
          _Section(
            title: 'Storage',
            children: [
              _SettingsTile(
                icon: Icons.save_alt_rounded,
                title: 'Auto Save to Gallery',
                value: state.autoSaveToGallery,
                onChanged: ctrl.toggleAutoSave,
              ),
              _SettingsTile(
                icon: Icons.photo_library_rounded,
                title: 'Save Original Photo',
                subtitle: 'Keep both stamped and unstamped',
                value: state.saveOriginalPhoto,
                onChanged: ctrl.toggleSaveOriginal,
              ),
              _TextTile(
                icon: Icons.folder_rounded,
                title: 'Default Folder',
                value: state.defaultFolderName,
                onChanged: ctrl.setFolder,
              ),
            ],
          ),

          // ── About ─────────────────────────────────────────────────────
          _Section(
            title: 'About',
            children: [
              _InfoTile(icon: Icons.info_outline_rounded, title: 'Version', value: '2.4.1'),
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
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsTile({required this.icon, required this.title, this.subtitle, required this.value, required this.onChanged});

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
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
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

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      '${value.toInt()}$suffix',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ValueChanged<String> onChanged;
  const _TextTile({required this.icon, required this.title, required this.value, required this.onChanged});

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
      subtitle: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: () => _showEditDialog(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onChanged(ctrl.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('Save'),
          ),
        ],
      ),
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
