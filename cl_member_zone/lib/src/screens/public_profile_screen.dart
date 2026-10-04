import 'package:cl_club_members/cl_club_members.dart' show PublicProfileView;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicProfileProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

/// Public coach profile at `/memberzone/profile/:publicId`.
///
/// Reachable by any authenticated member (no role/relationship gate — the
/// member-zone shell already requires auth). Loads the privacy-safe
/// `PublicProfile` by its HMAC `publicId` and renders [PublicProfileView].
/// A non-surfaced / unknown id resolves to a neutral "unavailable" view.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    required this.publicId,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final String publicId;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clPublicProfileProvider(publicId));
    return profileAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        title: 'Profile unavailable',
        subtitle: 'This profile is not publicly available.',
        icon: LucideIcons.userX,
        tone: ErrorTone.neutral,
        errorCode: '$error',
        onHome: onHome,
        onBack: onBack,
        onRetry: () => ref.invalidate(clPublicProfileProvider(publicId)),
      ),
      data: (profile) => PublicProfileView(profile: profile, onBack: onBack),
    );
  }
}
