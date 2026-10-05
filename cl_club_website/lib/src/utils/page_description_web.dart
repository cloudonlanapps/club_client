import 'package:web/web.dart' as web;

/// Where the description the site was built with is kept, on the tag itself.
const builtDescriptionAttribute = 'data-built-content';

/// Sets the document's `<meta name="description">` to [description], or back
/// to the one the site was built with when [description] is null.
void writePageDescription(String? description) {
  final tag = web.document.querySelector('meta[name="description"]');
  if (tag == null) return;
  final built =
      tag.getAttribute(builtDescriptionAttribute) ??
      tag.getAttribute('content') ??
      '';
  tag
    ..setAttribute(builtDescriptionAttribute, built)
    ..setAttribute('content', description ?? built);
}
