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

/// What the member app is called under its icon once installed (#367).
const memberAppLabel = 'Member App';

/// What [target] is called once installed and in its tab (#367): the app is
/// `<shortName> Member App`, labelled [memberAppLabel] under its icon (the
/// logo says which club); the website keeps the club's own names.
({String name, String iconLabel}) installedNames(
  Target target,
  WebNames names,
) => switch (target) {
  Target.app => (
    name: '${names.shortName} $memberAppLabel',
    iconLabel: memberAppLabel,
  ),
  Target.website => (name: names.fullName, iconLabel: names.shortName),
};

/// The page's own script, copied beside index.html from the template. The
/// page runs no inline script, so its policy needs no `'unsafe-inline'` for
/// scripts.
const indexScript = 'index.js';

/// The page's Content-Security-Policy: what the generated app and website may
/// load and where they may connect (#315).
///
/// - Scripts come from the page's own origin, plus CanvasKit, which Flutter
///   web fetches from `www.gstatic.com` and compiles as WebAssembly
///   (`'wasm-unsafe-eval'`).
/// - The API ([apiUrl]'s origin) answers requests and serves images and video.
/// - Flutter's fallback fonts come from `fonts.gstatic.com`.
/// - Styles allow `'unsafe-inline'`: Flutter web sets inline styles on the
///   elements it draws with, and the splash's style is inline.
/// - A venue's map is an embedded Google Maps frame.
/// - `blob:` and `data:` cover pictures and video the app opens from
///   memory.
///
/// A meta tag cannot set `frame-ancestors` or reporting; those are the host's.
String contentSecurityPolicy({required String apiUrl}) {
  final api = Uri.parse(apiUrl).origin;
  const gstatic = 'https://www.gstatic.com';
  const fonts = 'https://fonts.gstatic.com';
  return [
    "default-src 'self'",
    "script-src 'self' 'wasm-unsafe-eval' $gstatic",
    "connect-src 'self' $api $gstatic $fonts",
    "img-src 'self' data: blob: $api",
    "media-src 'self' blob: $api",
    "font-src 'self' data: $fonts",
    "style-src 'self' 'unsafe-inline'",
    'frame-src https://www.google.com',
    "worker-src 'self' blob:",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join('; ');
}

/// Fills the `@@TOKEN@@`s of the index.html template. Fails on any token
/// left over, so a template change cannot ship a page with a raw token in it.
///
/// [apiUrl] is the API the page talks to, which its policy allows
/// ([contentSecurityPolicy]). [description] is the page's description;
/// without one it is the club's name and what the target is.
String renderIndexHtml({
  required String apiUrl,
  required String template,
  required Target target,
  required WebNames names,
  required WebColors colors,
  String? description,
}) {
  const escape = HtmlEscape();
  final values = {
    'FULL_NAME': escape.convert(names.fullName),
    'PAGE_NAME': escape.convert(installedNames(target, names).name),
    'SHORT_NAME': escape.convert(names.shortName),
    'DESCRIPTION': escape.convert(
      description ?? defaultDescription(target, names),
    ),
    'BACKGROUND_LIGHT': colors.backgroundLight,
    'BACKGROUND_DARK': colors.backgroundDark,
    'ACCENT_LIGHT': colors.accentLight,
    'ACCENT_DARK': colors.accentDark,
    'CONTENT_SECURITY_POLICY': const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(contentSecurityPolicy(apiUrl: apiUrl)),
    'INDEX_SCRIPT': indexScript,
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

  final installed = installedNames(target, names);
  final manifest = {
    'name': installed.name,
    'short_name': installed.iconLabel,
    'start_url': '.',
    // A browser offers to install only a page that opens in its own window,
    // so the website, shown as "browser", is not offered (#367).
    'display': target == Target.app ? 'standalone' : 'browser',
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

/// The brand's `icon_1024.png`, checked: readable, square, at least 512 px.
img.Image decodeBrandIcon(Uint8List source) {
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
  return image;
}

/// The web icons, keyed by their path under `web/`, resized from the brand's
/// square source image (at least 512 px).
Map<String, Uint8List> renderIcons(Uint8List source) {
  final image = decodeBrandIcon(source);
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
    // 32 px: the brands' logos blur at 16 (#367).
    'favicon.png': sized(32),
    'icons/Icon-192.png': icon192,
    'icons/Icon-512.png': icon512,
    'icons/Icon-maskable-192.png': icon192,
    'icons/Icon-maskable-512.png': icon512,
  };
}
