import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_meta.dart';
import '../models/site_config.dart';
import '../providers/page_meta.dart';
import '../utils/meta_description.dart';

/// Tells the app what the page on screen is called and about, through
/// [pageMetaProvider]: the browser title becomes `<pageName> | <club>` and
/// the document's description [description].
///
/// It publishes when it appears, when either value changes, and when its
/// route becomes the current one again, so the page on top always wins.
class PageMetaPublisher extends ConsumerStatefulWidget {
  const PageMetaPublisher({
    required this.child,
    this.pageName,
    this.description,
    super.key,
  });

  /// The page's name; null on the home page, whose title is the club's name.
  final String? pageName;

  /// What the page is about, as plain text or Markdown of any length; null
  /// keeps the description the site was built with.
  final String? description;

  final Widget child;

  @override
  ConsumerState<PageMetaPublisher> createState() => PageMetaPublisherState();
}

/// Publishes its widget's [PageMeta] after the frame that changed it.
class PageMetaPublisherState extends ConsumerState<PageMetaPublisher> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    publish();
  }

  @override
  void didUpdateWidget(PageMetaPublisher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageName != widget.pageName ||
        oldWidget.description != widget.description) {
      publish();
    }
  }

  /// Hands this page's [PageMeta] to the app, unless another route covers it.
  void publish() {
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final clubName = ref.read(siteConfigProvider).fullName;
    final pageName = widget.pageName;
    final meta = PageMeta(
      title: pageName == null ? clubName : '$pageName | $clubName',
      description: metaDescriptionFrom(widget.description),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pageMetaProvider.notifier).state = meta;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
