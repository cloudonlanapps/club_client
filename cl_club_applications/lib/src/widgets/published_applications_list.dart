import 'package:cl_remote_store/cl_remote_store.dart'
    show
        applicationsProvider,
        clApplicationsMasterProvider,
        clIdentityDocsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../utils/application_eligibility.dart';
import '../utils/application_title.dart';
import 'application_download_row.dart';

/// The published applications [currentUser] may download their own form
/// of, each with Download, under what to do with it: print it, affix a
/// passport-size photograph, sign it and hand it in (club_client#321).
///
/// Only the ones [currentUser] is eligible for are listed
/// ([isEligibleFor], club_client#380). A member with no date of birth fits
/// no age category, and is told to add one.
///
/// The member's Applications page and onboarding's waiting page show it.
/// Download first asks whether the member's profile is complete; **No**
/// calls [onOpenProfile] (club_client#340).
/// Without an identity document the server offers none, and the list says
/// so. Renders nothing unless the server offers applications.
class PublishedApplicationsList extends ConsumerWidget {
  const PublishedApplicationsList({
    required this.currentUser,
    required this.pdfAction,
    required this.onOpenProfile,
    super.key,
  });

  /// The signed-in member.
  final UserPrivate currentUser;

  /// What a downloaded form is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  /// Opens the member's profile page, for a member who says their profile
  /// is not complete.
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final templates = ref.watch(clApplicationsMasterProvider);
    if (templates.isLoading && !templates.hasValue) {
      return const Center(child: ShadProgress());
    }
    if (!templates.hasValue) {
      return Text(
        ApplicationViewStrings.loadFailed,
        style: theme.textTheme.muted,
      );
    }
    final published = publishedApplications(templates.requireValue.values);
    final open = published.where((t) => isEligibleFor(t, currentUser)).toList();
    final needsDateOfBirth = hiddenForMissingDateOfBirth(
      published,
      currentUser,
    );
    if (published.isEmpty) {
      final documents = ref.watch(
        clIdentityDocsMasterProvider(currentUser.username),
      );
      final none = documents.valueOrNull?.isEmpty ?? false;
      return Text(
        none
            ? ApplicationViewStrings.needsIdentityDocument
            : ApplicationViewStrings.noneOpen,
        style: theme.textTheme.muted,
      );
    }
    final dateOfBirthNote = Text(
      ApplicationViewStrings.needsDateOfBirth,
      style: theme.textTheme.muted,
    );
    if (open.isEmpty) {
      return needsDateOfBirth
          ? dateOfBirthNote
          : Text(ApplicationViewStrings.noneOpen, style: theme.textTheme.muted);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ApplicationViewSizes.rowGap,
      children: [
        Text(ApplicationViewStrings.printNote, style: theme.textTheme.muted),
        if (needsDateOfBirth) dateOfBirthNote,
        for (final template in open)
          ApplicationDownloadRow(
            key: ValueKey('application.download.${template.id}'),
            title: applicationTitle(template),
            member: currentUser,
            download: ApplicationOwnForm(template.id),
            pdfAction: pdfAction,
            onOpenProfile: onOpenProfile,
          ),
      ],
    );
  }
}
