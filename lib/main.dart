import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/features/splash/splash_view.dart';
import 'package:gps_map_camera/services/storage_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefHelper.init();
  runApp(const ProviderScope(child: GPSMapCameraApp()));
}

class GPSMapCameraApp extends StatelessWidget {
  const GPSMapCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS CAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC107))),
      home: const SplashView(),
    );
  }
}
