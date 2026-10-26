import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView;

/// Screen wrapper around [ProfileView] for `/memberzone/profile`.
///
/// Resolves the current user from `authStateProvider` and forwards it
/// to the view. Any authenticated user can view their own profile, so
/// no role gate is applied.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    required this.eventsSection,
    this.applicationsSection,
    this.onBack,
    super.key,
  });

  final Widget Function(String username) eventsSection;

  /// Builds the Applications section (club_client#321) for the member and
  /// whether they are the signed-in member.
  final Widget Function(UserPrivate member, {required bool own})?
  applicationsSection;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return const LoadingView(message: 'Loading profile…');
    }
    return ProfileView(
      currentUser: currentUser,
      eventsSection: eventsSection,
      applicationsSection: applicationsSection,
      onBack: onBack,
    );
  }
}
