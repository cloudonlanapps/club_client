import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../utils/application_download_refusal.dart';

/// Fetches one application PDF — a member's form or an admin's preview
/// ([download]) — and hands its bytes to [pdfAction] as [fileName]: the
/// app's share, download or viewer, whichever works on the platform
/// (club_client#324). The button shows the action's icon and, unless
/// [label] names it otherwise, its label.
///
/// While it downloads the button is off and shows a spinner. A refusal
/// about the member or the application (not eligible, no identity
/// document, no longer published) shows as a clear message under the
/// button; any other failure is a toast with a fixed message.
class ApplicationDownloadButton extends ConsumerStatefulWidget {
  const ApplicationDownloadButton({
    required this.download,
    required this.pdfAction,
    required this.fileName,
    this.label,
    super.key,
  });

  /// The PDF to fetch.
  final ApplicationDownload download;

  /// What the fetched PDF is handed to.
  final PdfAction pdfAction;

  /// The name the PDF is shared or saved under.
  final String fileName;

  /// The button's text; the action's label when null.
  final String? label;

  @override
  ConsumerState<ApplicationDownloadButton> createState() =>
      ApplicationDownloadButtonState();
}

/// State of [ApplicationDownloadButton]: the download in flight and the
/// last refusal.
class ApplicationDownloadButtonState
    extends ConsumerState<ApplicationDownloadButton> {
  /// Whether a download is in flight.
  bool downloading = false;

  /// What the server refused, shown under the button; null for nothing.
  String? refusal;

  /// Fetches the PDF and hands it to the action.
  Future<void> run() async {
    if (downloading) return;
    setState(() {
      downloading = true;
      refusal = null;
    });
    try {
      final notifier = ref.read(clApplicationsMasterProvider.notifier);
      final bytes = await widget.download.fetch(notifier);
      if (mounted) await widget.pdfAction.run(bytes, widget.fileName);
    } on Object catch (e) {
      if (!mounted) return;
      final message = applicationDownloadRefusal(e);
      if (message != null) {
        setState(() => refusal = message);
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text(ApplicationViewStrings.downloadFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final refused = refusal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: ApplicationViewSizes.smallGap,
      children: [
        ShadButton.outline(
          size: ShadButtonSize.sm,
          enabled: !downloading,
          onPressed: run,
          leading: downloading
              ? const SizedBox.square(
                  dimension: ApplicationViewSizes.spinner,
                  child: ShadProgress(),
                )
              : Icon(widget.pdfAction.icon),
          child: Text(widget.label ?? widget.pdfAction.label),
        ),
        if (refused != null)
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ApplicationViewSizes.refusalWidth,
            ),
            child: Text(
              refused,
              textAlign: TextAlign.end,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
      ],
    );
  }
}
