import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ambot_ai/core/providers/roles_provider.dart';
import 'package:ambot_ai/core/roles/role.dart';
import 'package:ambot_ai/core/roles/default_roles.dart';

void main() {
  group('RolesNotifier', () {
    late RolesNotifier notifier;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      notifier = RolesNotifier();
    });

    test('starts with default roles', () {
      expect(notifier.state.length, DefaultRoles.all.length);
    });

    group('installed getter', () {
      test('returns only installed roles', () {
        final installed = notifier.installed;
        expect(installed.every((r) => r.isInstalled), isTrue);
      });

      test('excludes uninstalled roles', () {
        final nonInstalled =
            notifier.state.where((r) => !r.isInstalled).toList();
        final installed = notifier.installed;
        for (final r in nonInstalled) {
          expect(installed.any((i) => i.id == r.id), isFalse);
        }
      });
    });

    group('toggleInstall', () {
      test('installs a role', () async {
        final role = notifier.state.firstWhere((r) => !r.isInstalled);
        await notifier.toggleInstall(role.id);
        final updated =
            notifier.state.firstWhere((r) => r.id == role.id);
        expect(updated.isInstalled, isTrue);
      });

      test('uninstalls a role', () async {
        final role = notifier.state.firstWhere((r) => r.isInstalled);
        await notifier.toggleInstall(role.id);
        final updated =
            notifier.state.firstWhere((r) => r.id == role.id);
        expect(updated.isInstalled, isFalse);
      });

      test('installed getter reflects toggle', () async {
        final before = notifier.installed.length;
        final role = notifier.state.firstWhere((r) => !r.isInstalled);
        await notifier.toggleInstall(role.id);
        expect(notifier.installed.length, before + 1);
      });
    });

    group('addCustomRole', () {
      test('adds a role to the state', () {
        final custom = Role(
          id: 'custom_test',
          name: 'TestRole',
          description: 'A custom role',
          systemPrompt: 'You are a test role.',
          category: RoleCategory.universal,
          icon: Icons.star,
          createdAt: DateTime(2026, 1, 1),
          isCustom: true,
        );
        notifier.addCustomRole(custom);
        expect(notifier.state.length, DefaultRoles.all.length + 1);
        expect(notifier.state.any((r) => r.id == 'custom_test'), isTrue);
      });

      test('custom role appears in state list', () {
        final custom = Role(
          id: 'my_custom',
          name: 'MyCustom',
          description: 'desc',
          systemPrompt: 'prompt',
          category: RoleCategory.universal,
          icon: Icons.star,
          createdAt: DateTime(2026, 1, 1),
          isCustom: true,
        );
        notifier.addCustomRole(custom);
        expect(notifier.state.last.id, 'my_custom');
      });
    });
  });
}
