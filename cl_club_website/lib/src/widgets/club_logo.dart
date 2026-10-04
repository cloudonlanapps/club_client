import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/site_config.dart';

/// The host's club logo, `assets/images/club_logo.png`.
///
/// Falls back to the club's short name if the asset is missing.
class ClubLogo extends ConsumerWidget {
  const ClubLogo({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Image.asset(
      kClubLogoAsset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        ref.watch(siteConfigProvider).shortName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: height != null ? height! * 0.5 : 14,
          color: ShadTheme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
