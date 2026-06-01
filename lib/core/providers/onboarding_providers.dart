import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserType { student, teacher, both }

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false);
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('onboardingComplete') ?? false;
  }

  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
  }
}

final userTypeProvider = StateProvider<UserType>((ref) => UserType.student);

final aiSetupCompleteProvider =
    StateNotifierProvider<AISetupNotifier, bool>((ref) {
  return AISetupNotifier();
});

class AISetupNotifier extends StateNotifier<bool> {
  AISetupNotifier() : super(false);
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('aiSetupComplete') ?? false;
  }

  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiSetupComplete', true);
  }

  void completeSilent() => state = true;
}
