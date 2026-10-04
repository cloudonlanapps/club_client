import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_config.dart';

const _themeConfigAssetPath = 'assets/config/theme.json';

/// Loads [ThemeConfig] from the bundled JSON asset once at app startup.
final themeConfigProvider = FutureProvider<ThemeConfig>((ref) async {
  final raw = await rootBundle.loadString(_themeConfigAssetPath);
  final map = json.decode(raw) as Map<String, dynamic>;
  return ThemeConfig.fromMap(map);
});
