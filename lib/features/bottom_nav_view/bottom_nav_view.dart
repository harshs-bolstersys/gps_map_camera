// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gps_map_camera/core/constants/app_colors.dart';
// import 'package:gps_map_camera/features/camera/camera_view.dart';
// import 'package:gps_map_camera/features/gallery/gallery_view.dart';
// import 'package:gps_map_camera/features/settings/settings_view.dart';

// final homeTabProvider = StateProvider<int>((ref) => 0);

// class BottomNavView extends ConsumerWidget {
//   const BottomNavView({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final tab = ref.watch(homeTabProvider);

//     const pages = [CameraView(), GalleryView(), SettingsView()];

//     return Scaffold(
//       body: IndexedStack(index: tab, children: pages),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: tab,
//         onTap: (i) => ref.read(homeTabProvider.notifier).state = i,
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: AppColors.textSecondary,
//         selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
//         items: const [
//           // BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.camera_alt_rounded), label: 'Camera'),
//           BottomNavigationBarItem(icon: Icon(Icons.collections_rounded), label: 'Gallery'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
//         ],
//       ),
//     );
//   }
// }
