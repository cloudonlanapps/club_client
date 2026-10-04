import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/confirm_dialog.dart';

void main() {
  testWidgets('renders title and message', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: ConfirmDialog(
          title: 'Delete Data',
          message: 'Are you sure?',
          confirmLabel: 'Delete',
          onConfirm: () {},
        ),
      ),
    );
    expect(find.text('Delete Data'), findsOneWidget);
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('calls onConfirm when confirm clicked', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      ShadApp(
        home: ConfirmDialog(
          title: 'T',
          message: 'M',
          confirmLabel: 'Confirm',
          onConfirm: () => confirmed = true,
        ),
      ),
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(confirmed, true);
  });

  testWidgets('destructive flag uses destructive button', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: ConfirmDialog(
          title: 'T',
          message: 'M',
          confirmLabel: 'Confirm',
          destructive: true,
          onConfirm: () {},
        ),
      ),
    );
    expect(find.text('Confirm'), findsOneWidget);
  });
}
