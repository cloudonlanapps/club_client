import 'package:cl_remote_store/src/models/contact_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The contact block the host bundles (`assets/data/contact_info.json`,
/// read with [ContactInfo.fromBundled]): what `contactInfoProvider` shows
/// until the server answers, and for every field the server leaves out.
///
/// Overridden by the integrator — `clubMain()` in cl_club_app,
/// `websiteMain()` in cl_club_website. The default throws: a host that
/// reaches it is misconfigured, and there is no club-neutral contact block
/// to invent.
final Provider<ContactInfo> bundledContactInfoProvider = Provider<ContactInfo>(
  (ref) => throw UnimplementedError(
    'bundledContactInfoProvider was read without being overridden. It is '
    'supplied by clubMain() / websiteMain(); a test overrides it explicitly.',
  ),
);
