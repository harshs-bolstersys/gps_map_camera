import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/core/constants/image_constant.dart';
import 'package:gps_map_camera/features/camera/camera_view.dart';
import 'package:gps_map_camera/features/onboarding/onboarding_view.dart';
import 'package:gps_map_camera/services/storage_services.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'splash_controller.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashControllerProvider.notifier).initialize(() {
        if (!mounted) return;
        SharedPrefHelper.getBool('has_seen_permissions').then((hasSeenPermissions) {
          if (!mounted) return;
          if (hasSeenPermissions == true) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const CameraView()), (route) => false);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingView()),
              (route) => false,
            );
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(scale: _scaleAnimation, child: child),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo image
              Image.asset(ImageConstants.mainLogo, width: 110, height: 110),
              const SizedBox(height: 28),
              // App name
              const Text(
                'GPS CAM',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              // Tagline
              Text(
                'Geo Tagging · Timestamp · Location Stamp',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, letterSpacing: 0.3),
              ),
              const SizedBox(height: 60),
              // Loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
