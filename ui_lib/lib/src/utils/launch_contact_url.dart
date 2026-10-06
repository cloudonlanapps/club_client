import 'package:url_launcher/url_launcher.dart';

/// Opens a contact link — `tel:`, `mailto:`, WhatsApp, Instagram — in the
/// app that handles it.
///
/// On web, `webOnlyWindowName: '_self'` hands the link to the browser's own
/// handler in the current tab instead of opening a blank popup the user has
/// to close on return; native platforms ignore it. A no-op for an empty URL
/// or when nothing handles it.
Future<void> launchContactUrl(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
  }
}
