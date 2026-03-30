import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import 'gallery_controller.dart';
import 'gallery_local_image.dart';

class GalleryView extends ConsumerWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Collection'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                _StatChip(label: '${state.photos.length} Photos', icon: Icons.photo),
                const SizedBox(width: 10),
                _StatChip(label: 'GPS Tagged', icon: Icons.location_on, color: AppColors.primary),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.photos.isEmpty
                ? const _EmptyGallery()
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: state.photos.length,
                    itemBuilder: (context, index) {
                      final photo = state.photos[index];
                      return _PhotoTile(
                        photo: photo,
                        onTap: () {
                          ref.read(galleryControllerProvider.notifier).selectPhoto(photo);
                          _showPhotoDetail(context, ref, photo);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(BuildContext context, WidgetRef ref, GeoPhoto photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoDetailSheet(photo: photo, ref: ref),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final GeoPhoto photo;
  final VoidCallback onTap;
  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(8)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: galleryLocalImage(
                photo.filePath,
                fit: BoxFit.cover,
                fallback: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.primaries[photo.id.hashCode % Colors.primaries.length].shade800,
                        Colors.primaries[photo.id.hashCode % Colors.primaries.length].shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: Icon(Icons.image_rounded, color: Colors.white30, size: 28)),
                ),
              ),
            ),
            // GPS badge
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                child: const Text(
                  'GPS',
                  style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _shareGeoPhoto(BuildContext context, GeoPhoto photo) async {
  final path = photo.filePath;
  if (!File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo file not found')));
    }
    return;
  }
  Rect? shareOrigin;
  final ro = context.findRenderObject();
  if (ro is RenderBox && ro.hasSize) {
    final topLeft = ro.localToGlobal(Offset.zero);
    shareOrigin = Rect.fromLTWH(topLeft.dx, topLeft.dy, ro.size.width, ro.size.height);
  }
  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)], sharePositionOrigin: shareOrigin));
  } catch (e) {
    if (context.mounted) {
      debugPrint('Could not share: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    }
  }
}

Widget _galleryDetailImage(GeoPhoto photo) {
  return galleryLocalImage(
    photo.filePath,
    fit: BoxFit.contain,
    fallback: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.primaries[photo.id.hashCode % Colors.primaries.length].shade800,
            Colors.primaries[photo.id.hashCode % Colors.primaries.length].shade400,
          ],
        ),
      ),
      child: const Center(child: Icon(Icons.image_rounded, color: Colors.white30, size: 60)),
    ),
  );
}

class _PhotoDetailSheet extends StatelessWidget {
  final GeoPhoto photo;
  final WidgetRef ref;
  const _PhotoDetailSheet({required this.photo, required this.ref});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Photo preview
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (ctx) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
                        body: Center(child: _galleryDetailImage(photo)),
                      ),
                    ),
                  ),
                  child: Container(
                    height: 220,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF2C3E50)),
                    clipBehavior: Clip.antiAlias,
                    child: _galleryDetailImage(photo),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.address, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_formatDate(photo.capturedAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      // GPS Info grid
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Latitude', value: '${photo.coordinate.latitude.toStringAsFixed(6)}°'),
                            const Divider(height: 12),
                            _InfoRow(label: 'Longitude', value: '${photo.coordinate.longitude.toStringAsFixed(6)}°'),
                            const Divider(height: 12),
                            _InfoRow(label: 'Altitude', value: '${photo.coordinate.altitude?.toStringAsFixed(1) ?? '--'}m'),
                            const Divider(height: 12),
                            _InfoRow(label: 'Accuracy', value: '±${photo.coordinate.accuracy?.toStringAsFixed(1) ?? '--'}m'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (shareContext) => _ActionButton(
                                icon: Icons.share_rounded,
                                label: 'Share',
                                onTap: () => _shareGeoPhoto(shareContext, photo),
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              onTap: () async {
                                await ref.read(galleryControllerProvider.notifier).deletePhoto(photo.id);
                                if (context.mounted) Navigator.pop(context);
                              },
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionButton({required this.icon, required this.label, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.icon, this.color = AppColors.textSecondary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Photos Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text('Capture your first GPS-tagged photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
