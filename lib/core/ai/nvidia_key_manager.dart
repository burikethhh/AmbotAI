import '../config/api_keys.dart';

/// Manages a pair of NVIDIA API keys with automatic rotation on rate-limit (429).
///
/// Priority: user override > compile-time default > null.
/// On 429: primary → secondary → error.
class NvidiaKeyManager {
  static final NvidiaKeyManager shared = NvidiaKeyManager._();

  NvidiaKeyManager._();

  String? _userKey1;
  String? _userKey2;
  bool _usingSecondary = false;

  void setUserKeys(String? key1, String? key2) {
    _userKey1 = key1;
    _userKey2 = key2;
    _usingSecondary = false;
  }

  /// Returns the currently active key.
  String? get activeKey {
    final key = _usingSecondary ? _resolvedKey2 : _resolvedKey1;
    return key?.isNotEmpty == true ? key : null;
  }

  /// The current key label for logging.
  String get activeLabel => _usingSecondary ? 'NVIDIA Key 2' : 'NVIDIA Key 1';

  /// Whether we have at least one usable key.
  bool get hasAnyKey =>
      (_resolvedKey1?.isNotEmpty == true) || (_resolvedKey2?.isNotEmpty == true);

  /// Switch to the secondary key after a rate-limit.
  void rotateOnRateLimit() {
    if (!_usingSecondary) {
      _usingSecondary = true;
    }
  }

  /// Reset to the primary key (e.g., on new request cycle).
  void reset() => _usingSecondary = false;

  String? get _resolvedKey1 => _userKey1?.isNotEmpty == true ? _userKey1 : ApiKeys.nvidiaKey1;

  String? get _resolvedKey2 => _userKey2?.isNotEmpty == true ? _userKey2 : ApiKeys.nvidiaKey2;
}
