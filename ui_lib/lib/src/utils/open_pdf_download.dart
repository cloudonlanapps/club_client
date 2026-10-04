import 'package:url_launcher/url_launcher.dart';

/// Opens a gallery PDF's [url] outside the app, exactly as given.
///
/// The URL is the API's own media download URL
/// (`…/media/by_id/<uuid>/download`), and it is opened unchanged: no website
/// origin serves a `/downloads/…` copy of API media (#67). The browser (or the
/// platform's handler) fetches it without the app's bearer token, which the
/// server accepts for `public` media — every event-gallery upload is public.
///
/// Returns whether the platform reported the URL as launched.
Future<bool> openPdfDownload(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
