import 'package:flutter_riverpod/flutter_riverpod.dart';

// --------------- State ---------------

class SplashState {
  final bool isLoading;

  const SplashState({this.isLoading = true});

  SplashState copyWith({bool? isLoading}) {
    return SplashState(isLoading: isLoading ?? this.isLoading);
  }
}

// --------------- Controller ---------------

class SplashController extends StateNotifier<SplashState> {
  SplashController() : super(const SplashState());

  Future<void> initialize(void Function() onComplete) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
    onComplete();
  }
}

// --------------- Provider ---------------

final splashControllerProvider =
    StateNotifierProvider<SplashController, SplashState>(
  (ref) => SplashController(),
);
