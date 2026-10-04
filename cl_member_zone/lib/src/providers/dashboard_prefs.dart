import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_panel_id.dart';
import '../models/dashboard_prefs.dart';
import '../utils/dashboard_layout.dart';
import '../utils/dashboard_prefs_storage.dart';
import '../utils/panel_registry.dart';

/// Owns the [DashboardPrefs] for the currently authenticated user.
///
/// Persists changes to SharedPreferences keyed per username via
/// [DashboardPrefsStorage]. Rebuilds when [authStateProvider] changes so a
/// new login sees that user's prefs.
final dashboardPrefsProvider =
    AsyncNotifierProvider<DashboardPrefsNotifier, DashboardPrefs>(
      DashboardPrefsNotifier.new,
    );

class DashboardPrefsNotifier extends AsyncNotifier<DashboardPrefs> {
  SharedPreferences? prefs;
  String? username;

  @override
  Future<DashboardPrefs> build() async {
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;
    if (user == null) {
      return const DashboardPrefs(
        selected: <DashboardPanelId>{},
        expandedOnMobile: <DashboardPanelId>{},
      );
    }

    final isAdmin = user.roles.isAdmin || user.isSuperAdmin;
    final isCoach = user.roles.isCoach;
    final allowed = visiblePanelsFor(
      isAdmin: isAdmin,
      isCoach: isCoach,
    ).map((p) => p.id);
    final allowedSet = allowed.toSet();

    prefs = await SharedPreferences.getInstance();
    username = user.username;

    final storedSelected = prefs!.getStringList(
      DashboardPrefsStorage.selectedKey(user.username),
    );
    final storedExpanded = prefs!.getStringList(
      DashboardPrefsStorage.expandedKey(user.username),
    );

    final Set<DashboardPanelId> selected;
    final Set<DashboardPanelId> expanded;

    if (storedSelected == null) {
      // First-run defaults: every allowed panel selected; the first
      // [DashboardLayout.mobileInitiallyExpandedCount] panels in display
      // order start expanded on mobile.
      selected = allowedSet;
      expanded = allowed
          .take(DashboardLayout.mobileInitiallyExpandedCount)
          .toSet();
      await prefs!.setStringList(
        DashboardPrefsStorage.selectedKey(user.username),
        DashboardPrefsStorage.encodeIds(selected),
      );
      await prefs!.setStringList(
        DashboardPrefsStorage.expandedKey(user.username),
        DashboardPrefsStorage.encodeIds(expanded),
      );
    } else {
      // Filter persisted IDs through the role gate so a role downgrade can't
      // resurrect forbidden panels.
      selected = DashboardPrefsStorage.decodeIds(
        storedSelected,
      ).intersection(allowedSet);
      expanded = DashboardPrefsStorage.decodeIds(
        storedExpanded,
      ).intersection(selected).toSet();
    }

    return DashboardPrefs(selected: selected, expandedOnMobile: expanded);
  }

  Future<void> setSelected(Set<DashboardPanelId> next) async {
    final localPrefs = prefs;
    final user = username;
    if (localPrefs == null || user == null) return;
    final current = state.valueOrNull;
    if (current == null) return;
    final expanded = current.expandedOnMobile.intersection(next);
    state = AsyncData(
      current.copyWith(selected: next, expandedOnMobile: expanded),
    );
    await localPrefs.setStringList(
      DashboardPrefsStorage.selectedKey(user),
      DashboardPrefsStorage.encodeIds(next),
    );
    await localPrefs.setStringList(
      DashboardPrefsStorage.expandedKey(user),
      DashboardPrefsStorage.encodeIds(expanded),
    );
  }

  Future<void> closePanel(DashboardPanelId id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.selected.contains(id)) return;
    final next = current.selected.toSet()..remove(id);
    await setSelected(next);
  }

  Future<void> setExpandedOnMobile(Set<DashboardPanelId> next) async {
    final localPrefs = prefs;
    final user = username;
    if (localPrefs == null || user == null) return;
    final current = state.valueOrNull;
    if (current == null) return;
    final clamped = next.intersection(current.selected);
    if (setEquals(clamped, current.expandedOnMobile)) return;
    state = AsyncData(current.copyWith(expandedOnMobile: clamped));
    await localPrefs.setStringList(
      DashboardPrefsStorage.expandedKey(user),
      DashboardPrefsStorage.encodeIds(clamped),
    );
  }
}
