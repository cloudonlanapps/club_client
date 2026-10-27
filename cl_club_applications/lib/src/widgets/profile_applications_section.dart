import 'package:cl_remote_store/cl_remote_store.dart'
    show applicationsProvider, clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../utils/application_title.dart';
import 'application_download_row.dart';

/// The Applications section of a member's profile (club_client#321): each
/// published application with a button to download [member]'s form of it.
///
/// On one's own profile ([own]) it downloads the signed-in member's form;
/// an admin on another member's profile downloads that member's. The host
/// shows it to no one else. Renders nothing unless the server offers
/// applications.
class ProfileApplicationsSection extends ConsumerWidget {
  const ProfileApplicationsSection({
    required this.member,
    required this.own,
    required this.pdfAction,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('profile.section.applications');

  /// The member whose profile it is.
  final UserPrivate member;

  /// Whether [member] is the signed-in member.
  final bool own;

  /// What a downloaded form is handed to: shared, saved or opened.
  final PdfAction pdfAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(applicationsProvider) != true) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    final templates = ref.watch(clApplicationsMasterProvider).valueOrNull;
    final published = publishedApplications(templates?.values ?? const []);
    return ShadCard(
      key: cardKey,
      title: Text(
        ApplicationViewStrings.applications,
        style: theme.textTheme.h4,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: ApplicationViewSizes.smallGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ApplicationViewSizes.rowGap,
          children: [
            if (published.isEmpty)
              Text(
                ApplicationViewStrings.nothingToDownload,
                style: theme.textTheme.muted,
              )
            else ...[
              if (own)
                Text(
                  ApplicationViewStrings.printNote,
                  style: theme.textTheme.muted,
                ),
              for (final template in published)
                ApplicationDownloadRow(
                  title: applicationTitle(template),
                  download: own
                      ? ApplicationOwnForm(template.id)
                      : ApplicationMemberForm(template.id, member.username),
                  pdfAction: pdfAction,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
