import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/roles/default_roles.dart';
import '../../core/roles/role_domain.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import 'widgets/role_card.dart';
import 'widgets/role_filter_bar.dart';
import 'widgets/role_search_bar.dart';

class RolesBrowserScreen extends ConsumerStatefulWidget {
  const RolesBrowserScreen({super.key});

  @override
  ConsumerState<RolesBrowserScreen> createState() => _RolesBrowserScreenState();
}

class _RolesBrowserScreenState extends ConsumerState<RolesBrowserScreen> {
  RoleDomain? _selectedDomain;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final roles = DefaultRoles.all;

    // Filter by domain and search
    var filtered = roles;
    if (_selectedDomain != null) {
      filtered = filtered.where((r) => r.domain == _selectedDomain).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.name.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ALL ROLES',
          style: AppTypography.headlineMedium(c.textPrimary),
        ),
      ),
      body: Column(
        children: [
          RoleSearchBar(onChanged: (v) => setState(() => _searchQuery = v)),
          RoleFilterBar(
            selectedDomain: _selectedDomain,
            onDomainChanged: (d) => setState(() => _selectedDomain = d),
          ),

          const SizedBox(height: 4),

          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${filtered.length} role${filtered.length == 1 ? '' : 's'}',
              style: AppTypography.labelSmall(c.textTertiary),
            ),
          ),

          // Role list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No roles found',
                      style: AppTypography.bodyMedium(c.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final role = filtered[index];
                      return RoleCard(role: role);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

