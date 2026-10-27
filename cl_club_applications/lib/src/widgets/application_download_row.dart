import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../models/application_download.dart';
import 'application_download_button.dart';

/// One application a member can download: its title and an
/// [ApplicationDownloadButton] for [download], which hands the PDF to
/// [pdfAction] named after [title].
class ApplicationDownloadRow extends StatelessWidget {
  const ApplicationDownloadRow({
    required this.title,
    required this.download,
    required this.pdfAction,
    this.onOpenProfile,
    super.key,
  });

  /// The application's title.
  final String title;

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
            fileName: PdfAction.fileNameFor(title),
            onOpenProfile: onOpenProfile,
          ),
        ],
      ),
    );
  }
}
