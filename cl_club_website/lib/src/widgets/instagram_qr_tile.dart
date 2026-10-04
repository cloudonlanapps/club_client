import 'package:cl_club_branding/cl_club_branding.dart' show launchContactUrl;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The Instagram QR code. Tapping it opens [instagramUrl] in the external
/// browser / Instagram app.
///
/// Drawn from the URL rather than shipped as a PNG. A picture of a QR code
/// and the link beside it are two copies of the same fact, and the picture is
/// the one nobody notices has gone stale — it encodes a handle that changed
/// months ago and still scans, cleanly, to the wrong place. Generating it
/// makes that impossible, and takes 1.2MB of image out of the bundle.
class InstagramQrTile extends StatelessWidget {
  const InstagramQrTile({required this.instagramUrl, super.key});

  final String? instagramUrl;

  /// The code's side, in logical pixels.
  static const double size = 140;

  /// A QR code needs a light quiet zone to scan; in dark mode the card
  /// behind it is not one.
  static const Color quietZone = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final url = instagramUrl;

    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          LucideIcons.qrCode,
          size: 48,
          color: theme.colorScheme.mutedForeground,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchContactUrl(url),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: quietZone,
            borderRadius: BorderRadius.circular(8),
          ),
          child: QrImageView(
            data: url,
            size: size,
            backgroundColor: quietZone,
          ),
        ),
      ),
    );
  }
}
