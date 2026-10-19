import 'package:flutter/material.dart';

import '../page_content/page_type.dart';
import '../page_content/site_copy.dart';
import 'site_page_data_content.dart';

/// A content page whose copy [SiteCopy] holds for [pageType].
///
/// Builds, in order: the hero; the active section header and
/// [activeContent], or the empty state when [activeContent] is null; the
/// past section header and [pastContent]; the CTA.
class PageDataScaffold extends StatelessWidget {
  const PageDataScaffold({
    required this.pageType,
    super.key,
    this.activeContent,
    this.pastContent,
  });

  /// The page type to fetch data for.
  final PageType pageType;

  /// Content for the active section. If null, shows empty state instead.
  final Widget? activeContent;

  /// Content for the past section. Only shown if pastContent is provided
  /// and pageData.pastSection is not null.
  final Widget? pastContent;

  @override
  Widget build(BuildContext context) {
    return SitePageDataContent(
      pageData: SiteCopy.of(context).pageData(pageType),
      activeContent: activeContent,
      pastContent: pastContent,
    );
  }
}
