import 'dart:typed_data';

import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show PdfAction;

/// The label of [recordingPdfAction].
const String testPdfActionLabel = 'Download';

/// A PDF action shown as Download that records what it is handed: the
/// bytes into [bytes] and the file names into [names].
PdfAction recordingPdfAction({List<Uint8List>? bytes, List<String>? names}) =>
    PdfAction(
      label: testPdfActionLabel,
      icon: LucideIcons.download,
      run: (pdf, fileName) async {
        bytes?.add(pdf);
        names?.add(fileName);
      },
    );
