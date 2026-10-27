import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationTemplate;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_strings.dart';
import '../models/application_template_file.dart';
import '../utils/application_title.dart';

/// **Export JSON** of a finalized template: writes its content as a JSON
/// file named after it and hands it to [onSaveFile], to import it on
/// another server. Placed at the foot of the editor, apart from the moves.
class ApplicationExportButton extends StatefulWidget {
  const ApplicationExportButton({
    required this.template,
    required this.onSaveFile,
    super.key,
  });

  /// The template to export.
  final ApplicationTemplate template;

  /// Saves a file of this name and these bytes; resolves to whether it was
  /// saved (`false` when the save was cancelled).
  final Future<bool> Function(String fileName, Uint8List bytes) onSaveFile;

  @override
  State<ApplicationExportButton> createState() =>
      ApplicationExportButtonState();
}

/// State of [ApplicationExportButton]: whether the file is being saved.
class ApplicationExportButtonState extends State<ApplicationExportButton> {
  /// Whether the file is being saved.
  bool saving = false;

  /// Writes the file and saves it; says once it is saved, or that it could
  /// not be.
  Future<void> export() async {
    setState(() => saving = true);
    final toaster = ShadToaster.of(context);
    try {
      final saved = await widget.onSaveFile(
        ApplicationTemplateFile.fileName(applicationTitle(widget.template)),
        utf8.encode(ApplicationTemplateFile.encode(widget.template)),
      );
      if (saved) {
        toaster.show(
          const ShadToast(description: Text(ApplicationViewStrings.exported)),
        );
      }
    } on Object {
      toaster.show(
        const ShadToast.destructive(
          description: Text(ApplicationViewStrings.exportFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ShadButton.outline(
    key: const ValueKey('application.exportJson'),
    onPressed: saving ? null : () => unawaited(export()),
    leading: const Icon(LucideIcons.fileJson),
    child: const Text(ApplicationViewStrings.exportJson),
  );
}
