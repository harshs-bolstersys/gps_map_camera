import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/core/constants/image_constant.dart';
import 'package:gps_map_camera/features/permissions/permission_view.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'onboarding_controller.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final state = ref.read(onboardingControllerProvider);

    if (state.isLastPage) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PermissionView()));
    } else {
      controller.nextPage();
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Illustration area
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _pageController,
                itemCount: state.pages.length,
                onPageChanged: (index) {
                  ref.read(onboardingControllerProvider.notifier).setPage(index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingIllustration(tag: state.pages[index].illustrationTag);
                },
              ),
            ),
            // Bottom content area
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Arrow row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                state.pages[state.currentPage].title,
                                key: ValueKey(state.currentPage),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Subtitle
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                state.pages[state.currentPage].subtitle,
                                key: ValueKey('sub_${state.currentPage}'),
                                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _NextButton(
                        onTap: _onNext,
                        isLastPage: state.isLastPage,
                        progress: (state.currentPage + 1) / state.pages.length,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // Dots indicator
                  Row(
                    children: List.generate(state.pages.length, (index) => _DotIndicator(isActive: index == state.currentPage)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Illustration per page ───────────────────────────────────────────────────

class _OnboardingIllustration extends StatelessWidget {
  final String tag;
  const _OnboardingIllustration({required this.tag});

  @override
  Widget build(BuildContext context) {
    switch (tag) {
      case 'camera':
        return Image.asset(ImageConstants.onboardingImage1, fit: BoxFit.cover);
      case 'map':
        return Image.asset(ImageConstants.onboardingImage2, fit: BoxFit.cover);
      case 'ratings':
        return Image.asset(ImageConstants.onboardingImage3, fit: BoxFit.cover);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Next Button ─────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLastPage;
  final double progress;

  const _NextButton({required this.onTap, required this.isLastPage, required this.progress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            SizedBox(
              width: 62,
              height: 62,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            // Inner circle
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: isLastPage ? AppColors.primary : const Color(0xFFE0E0E0), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded, color: isLastPage ? Colors.white : AppColors.textPrimary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot Indicator ───────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.divider, borderRadius: BorderRadius.circular(4)),
    );
  }
}
