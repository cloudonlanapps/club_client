import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/site_strings.dart';
import '../providers/site_strings.dart';

/// Holds the pages back until the site's copy has loaded, then puts it in
/// scope for [SiteStrings.of].
///
/// The copy is a bundled asset, so the loading state lasts one asset read.
/// A failure has no copy to explain itself with, so it says so plainly.
class SiteStringsGate extends ConsumerWidget {
  const SiteStringsGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = ShadTheme.of(context).colorScheme.background;
    return ref
        .watch(siteStringsProvider)
        .when(
          data: (strings) => SiteStringsScope(strings: strings, child: child),
          loading: () => ColoredBox(
            color: background,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ColoredBox(
            color: background,
            child: const Center(child: Text('The site could not load.')),
          ),
        );
  }
}
