import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../models/application_download.dart';
import '../utils/application_file_name.dart';
import 'application_download_button.dart';

/// One application a member can download: its title and an
/// [ApplicationDownloadButton] for [download], which hands the PDF to
/// [pdfAction] named after [title] and [member] ([memberFormFileName],
/// club_client#404).
class ApplicationDownloadRow extends StatelessWidget {
  const ApplicationDownloadRow({
    required this.title,
    required this.member,
    required this.download,
    required this.pdfAction,
    this.onOpenProfile,
    super.key,
  });

  /// The application's title.
  final String title;

  /// The member whose form [download] fetches.
  final UserPrivate member;

  /// The PDF the button fetches.
  final ApplicationDownload download;

  /// What the fetched PDF is handed to.
  final PdfAction pdfAction;

  /// Opens the member's profile page when they answer **No** to "Is your
  /// profile complete?" (club_client#340); null only closes the dialog.
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(ApplicationViewSizes.rowPadding),
      child: Row(
        spacing: ApplicationViewSizes.smallGap,
        children: [
          Expanded(
            child: Text(title, style: ShadTheme.of(context).textTheme.p),
          ),
          ApplicationDownloadButton(
            download: download,
            pdfAction: pdfAction,
            fileName: memberFormFileName(title, member),
            onOpenProfile: onOpenProfile,
          ),
        ],
      ),
    );
  }
}
