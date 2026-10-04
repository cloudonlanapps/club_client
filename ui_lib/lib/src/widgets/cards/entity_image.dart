import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/cards/entity_card.dart' show EntityCard;
import 'package:ui_lib/src/widgets/credentialed_network_image.dart'
    show CredentialedNetworkImage;
import 'package:ui_lib/ui_lib.dart' show EntityCard;

/// Square image content for the leading slot of an [EntityCard].
///
/// Three factories produce the three accepted variants. The outer card sizes
/// the image (square, full card height) and clips its left corners to match
/// the card border radius. This widget only produces the inner content.
class EntityImage extends StatelessWidget {
  const EntityImage._({
    this.imageUrl,
    this.initials,
    this.backgroundColor,
    this.httpHeaders = const {},
  });

  /// Renders [imageUrl] via [CredentialedNetworkImage] with `BoxFit.cover`.
  ///
  /// Pass [httpHeaders] (typically from `imageAuthHeadersProvider`) when
  /// the URL points at an auth-protected endpoint.
  factory EntityImage.network(
    String imageUrl, {
    Map<String, String> httpHeaders = const {},
  }) => EntityImage._(imageUrl: imageUrl, httpHeaders: httpHeaders);

  /// Renders [letters] centred on a muted background.
  factory EntityImage.initials(String letters) =>
      EntityImage._(initials: letters);

  /// Renders a plain coloured square. Defaults to the theme's muted colour.
  factory EntityImage.placeholder({Color? background}) =>
      EntityImage._(backgroundColor: background);

  final String? imageUrl;
  final String? initials;
  final Color? backgroundColor;
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (imageUrl != null) {
      return CredentialedNetworkImage(
        imageUrl: imageUrl!,
        httpHeaders: httpHeaders,
        fit: BoxFit.cover,
        errorBuilder: (_) => EntityImagePlaceholder(
          background: theme.colorScheme.muted,
        ),
      );
    }

    if (initials != null) {
      return EntityImageInitials(
        letters: initials!,
        background: theme.colorScheme.muted,
        foreground: theme.colorScheme.mutedForeground,
      );
    }

    return EntityImagePlaceholder(
      background: backgroundColor ?? theme.colorScheme.muted,
    );
  }
}

class EntityImagePlaceholder extends StatelessWidget {
  const EntityImagePlaceholder({required this.background, super.key});

  final Color background;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: background, child: const SizedBox.expand());
}

class EntityImageInitials extends StatelessWidget {
  const EntityImageInitials({
    required this.letters,
    required this.background,
    required this.foreground,
    super.key,
  });

  final String letters;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Center(
        child: Text(
          letters,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
