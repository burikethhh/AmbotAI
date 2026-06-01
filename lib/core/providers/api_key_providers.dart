import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/engine_selector.dart' show CloudProvider;
import '../services/secure_key_storage.dart';

final userGeminiKeyProvider =
    StateNotifierProvider<UserGeminiKeyNotifier, String?>((ref) {
  return UserGeminiKeyNotifier();
});

class UserGeminiKeyNotifier extends StateNotifier<String?> {
  UserGeminiKeyNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await SecureKeyStorage.getGeminiKey();
  }

  Future<void> set(String? value) async {
    state = value;
    await SecureKeyStorage.setGeminiKey(value);
  }
}

final userOpenRouterKeyProvider =
    StateNotifierProvider<UserOpenRouterKeyNotifier, String?>((ref) {
  return UserOpenRouterKeyNotifier();
});

class UserOpenRouterKeyNotifier extends StateNotifier<String?> {
  UserOpenRouterKeyNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await SecureKeyStorage.getOpenRouterKey();
  }

  Future<void> set(String? value) async {
    state = value;
    await SecureKeyStorage.setOpenRouterKey(value);
  }
}

final userQwenKeyProvider =
    StateNotifierProvider<UserQwenKeyNotifier, String?>((ref) {
  return UserQwenKeyNotifier();
});

class UserQwenKeyNotifier extends StateNotifier<String?> {
  UserQwenKeyNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await SecureKeyStorage.getQwenKey();
  }

  Future<void> set(String? value) async {
    state = value;
    await SecureKeyStorage.setQwenKey(value);
  }
}

final userHfTokenProvider =
    StateNotifierProvider<UserHfTokenNotifier, String?>((ref) {
  return UserHfTokenNotifier();
});

class UserHfTokenNotifier extends StateNotifier<String?> {
  UserHfTokenNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await SecureKeyStorage.getHfToken();
  }

  Future<void> set(String? value) async {
    state = value;
    await SecureKeyStorage.setHfToken(value);
  }
}

final userNvidiaKeyProvider =
    StateNotifierProvider<UserNvidiaKeyNotifier, String?>((ref) {
  return UserNvidiaKeyNotifier();
});

class UserNvidiaKeyNotifier extends StateNotifier<String?> {
  UserNvidiaKeyNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await SecureKeyStorage.getNvidiaKey();
  }

  Future<void> set(String? value) async {
    state = value;
    await SecureKeyStorage.setNvidiaKey(value);
  }
}

final userNvidiaKey2Provider =
    StateNotifierProvider<UserNvidiaKey2Notifier, String?>((ref) {
  return UserNvidiaKey2Notifier();
});

class UserNvidiaKey2Notifier extends StateNotifier<String?> {
  UserNvidiaKey2Notifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await SecureKeyStorage.getNvidiaKey2();
  }

  Future<void> set(String? value) async {
    state = value;
    await SecureKeyStorage.setNvidiaKey2(value);
  }
}

final cloudProviderProvider =
    StateProvider<CloudProvider>((ref) => CloudProvider.nvidia);
