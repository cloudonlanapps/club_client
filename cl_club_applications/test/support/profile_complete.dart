import 'package:cl_club_applications/src/widgets/profile_complete_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers "Is your profile complete?" with **Yes** (club_client#340) and
/// lets the download run.
Future<void> answerProfileComplete(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ProfileCompleteDialog.yesKey));
  await tester.pumpAndSettle();
}
