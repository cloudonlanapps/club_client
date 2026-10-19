import 'dart:convert';
import 'dart:typed_data';

import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/template_file_strings.dart';
import '../models/evaluation_template_file.dart';

/// **Export** of a template (club_client#27): writes [template] as a JSON
/// file named after it and hands it to [onSaveFile]. Only reads, so it is
/// open for a template in use too.
class TemplateExportButton extends StatefulWidget {
  /// Exports [template] through [onSaveFile].
  const TemplateExportButton({
    required this.template,
    required this.onSaveFile,
    super.key,
  });

  /// The template to export.
  final EvaluationTemplate template;

  /// Saves a file of this name and these bytes; resolves to whether it was
  /// saved (`false` when the save was cancelled).
  final Future<bool> Function(String fileName, Uint8List bytes) onSaveFile;

  @override
  State<TemplateExportButton> createState() => TemplateExportButtonState();
}

/// State of [TemplateExportButton]: whether the file is being saved.
class TemplateExportButtonState extends State<TemplateExportButton> {
  /// Whether the file is being saved.
  bool saving = false;

  /// Writes the file and saves it; says once it is saved, or that it could
  /// not be.
  Future<void> export() async {
    setState(() => saving = true);
    final toaster = ShadToaster.of(context);
    try {
      final saved = await widget.onSaveFile(
        EvaluationTemplateFile.fileName(widget.template.name),
        utf8.encode(EvaluationTemplateFile.encode(widget.template)),
      );
      if (saved) {
        toaster.show(
          const ShadToast(description: Text(TemplateFileStrings.exported)),
        );
      }
    } on Object {
      toaster.show(
        const ShadToast.destructive(
          description: Text(TemplateFileStrings.exportFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ShadButton.outline(
    onPressed: saving ? null : export,
    child: const Text(TemplateFileStrings.export),
  );
}
