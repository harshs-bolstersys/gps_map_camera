import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'gallery_controller.dart';
import 'gallery_local_image.dart';

class GalleryView extends ConsumerWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryControllerProvider);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Collection',
          style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      // bottomNavigationBar: Padding(
      //   padding: EdgeInsets.only(bottom: height * 0.03),
      //   child: Container(height: 50, width: double.infinity, color: Colors.amberAccent),
      // ),
      body: Column(
        children: [
          /// Stats bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.012),
            color: AppColors.surface,
            child: Row(
              children: [
                _StatChip(label: '${state.photos.length} Photos', icon: Icons.photo, width: width),

                SizedBox(width: width * 0.025),

                _StatChip(label: 'GPS Tagged', icon: Icons.location_on, color: AppColors.primary, width: width),
              ],
            ),
          ),

          /// Grid
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.photos.isEmpty
                ? const _EmptyGallery()
                : GridView.builder(
                    padding: EdgeInsets.all(width * 0.03),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width > 600 ? 4 : 3,
                      crossAxisSpacing: width * 0.015,
                      mainAxisSpacing: width * 0.015,
                      childAspectRatio: 1,
                    ),
                    itemCount: state.photos.length,
                    itemBuilder: (context, index) {
                      final photo = state.photos[index];

                      return _PhotoTile(
                        photo: photo,
                        width: width,
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
  final double width;

  const _PhotoTile({required this.photo, required this.onTap, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(width * 0.02)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.02),
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
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.image_rounded, color: Colors.white30, size: width * 0.07),
                  ),
                ),
              ),
            ),

            /// GPS Badge
            Positioned(
              bottom: width * 0.01,
              right: width * 0.01,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.01, vertical: width * 0.005),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(width * 0.01)),
                child: Text(
                  'GPS',
                  style: TextStyle(color: Colors.black, fontSize: width * 0.02, fontWeight: FontWeight.w800),
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
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.05)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: height * 0.012),
                    width: width * 0.1,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                /// Image
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
                    height: height * 0.3,
                    margin: EdgeInsets.all(width * 0.04),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(width * 0.03), color: const Color(0xFF2C3E50)),
                    clipBehavior: Clip.antiAlias,
                    child: _galleryDetailImage(photo),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.address,
                        style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.w700),
                      ),

                      SizedBox(height: height * 0.005),

                      Text(
                        _formatDate(photo.capturedAt),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: width * 0.033),
                      ),

                      SizedBox(height: height * 0.02),

                      /// GPS Info
                      Container(
                        padding: EdgeInsets.all(width * 0.035),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(width * 0.03)),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Latitude', value: '${photo.coordinate.latitude}°', width: width),

                            SizedBox(height: height * 0.01),

                            _InfoRow(label: 'Longitude', value: '${photo.coordinate.longitude}°', width: width),

                            SizedBox(height: height * 0.01),

                            _InfoRow(
                              label: 'Altitude',
                              value: '${photo.coordinate.altitude?.toStringAsFixed(1) ?? '--'}m',
                              width: width,
                            ),

                            SizedBox(height: height * 0.01),

                            _InfoRow(
                              label: 'Accuracy',
                              value: '±${photo.coordinate.accuracy?.toStringAsFixed(1) ?? '--'}m',
                              width: width,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.025),

                      /// Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (shareContext) => _ActionButton(
                                icon: Icons.share_rounded,
                                label: 'Share',
                                onTap: () => _shareGeoPhoto(shareContext, photo),
                                color: AppColors.secondary,
                                width: width,
                              ),
                            ),
                          ),

                          SizedBox(width: width * 0.03),

                          Expanded(
                            child: _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              onTap: () async {
                                await ref.read(galleryControllerProvider.notifier).deletePhoto(photo.id);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              color: AppColors.error,
                              width: width,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: height * 0.04),
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
    const months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];

    final dateStr = '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}, ${dt.year}';

    final amPm = dt.hour >= 12 ? 'PM' : 'AM';

    final hour12 = (dt.hour % 12 == 0) ? 12 : dt.hour % 12;

    final timeStr = '$hour12:${dt.minute.toString().padLeft(2, '0')} $amPm';

    return '$dateStr - $timeStr';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double width;

  const _InfoRow({required this.label, required this.value, required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: width * 0.033),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: width * 0.033),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double width;

  const _ActionButton({required this.icon, required this.label, required this.onTap, required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: width * 0.12,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(width * 0.03),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: width * 0.045),

            SizedBox(width: width * 0.015),

            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: width * 0.035),
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
  final double width;

  const _StatChip({required this.label, required this.icon, required this.width, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: width * 0.012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.05),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: width * 0.035, color: color),

          SizedBox(width: width * 0.01),

          Text(
            label,
            style: TextStyle(fontSize: width * 0.03, color: color, fontWeight: FontWeight.w600),
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: width * 0.18, color: Colors.grey.shade300),

          SizedBox(height: height * 0.02),

          Text(
            'No Photos Yet',
            style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),

          SizedBox(height: height * 0.008),

          Text(
            'Capture your first GPS-tagged photo',
            style: TextStyle(color: AppColors.textSecondary, fontSize: width * 0.035),
          ),
        ],
      ),
    );
  }
}
