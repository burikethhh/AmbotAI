import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../roles/role.dart';
import '../roles/default_roles.dart';

final rolesProvider = StateNotifierProvider<RolesNotifier, List<Role>>((ref) {
  final notifier = RolesNotifier();
  notifier.load();
  return notifier;
});

class RolesNotifier extends StateNotifier<List<Role>> {
  RolesNotifier() : super(DefaultRoles.all);

  static const _prefsKey = 'installed_role_ids';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final installedIds = prefs.getStringList(_prefsKey) ?? [];

    final baseRoles = DefaultRoles.all;

    if (installedIds.isEmpty) {
      state = baseRoles;
      return;
    }

    state = [
      for (final role in baseRoles)
        if (installedIds.contains(role.id))
          role.copyWith(isInstalled: true)
        else
          role.copyWith(isInstalled: false),
    ];
  }

  Future<void> toggleInstall(String roleId) async {
    final role = state.where((r) => r.id == roleId).firstOrNull;
    if (role == null) return;
    final newInstalled = !role.isInstalled;
    state = [
      for (final r in state)
        if (r.id == roleId)
          r.copyWith(isInstalled: newInstalled)
        else
          r,
    ];
    final prefs = await SharedPreferences.getInstance();
    final currentIds = prefs.getStringList(_prefsKey) ?? [];
    if (newInstalled) {
      if (!currentIds.contains(roleId)) {
        await prefs.setStringList(_prefsKey, [...currentIds, roleId]);
      }
    } else {
      await prefs.setStringList(_prefsKey, currentIds.where((id) => id != roleId).toList());
    }
  }

  void addCustomRole(Role role) {
    state = [...state, role];
  }

  List<Role> get installed => state.where((r) => r.isInstalled).toList();
}

final activeRoleProvider = StateProvider<Role?>((ref) => null);
