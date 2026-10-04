import 'target.dart';

/// The splash and browser-chrome colours, from `club.json`'s optional `web`
/// block. Each is `#RRGGBB`; a missing one takes the neutral default.
class WebColors {
  const WebColors({
    required this.backgroundLight,
    required this.backgroundDark,
    required this.accentLight,
    required this.accentDark,
  });

  factory WebColors.fromClubJson(Map<String, dynamic> clubJson) {
    final raw = clubJson['web'];
    if (raw != null && raw is! Map) {
      throw const GeneratorException('club.json: "web" must be an object');
    }
    final web = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    String pick(String key, String fallback) {
      final value = web[key];
      if (value == null) return fallback;
      if (value is! String || !_hex.hasMatch(value)) {
        throw GeneratorException(
          'club.json: web.$key must be a #RRGGBB colour, got "$value"',
        );
      }
      return value;
    }

    return WebColors(
      backgroundLight: pick('backgroundLight', neutral.backgroundLight),
      backgroundDark: pick('backgroundDark', neutral.backgroundDark),
      accentLight: pick('accentLight', neutral.accentLight),
      accentDark: pick('accentDark', neutral.accentDark),
    );
  }

  static const neutral = WebColors(
    backgroundLight: '#FFFFFF',
    backgroundDark: '#020817',
    accentLight: '#2563EB',
    accentDark: '#3B82F6',
  );

  static final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  final String backgroundLight;
  final String backgroundDark;
  final String accentLight;
  final String accentDark;
}
