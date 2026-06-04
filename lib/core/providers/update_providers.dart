import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/version_check_service.dart';

final lastUpdateCheckProvider = StateProvider<UpdateCheckResult?>((ref) => null);

final updateCheckFutureProvider = FutureProvider<UpdateCheckResult>((ref) {
  final service = VersionCheckService();
  return service.check();
});
