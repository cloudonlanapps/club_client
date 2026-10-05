import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_meta.dart';
import '../utils/page_description.dart';

/// The page on screen, as its `PageMetaPublisher` describes it. Null until
/// the first page has published; the app then shows the club's name.
final pageMetaProvider = StateProvider<PageMeta?>((ref) => null);

/// Writes a page's description where a search engine reads it. Overridden
/// in tests, which have no document to write to.
final pageDescriptionWriterProvider = Provider<void Function(String?)>(
  (ref) => writePageDescription,
);
