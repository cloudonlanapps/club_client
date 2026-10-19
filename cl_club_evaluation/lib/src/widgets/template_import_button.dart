import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/template_file_strings.dart';
import '../models/evaluation_template_file.dart';
import '../models/template_file_exception.dart';

/// **Import** of the template library (club_client#27): picks a template
/// file through [onPickFile] and hands its contents to [onImported] as the
/// designer's initial values, nothing yet created. A file this app cannot
/// read is refused with a toast saying why.
class TemplateImportButton extends StatefulWidget {
  /// Imports through [onPickFile] into [onImported].
  const TemplateImportButton({
    required this.onPickFile,
    required this.onImported,
    super.key,
  });

  /// Picks a file and resolves to its bytes; `null` when none was chosen.
  final Future<Uint8List?> Function() onPickFile;

  /// Opens the designer with these initial values.
  final ValueChanged<Map<String, dynamic>> onImported;

  @override
  State<TemplateImportButton> createState() => TemplateImportButtonState();
}

/// State of [TemplateImportButton]: whether a file is being picked.
class TemplateImportButtonState extends State<TemplateImportButton> {
  /// Whether a file is being picked.
  bool picking = false;

  /// Picks a file and reads it, or says why it cannot be read.
  Future<void> import() async {
    setState(() => picking = true);
    final toaster = ShadToaster.of(context);
    try {
      final bytes = await widget.onPickFile();
      if (bytes == null) return;
      widget.onImported(EvaluationTemplateFile.initialValues(bytes));
    } on TemplateFileException catch (e) {
      toaster.show(ShadToast.destructive(description: Text(e.message)));
    } on Object {
      toaster.show(
        const ShadToast.destructive(
          description: Text(TemplateFileStrings.importFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => ShadButton.outline(
    onPressed: picking ? null : import,
    leading: const Icon(LucideIcons.upload),
    child: const Text(TemplateFileStrings.import),
  );
}
