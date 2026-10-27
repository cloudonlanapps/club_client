import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationLibraryText;
import 'package:flutter/widgets.dart';

import '../../constants/application_library_strings.dart';
import '../../constants/application_view_strings.dart';
import '../sections/application_section_read.dart';

/// A library text's read mode (club_client#389): where it is used, then a
/// term's heading and the text in each language, as written.
class ApplicationLibraryTextRead extends StatelessWidget {
  const ApplicationLibraryTextRead({required this.text, super.key});

  /// The text.
  final ApplicationLibraryText text;

  @override
  Widget build(BuildContext context) => ApplicationSectionRead(
    lines: [
      (
        label: ApplicationLibraryStrings.usedFor,
        value: ApplicationLibraryStrings.kindName(text.kind),
      ),
      for (final MapEntry(key: code, value: heading)
          in (text.heading?.texts ?? const <String, String>{}).entries)
        (
          label: ApplicationLibraryStrings.heading(
            ApplicationViewStrings.languageName(code),
          ),
          value: heading,
        ),
      for (final MapEntry(key: code, :value) in text.text.texts.entries)
        (
          label: ApplicationLibraryStrings.text(
            ApplicationViewStrings.languageName(code),
          ),
          value: value,
        ),
    ],
  );
}
