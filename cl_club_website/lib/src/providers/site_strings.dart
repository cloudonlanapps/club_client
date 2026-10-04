import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/site_strings.dart';

/// Where the host keeps its copy.
const kSiteStringsAsset = 'assets/l10n/app_en.arb';

/// The site's copy, read from the host's bundled ARB.
///
/// Everything that shows copy reads it through here, so where the copy comes
/// from can change without the pages noticing. Per-language copy from the
/// server would replace [build] with a stream that yields this bundled copy
/// first and a downloaded language only once it has fully arrived.
class SiteStringsNotifier extends AsyncNotifier<SiteStrings> {
  @override
  Future<SiteStrings> build() async {
    final raw = await rootBundle.loadString(kSiteStringsAsset);
    return SiteStrings.fromArb(json.decode(raw) as Map<String, dynamic>);
  }
}

final siteStringsProvider =
    AsyncNotifierProvider<SiteStringsNotifier, SiteStrings>(
      SiteStringsNotifier.new,
    );
