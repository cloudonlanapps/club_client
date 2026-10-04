import '../models/dashboard_panel_id.dart';

/// Build SharedPreferences keys and (de)serialise [DashboardPanelId] sets for
/// the dashboard prefs notifier.
abstract class DashboardPrefsStorage {
  static const String keyPrefix = 'dashboard.';
  static const String selectedSuffix = '.selected';
  static const String expandedMobileSuffix = '.expandedMobile';

  static String selectedKey(String username) =>
      '$keyPrefix$username$selectedSuffix';

  static String expandedKey(String username) =>
      '$keyPrefix$username$expandedMobileSuffix';

  /// Decodes a stored list of panel-id names. Unknown names are skipped.
  static Set<DashboardPanelId> decodeIds(List<String>? raw) {
    if (raw == null) return const <DashboardPanelId>{};
    final byName = {for (final v in DashboardPanelId.values) v.name: v};
    return raw.map((s) => byName[s]).whereType<DashboardPanelId>().toSet();
  }

  /// Encodes a panel-id set as a list of names suitable for SharedPreferences.
  static List<String> encodeIds(Iterable<DashboardPanelId> ids) =>
      ids.map((e) => e.name).toList(growable: false);
}
