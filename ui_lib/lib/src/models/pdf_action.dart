import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

/// What a PDF the app holds in memory is handed to, as a button shows it
/// (club_client#324): share it, download it or open it, whichever works on
/// the platform. The app chooses it, since only the app knows the
/// platform; a package's button shows its [label] and [icon] and calls
/// [run] with the bytes it fetched.
@immutable
class PdfAction {
  /// An action shown as [label] with [icon] that does [run].
  const PdfAction({required this.label, required this.icon, required this.run});

  /// The button's text: what the action does (Share, Download).
  final String label;

  /// The button's icon.
  final IconData icon;

  /// Hands the PDF's bytes on, as a file of the given name. Completes when
  /// the platform has taken it; throws when it could not.
  final Future<void> Function(Uint8List bytes, String fileName) run;

  /// The extension of a PDF's file name.
  static const String extension = '.pdf';

  /// The file name of a PDF called [title] (an application's or a
  /// review's): [title] with the characters a file name may not hold
  /// replaced, and `.pdf` added; `document.pdf` for a blank [title].
  static String fileNameFor(String title) {
    final name = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
    final base = name.isEmpty ? 'document' : name;
    return base.toLowerCase().endsWith(extension) ? base : '$base$extension';
  }
}
