import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'locations_controller.dart';

class LocationsView extends ConsumerWidget {
  const LocationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved Locations'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocationSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Location', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Map preview area
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Simulated map
                  Container(
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE8E0D0), Color(0xFFD4C9B0)])),
                    child: CustomPaint(painter: _MapGridPainter(), size: Size.infinite),
                  ),
                  // Pins for saved locations
                  ...state.locations.asMap().entries.map((entry) {
                    return Positioned(
                      left: 60.0 + entry.key * 80,
                      top: 60.0 + (entry.key % 2) * 40,
                      child: _MapPin(label: entry.value.title),
                    );
                  }),
                  // Map label
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Saved locations list
          Expanded(
            child: state.locations.isEmpty
                ? _EmptyLocations(onAdd: () => _showAddLocationSheet(context, ref))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.locations.length,
                    itemBuilder: (context, index) {
                      final loc = state.locations[index];
                      return _LocationTile(
                        location: loc,
                        onDelete: () => ref.read(locationsControllerProvider.notifier).deleteLocation(loc.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddLocationSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Manual Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // Simulated mini-map
              Container(
                height: 140,
                decoration: BoxDecoration(color: const Color(0xFFE8E0D0), borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  children: [
                    CustomPaint(painter: _MapGridPainter(), size: Size.infinite),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.info, color: Colors.white, size: 18),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      ref
                          .read(locationsControllerProvider.notifier)
                          .addLocation(
                            SavedLocation(
                              id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
                              title: titleCtrl.text,
                              coordinate: const GpsCoordinate(latitude: 41.259941, longitude: -95.990837),
                              address: addressCtrl.text.isEmpty ? 'Custom Location' : addressCtrl.text,
                              savedAt: DateTime.now(),
                            ),
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Location', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final SavedLocation location;
  final VoidCallback onDelete;
  const _LocationTile({required this.location, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(location.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  'Lat ${location.coordinate.latitude.toStringAsFixed(4)}  Lng ${location.coordinate.longitude.toStringAsFixed(4)}  Range: ${location.rangeMeters.toInt()}m',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  const _MapPin({required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
          ),
          child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const Icon(Icons.location_on, color: Colors.red, size: 22),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4C9B0)
      ..strokeWidth = 0.8;
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final roadPaint = Paint()..color = const Color(0xFFF5EFE0);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.12, size.height), roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.12), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyLocations extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLocations({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No Saved Locations',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add your first location'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
