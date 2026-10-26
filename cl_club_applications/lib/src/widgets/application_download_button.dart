import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../utils/application_download_refusal.dart';

/// Downloads one application PDF — a member's form or an admin's preview
/// ([download]) — and hands its bytes to [onOpenPdfBytes], which opens them
/// (the app's `openPdfBytes`).
///
/// While it downloads the button is off and shows a spinner. A refusal
/// about the member or the application (not eligible, no identity
/// document, no longer published) shows as a clear message under the
/// button; any other failure is a toast with a fixed message.
class ApplicationDownloadButton extends ConsumerStatefulWidget {
  const ApplicationDownloadButton({
    required this.download,
    required this.onOpenPdfBytes,
    this.label = ApplicationViewStrings.download,
    super.key,
  });

  /// The PDF to fetch.
  final ApplicationDownload download;

  /// Opens the downloaded PDF.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// The button's text.
  final String label;

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

  /// Fetches the PDF and opens it.
  Future<void> run() async {
    if (downloading) return;
    setState(() {
      downloading = true;
      refusal = null;
    });
    try {
      final notifier = ref.read(clApplicationsMasterProvider.notifier);
      final bytes = await widget.download.fetch(notifier);
      if (mounted) widget.onOpenPdfBytes(bytes);
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
              : const Icon(LucideIcons.download),
          child: Text(widget.label),
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
