import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'target.dart';
import 'web_colors.dart';

/// The names a page shows, from `club.json`.
class WebNames {
  const WebNames({required this.fullName, required this.shortName});

  factory WebNames.fromClubJson(Map<String, dynamic> clubJson) {
    String required(String key) {
      final value = clubJson[key];
      if (value is String && value.isNotEmpty) return value;
      throw GeneratorException('club.json: "$key" is missing');
    }

    return WebNames(
      fullName: required('fullName'),
      shortName: required('shortName'),
    );
  }

  final String fullName;
  final String shortName;
}

/// Fills the `@@TOKEN@@`s of the index.html template. Fails on any token
/// left over, so a template change cannot ship a page with a raw token in it.
///
/// [description] is the page's description; without one it is the club's
/// name and what the target is.
String renderIndexHtml({
  required String template,
  required Target target,
  required WebNames names,
  required WebColors colors,
  String? description,
}) {
  const escape = HtmlEscape();
  final values = {
    'FULL_NAME': escape.convert(names.fullName),
    'SHORT_NAME': escape.convert(names.shortName),
    'DESCRIPTION': escape.convert(
      description ?? defaultDescription(target, names),
    ),
    'BACKGROUND_LIGHT': colors.backgroundLight,
    'BACKGROUND_DARK': colors.backgroundDark,
    'ACCENT_LIGHT': colors.accentLight,
    'ACCENT_DARK': colors.accentDark,
  };
  final out = template.replaceAllMapped(
    RegExp('@@([A-Z_]+)@@'),
    (m) =>
        values[m[1]] ??
        (throw GeneratorException('index.html: unknown token ${m[0]}')),
  );
  return out;
}

/// The description of a page that is given none: `<fullName> - <suffix>`.
String defaultDescription(Target target, WebNames names) =>
    '${names.fullName} - ${target.descriptionSuffix}';

/// The web app manifest, described as [renderIndexHtml] describes the page.
String renderManifest({
  required Target target,
  required WebNames names,
  required WebColors colors,
  String? description,
}) {
  Map<String, String> icon(String file, int size, {bool maskable = false}) => {
    'src': 'icons/$file',
    'sizes': '${size}x$size',
    'type': 'image/png',
    if (maskable) 'purpose': 'maskable',
  };

  final manifest = {
    'name': names.fullName,
    'short_name': names.shortName,
    'start_url': '.',
    'display': 'standalone',
    'background_color': colors.backgroundLight,
    'theme_color': colors.backgroundLight,
    'description': description ?? defaultDescription(target, names),
    'orientation': 'portrait-primary',
    'prefer_related_applications': false,
    'icons': [
      icon('Icon-192.png', 192),
      icon('Icon-512.png', 512),
      icon('Icon-maskable-192.png', 192, maskable: true),
      icon('Icon-maskable-512.png', 512, maskable: true),
    ],
  };
  return '${const JsonEncoder.withIndent('    ').convert(manifest)}\n';
}

/// The web icons, keyed by their path under `web/`, resized from the brand's
/// square source image (at least 512 px).
Map<String, Uint8List> renderIcons(Uint8List source) {
  final image = img.decodeImage(source);
  if (image == null) {
    throw const GeneratorException('icon_1024.png is not a readable image');
  }
  if (image.width != image.height || image.width < 512) {
    throw GeneratorException(
      'icon_1024.png must be square and at least 512 px, '
      'got ${image.width}x${image.height}',
    );
  }
  Uint8List sized(int size) => img.encodePng(
    img.copyResize(
      image,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    ),
  );
  final icon192 = sized(192);
  final icon512 = sized(512);
  return {
    'favicon.png': sized(16),
    'icons/Icon-192.png': icon192,
    'icons/Icon-512.png': icon512,
    'icons/Icon-maskable-192.png': icon192,
    'icons/Icon-maskable-512.png': icon512,
  };
}
