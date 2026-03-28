import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'file_name_controller.dart';

class FileNameView extends ConsumerWidget {
  const FileNameView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileNameControllerProvider);
    final ctrl = ref.read(fileNameControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('File Name'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.splashBg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.image_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      state.preview,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Prefix input
          const Text('Prefix', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: state.prefix,
            onChanged: ctrl.setPrefix,
            decoration: InputDecoration(
              hintText: 'e.g. GPS, SITE, PROJECT',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Include in Filename', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),

          _ToggleTile(
            icon: Icons.calendar_today_rounded,
            title: 'Date',
            subtitle: 'e.g. 20250812',
            value: state.useDate,
            onChanged: ctrl.toggleDate,
          ),
          _ToggleTile(
            icon: Icons.access_time_rounded,
            title: 'Time',
            subtitle: 'e.g. 1432',
            value: state.useTime,
            onChanged: ctrl.toggleTime,
          ),
          _ToggleTile(
            icon: Icons.location_on_rounded,
            title: 'Location Name',
            subtitle: 'e.g. WestHollywood',
            value: state.useLocation,
            onChanged: ctrl.toggleLocation,
          ),
          _ToggleTile(
            icon: Icons.format_list_numbered_rounded,
            title: 'Sequence Number',
            subtitle: 'e.g. 001, 002…',
            value: state.useSequence,
            onChanged: ctrl.toggleSequence,
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Files are saved automatically to the GPS Map Camera folder in your gallery.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
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
        ],
      ),
    );
  }
}
