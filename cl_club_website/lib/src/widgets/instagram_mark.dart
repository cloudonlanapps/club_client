import 'package:flutter/material.dart';

import '../icons/brand_icons.dart';
import '../models/site_config.dart';

/// The host's Instagram mark, `assets/images/instagram.png`.
///
/// Falls back to [BrandIcons.instagram] if the asset is missing, the way
/// `ClubLogo` treats `club_logo.png`: shipping a brand mark is the club's
/// licensing decision, so the package carries none.
class InstagramMark extends StatelessWidget {
  const InstagramMark({required this.size, this.color, super.key});

  /// Width and height of the mark.
  final double size;

  /// Colour of the fallback icon. The host's image keeps its own colours.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kInstagramMarkAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(BrandIcons.instagram, size: size, color: color),
    );
  }
}
