import 'package:flutter_riverpod/flutter_riverpod.dart';

// --------------- Model ---------------

class OnboardingPage {
  final String title;
  final String subtitle;
  final String illustrationTag; // used to identify illustration

  const OnboardingPage({required this.title, required this.subtitle, required this.illustrationTag});
}

// --------------- State ---------------

class OnboardingState {
  final int currentPage;
  final List<OnboardingPage> pages;

  const OnboardingState({this.currentPage = 0, required this.pages});

  bool get isLastPage => currentPage == pages.length - 1;

  OnboardingState copyWith({int? currentPage, List<OnboardingPage>? pages}) {
    return OnboardingState(currentPage: currentPage ?? this.currentPage, pages: pages ?? this.pages);
  }
}

// --------------- Controller ---------------

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController()
    : super(
        OnboardingState(
          pages: const [
            OnboardingPage(
              title: 'Capture Authenticity,\nAnywhere in the World',
              subtitle: 'Where Every Photo Tells 100% Truth',
              illustrationTag: 'camera',
            ),
            OnboardingPage(
              title: 'Edit Location Name\nAbout Privacy',
              subtitle: 'Make It More Authentic',
              illustrationTag: 'map',
            ),
            OnboardingPage(
              title: 'Highly-Rated GPS\nMap Camera App',
              subtitle: 'Trusted by Millions',
              illustrationTag: 'ratings',
            ),
          ],
        ),
      );

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }
}

// --------------- Provider ---------------

final onboardingControllerProvider = StateNotifierProvider<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(),
);
