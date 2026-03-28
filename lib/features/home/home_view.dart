// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../core/constants/app_colors.dart';
// import '../bottom_nav_view/bottom_nav_view.dart';
// import '../templates/templates_view.dart';
// import '../gallery/gallery_view.dart';
// import '../locations/locations_view.dart';
// import '../file_name/file_name_view.dart';

// // ─── Home Page ───────────────────────────────────────────────────────────────

// class HomeView extends ConsumerWidget {
//   const HomeView({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         toolbarHeight: 75,
//         automaticallyImplyLeading: false,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.primary, AppColors.primaryDark],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           // padding: const EdgeInsets.fromLTRB(20, 58, 20, 16),
//           padding: const EdgeInsets.only(left: 20, right: 20, top: 36, bottom: 16),
//           child: Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
//                 child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
//               ),
//               const SizedBox(width: 12),
//               const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'GPS Map Camera',
//                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
//                   ),
//                   Text('Geo Tagging · Timestamp · Location Stamp', style: TextStyle(color: Colors.white70, fontSize: 11)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Quick Stats ──
//               _QuickStats(),
//               const SizedBox(height: 16),

//               // ── Quick Capture CTA ──
//               _QuickCaptureBanner(onTap: () => ref.read(homeTabProvider.notifier).state = 1),
//               const SizedBox(height: 20),

//               // ── Features Grid ──
//               const Text('Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 12),
//               const _FeaturesGrid(),
//               const SizedBox(height: 20),

//               // ── Tools ──
//               const Text('Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 12),
//               const _ToolsList(),
//               const SizedBox(height: 20),

//               // ── Use Cases ──
//               const Text('Who Uses GPS Map Camera?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 12),
//               const _UseCaseChips(),
//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Quick Stats ──────────────────────────────────────────────────────────────

// class _QuickStats extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.cardBorder),
//       ),
//       child: Row(
//         children: [
//           _StatItem(value: '12', label: 'Photos', icon: Icons.photo_rounded, color: AppColors.secondary),
//           _VertDiv(),
//           _StatItem(value: '2', label: 'Locations', icon: Icons.location_on_rounded, color: AppColors.primary),
//           _VertDiv(),
//           _StatItem(value: '8', label: 'Templates', icon: Icons.grid_view_rounded, color: Colors.purple),
//         ],
//       ),
//     );
//   }
// }

// class _StatItem extends StatelessWidget {
//   final String value;
//   final String label;
//   final IconData icon;
//   final Color color;
//   const _StatItem({required this.value, required this.label, required this.icon, required this.color});
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
//           ),
//           Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
//         ],
//       ),
//     );
//   }
// }

// class _VertDiv extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Container(width: 1, height: 36, color: AppColors.divider);
// }

// // ─── Quick Capture CTA ────────────────────────────────────────────────────────

// class _QuickCaptureBanner extends StatelessWidget {
//   final VoidCallback onTap;
//   const _QuickCaptureBanner({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 70,
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 20),
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
//               child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
//             ),
//             const SizedBox(width: 14),
//             const Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Capture with GPS Stamp',
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
//                 ),
//                 Text('Tap to open camera', style: TextStyle(color: Colors.white54, fontSize: 12)),
//               ],
//             ),
//             const Spacer(),
//             const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
//             const SizedBox(width: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Features Grid ────────────────────────────────────────────────────────────

// class _FeaturesGrid extends StatelessWidget {
//   const _FeaturesGrid();

//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       _FItem(
//         Icons.grid_view_rounded,
//         'Templates',
//         '8 preset styles',
//         const Color(0xFFFFF3E0),
//         const Color(0xFFFF8F00),
//         const TemplatesView(),
//       ),
//       _FItem(
//         Icons.collections_rounded,
//         'Gallery',
//         'Browse & manage',
//         const Color(0xFFE8F5E9),
//         const Color(0xFF2E7D32),
//         const GalleryView(),
//       ),
//       _FItem(
//         Icons.edit_location_alt_rounded,
//         'Locations',
//         'Manual GPS edit',
//         const Color(0xFFE0F7FA),
//         const Color(0xFF00695C),
//         const LocationsView(),
//       ),
//     ];

//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 3,
//       mainAxisSpacing: 10,
//       crossAxisSpacing: 10,
//       childAspectRatio: 0.95,
//       children: items.map((item) {
//         return GestureDetector(
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => item.destination)),
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: item.color,
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: AppColors.cardBorder),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(item.icon, color: item.iconColor, size: 28),
//                 const SizedBox(height: 8),
//                 Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
//                 const SizedBox(height: 2),
//                 Text(item.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// class _FItem {
//   final IconData icon;
//   final String label;
//   final String subtitle;
//   final Color color;
//   final Color iconColor;
//   final Widget destination;
//   const _FItem(this.icon, this.label, this.subtitle, this.color, this.iconColor, this.destination);
// }

// // ─── Tools List ───────────────────────────────────────────────────────────────

// class _ToolsList extends StatelessWidget {
//   const _ToolsList();

//   @override
//   Widget build(BuildContext context) {
//     final tools = [
//       _TItem(
//         Icons.drive_file_rename_outline_rounded,
//         'File Name',
//         'Auto-name captured files',
//         const FileNameView(),
//         const Color(0xFF1565C0),
//       ),
//       _TItem(Icons.share_rounded, 'Quick Share', 'Share with Google Maps link', const GalleryView(), const Color(0xFF2E7D32)),
//     ];

//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.cardBorder),
//       ),
//       child: Column(
//         children: tools.asMap().entries.map((e) {
//           final isLast = e.key == tools.length - 1;
//           final t = e.value;
//           return Column(
//             children: [
//               ListTile(
//                 onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => t.destination)),
//                 leading: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(color: t.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
//                   child: Icon(t.icon, color: t.color, size: 20),
//                 ),
//                 title: Text(t.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
//                 subtitle: Text(t.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
//                 trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
//               ),
//               if (!isLast) const Divider(height: 0, indent: 60),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _TItem {
//   final IconData icon;
//   final String label;
//   final String subtitle;
//   final Widget destination;
//   final Color color;
//   const _TItem(this.icon, this.label, this.subtitle, this.destination, this.color);
// }

// // ─── Use Case Chips ───────────────────────────────────────────────────────────

// class _UseCaseChips extends StatelessWidget {
//   const _UseCaseChips();

//   @override
//   Widget build(BuildContext context) {
//     const cases = [
//       ('🏗️', 'Construction'),
//       ('🏠', 'Real Estate'),
//       ('✈️', 'Travel'),
//       ('🌾', 'Agriculture'),
//       ('🚚', 'Delivery Proof'),
//       ('📋', 'Inspections'),
//       ('🔭', 'Research'),
//       ('👮', 'Field Work'),
//     ];

//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: cases.map((c) {
//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//           decoration: BoxDecoration(
//             color: AppColors.surface,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: AppColors.divider),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(c.$1, style: const TextStyle(fontSize: 14)),
//               const SizedBox(width: 5),
//               Text(c.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
// }
