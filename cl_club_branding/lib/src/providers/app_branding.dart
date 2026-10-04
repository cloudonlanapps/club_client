import 'package:cl_club_branding/src/models/club_branding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Club brand strings used by the shared UI.
///
/// The host app overrides this in its `ProviderScope`, alongside
/// `appLogoUriProvider` and cl_remote_store's `bundledContactInfoProvider`
/// (the fallback under `contactInfoProvider`). The default is empty on
/// both fields, which keeps the libraries brand-neutral; callers should not
/// rely on the default rendering anything meaningful.
final appBrandingProvider = Provider<ClubBranding>(
  (ref) => const ClubBranding(
    fullName: '',
    shortName: '',
    heroSurface: ClubHeroSurface.secondary,
  ),
);
