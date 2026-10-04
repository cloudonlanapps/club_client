import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show mediaRefDownloadUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show PublicProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show CredentialedNetworkImage, ThemedMarkdown, TitleRow;

/// Read-only public profile for a coach, viewable by any logged-in member
/// (and reusable on a logged-out public website).
///
/// Renders only privacy-safe [PublicProfile] data — avatar, display name,
/// bio, achievements. Carries no SDK calls, role logic, or Riverpod fetch:
/// the host loads the [PublicProfile] (e.g. via `clPublicProfileProvider`)
/// and passes it in. It is a `ConsumerWidget` only to resolve the avatar's
/// signed download URL.
class PublicProfileView extends ConsumerWidget {
  const PublicProfileView({required this.profile, this.onBack, super.key});

  final PublicProfile profile;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(title: profile.displayName, onBack: onBack),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: _ProfileCard(profile: profile, isMobile: isMobile),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile, required this.isMobile});

  final PublicProfile profile;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final avatar = _Avatar(profile: profile);
    final content = _Content(profile: profile);

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: avatar,
                ),
              ),
            ),
            content,
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Positioned.fill keeps the avatar's LayoutBuilder out of
            // IntrinsicHeight's intrinsic-dimension pass (which a bare
            // LayoutBuilder can't satisfy) — mirrors ProfileCard.
            SizedBox(
              width: 260,
              child: Stack(children: [Positioned.fill(child: avatar)]),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// Avatar area: the public avatar image when available, else centered
/// initials on a muted background.
class _Avatar extends ConsumerWidget {
  const _Avatar({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final bg = theme.colorScheme.muted;
    final fg = theme.colorScheme.mutedForeground;
    final avatar = profile.avatar;
    if (avatar == null) return _initials(theme, bg, fg);

    final url = ref.watch(
      mediaRefDownloadUrlProvider((media: avatar, variant: 'original')),
    );
    final headers = ref.watch(imageAuthHeadersProvider).value ?? const {};
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: bg,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : constraints.maxWidth,
            child: CredentialedNetworkImage(
              imageUrl: url,
              httpHeaders: headers,
              fit: BoxFit.contain,
              errorBuilder: (_) => _initials(theme, bg, fg),
            ),
          ),
        );
      },
    );
  }

  Widget _initials(ShadThemeData theme, Color bg, Color fg) {
    final name = profile.displayName.trim();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return ColoredBox(
      color: bg,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Name + bio + achievements.
class _Content extends StatelessWidget {
  const _Content({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bio = profile.bio?.trim() ?? '';
    final achievements = profile.achievements?.trim() ?? '';
    final hasDetails = bio.isNotEmpty || achievements.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(profile.displayName, style: theme.textTheme.h3),
          const SizedBox(height: 16),
          if (bio.isNotEmpty) ...[
            ThemedMarkdown(data: bio, textAlign: TextAlign.justify),
            const SizedBox(height: 24),
          ],
          if (achievements.isNotEmpty) ...[
            Text('Achievements', style: theme.textTheme.h4),
            const SizedBox(height: 8),
            ThemedMarkdown(data: achievements, textAlign: TextAlign.justify),
          ],
          if (!hasDetails)
            Text(
              'No public details available.',
              style: theme.textTheme.muted,
            ),
        ],
      ),
    );
  }
}
