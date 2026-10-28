import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_strings.dart';

/// The file name of [member]'s form of application [title]
/// (club_client#404): `<title> - <full name>.pdf`, or the username when
/// the member has no name, cleaned as [PdfAction.fileNameFor] cleans it.
String memberFormFileName(String title, UserPrivate member) {
  final fullName = [
    member.firstName,
    member.middleName,
    member.lastName,
  ].map((part) => part?.trim() ?? '').where((p) => p.isNotEmpty).join(' ');
  return PdfAction.fileNameFor(
    ApplicationViewStrings.memberFormFileTitle(
      title,
      fullName.isEmpty ? member.username : fullName,
    ),
  );
}
