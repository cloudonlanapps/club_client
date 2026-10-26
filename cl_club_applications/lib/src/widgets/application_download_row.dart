import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import 'application_download_button.dart';

/// One application a member can download: its title and an
/// [ApplicationDownloadButton] for [download].
class ApplicationDownloadRow extends StatelessWidget {
  const ApplicationDownloadRow({
    required this.title,
    required this.download,
    required this.onOpenPdfBytes,
    this.label = ApplicationViewStrings.download,
    super.key,
  });

  /// The application's title.
  final String title;

  /// The PDF the button fetches.
  final ApplicationDownload download;

  /// Opens the downloaded PDF.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// The button's text.
  final String label;

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
            onOpenPdfBytes: onOpenPdfBytes,
            label: label,
          ),
        ],
      ),
    );
  }
}
