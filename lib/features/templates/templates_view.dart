import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'templates_controller.dart';

class TemplatesView extends ConsumerWidget {
  const TemplatesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templatesControllerProvider);
    final ctrl = ref.read(templatesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Templates'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a stamp template that fits your purpose. Each template pre-configures stamp data for you.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          ...state.templates.map((template) {
            final isSelected = template.id == state.selectedTemplateId;
            return GestureDetector(
              onTap: () => ctrl.selectTemplate(template.id),
              child: _TemplateTile(template: template, isSelected: isSelected),
            );
          }),
          const SizedBox(height: 24),
          if (state.selectedTemplateId.isNotEmpty)
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply Template', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final StampTemplate template;
  final bool isSelected;
  const _TemplateTile({required this.template, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 3))]
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Mini stamp preview
            _MiniPreview(config: template.config),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (template.isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Text(
                            'PRO',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.amber),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(template.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 8),
                  // Feature chips
                  Wrap(spacing: 4, runSpacing: 4, children: _buildChips(template.config)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChips(StampConfig c) {
    final items = <String>[];
    if (c.showLocation) items.add('Location');
    if (c.showCoordinates) items.add('GPS');
    if (c.showMap) items.add('Map');
    if (c.showDate) items.add('Date');
    if (c.showTime) items.add('Time');
    if (c.showAltitude) items.add('Altitude');
    if (c.showCompass) items.add('Compass');
    if (c.showLogo) items.add('Logo');
    if (c.showPersonName) items.add('Name');
    if (c.showNote) items.add('Note');

    return items
        .take(4)
        .map(
          (label) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        )
        .toList();
  }
}

class _MiniPreview extends StatelessWidget {
  final StampConfig config;
  const _MiniPreview({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1A1A2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.landscape_rounded, color: Colors.white10, size: 30)),
          Positioned(
            bottom: 6,
            left: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (config.showLocation)
                    Container(height: 4, width: 40, color: Colors.white70, margin: const EdgeInsets.only(bottom: 2)),
                  if (config.showCoordinates)
                    Container(height: 3, width: 55, color: Colors.white38, margin: const EdgeInsets.only(bottom: 2)),
                  if (config.showDate || config.showTime) Container(height: 3, width: 45, color: Colors.white38),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
