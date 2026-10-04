import 'dart:io';

import 'package:cl_club_branding/src/providers/app_logo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the app's brand logo from [appLogoUriProvider].
///
/// Picks `Image.asset` / `Image.file` / `Image.network` based on the URI
/// scheme. Sizing is up to the caller.
class AppLogo extends ConsumerWidget {
  const AppLogo({
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = ref.watch(appLogoUriProvider);
    switch (uri.scheme) {
      case 'asset':
        return Image.asset(
          uri.path,
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
        );
      case 'file':
        return Image.file(
          File(uri.toFilePath()),
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
        );
      case 'http':
      case 'https':
        return Image.network(
          uri.toString(),
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
        );
      default:
        return SizedBox(width: width, height: height);
    }
  }
}
