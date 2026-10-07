import 'package:cl_club_forms_example/data/form_demo_entries.dart';
import 'package:cl_club_forms_example/models/form_demo_entry.dart';
import 'package:cl_club_forms_example/widgets/club_forms_app.dart';
import 'package:cl_club_forms_example/widgets/forms_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A desktop window.
const Size kDesktop = Size(1280, 900);

/// A phone, portrait.
const Size kPhone = Size(390, 844);

/// The sizes every entry is mounted at, by name.
const Map<String, Size> kSurfaces = {'desktop': kDesktop, 'phone': kPhone};

/// The entry with [id].
FormDemoEntry entryWithId(String id) =>
    FormDemoEntries.all.firstWhere((entry) => entry.id == id);

/// Starts the demo on a window of [size].
Future<void> pumpDemo(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const ClubFormsApp());
  await tester.pumpAndSettle();
}

/// Starts the demo on a window of [size] and shows [entry].
Future<void> pumpEntry(
  WidgetTester tester,
  FormDemoEntry entry,
  Size size,
) async {
  await pumpDemo(tester, size);
  tester.state<FormsShellState>(find.byType(FormsShell)).select(entry);
  await tester.pumpAndSettle();
}
