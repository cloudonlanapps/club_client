import 'package:flutter_riverpod/flutter_riverpod.dart';

/// URI of the app's brand logo.
///
/// Supported schemes:
/// - `asset:<package-relative-path>` — Flutter asset (e.g.
///   `asset:assets/images/club_logo.png`).
/// - `file:<absolute-path>` — local file on disk.
/// - `http:` / `https:` — network image.
///
/// The host app overrides this in its `ProviderScope` with the URI of the
/// logo it ships. The default is a placeholder asset URI that callers
/// should not rely on rendering.
final appLogoUriProvider = Provider<Uri>(
  (ref) => Uri.parse('asset:assets/images/placeholder_logo.png'),
);
