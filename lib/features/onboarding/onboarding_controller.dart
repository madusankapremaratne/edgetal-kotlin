import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  return OnboardingController();
});

class OnboardingController extends StateNotifier<bool> {
  OnboardingController() : super(false) {
    _init();
  }

  static const _key = 'has_completed_onboarding';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = true;
  }
}
