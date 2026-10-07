import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/markdown/markdown_composer_field.dart'
    show MarkdownComposerField;
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  // Toggling a ShadCheckbox by tapping is hit-test fragile (the tap lands on
  // the label, missing the box). Invoke onChanged directly, as the identity
  // documents form test does.
  void setCheckbox(WidgetTester tester, Finder finder, {required bool value}) {
    tester.widget<ShadCheckbox>(finder).onChanged?.call(value);
  }

  Future<void> pump(
    WidgetTester tester, {
    required Future<bool> Function(BroadcastComposeResult) onSend,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        BroadcastComposer(
          placeholder: 'Type a message…',
          onSend: onSend,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Issue 740: the message box is a markdown field with a preview toggle',
    (tester) async {
      await pump(tester, onSend: (_) async => true);

      expect(find.byType(MarkdownComposerField), findsOneWidget);

      // Type a message, switch to preview, confirm it renders as markdown.
      await tester.enterText(find.byType(EditableText), 'Say **hi**');
      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pumpAndSettle();
      expect(find.byType(ThemedMarkdown), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 737: subject field is revealed only when both email checkboxes '
    'are on',
    (tester) async {
      await pump(tester, onSend: (_) async => true);

      // Default: only "Send email" is visible; no subject affordances.
      expect(find.text('Send email'), findsOneWidget);
      expect(find.text('Customize email subject'), findsNothing);
      expect(find.text('Subject'), findsNothing);

      // Enable email → the customize-subject checkbox appears.
      setCheckbox(tester, find.byType(ShadCheckbox), value: true);
      await tester.pumpAndSettle();
      expect(find.text('Customize email subject'), findsOneWidget);
      expect(find.text('Subject'), findsNothing);

      // Enable customize (now the second checkbox) → the subject input appears.
      setCheckbox(tester, find.byType(ShadCheckbox).last, value: true);
      await tester.pumpAndSettle();
      expect(find.text('Subject'), findsOneWidget);
    },
  );

  testWidgets('Issue 737: Send is blocked until the message is non-empty', (
    tester,
  ) async {
    BroadcastComposeResult? sent;
    await pump(
      tester,
      onSend: (r) async {
        sent = r;
        return true;
      },
    );

    // Empty message — tapping Send does nothing.
    await tester.tap(find.widgetWithText(ShadButton, 'Send'));
    await tester.pumpAndSettle();
    expect(sent, isNull);

    // With a message, Send fires with email off and no subject.
    await tester.enterText(find.byType(EditableText), '  hello team  ');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ShadButton, 'Send'));
    await tester.pumpAndSettle();
    expect(sent, isNotNull);
    expect(sent!.text, 'hello team');
    expect(sent!.sendEmail, isFalse);
    expect(sent!.emailSubject, isNull);
  });

  testWidgets(
    'Issue 737: customizing the subject blocks Send until a subject is typed',
    (tester) async {
      BroadcastComposeResult? sent;
      await pump(
        tester,
        onSend: (r) async {
          sent = r;
          return true;
        },
      );

      // Type the message, then turn on email + customize subject.
      await tester.enterText(find.byType(EditableText), 'practice moved');
      await tester.pumpAndSettle();
      setCheckbox(tester, find.byType(ShadCheckbox), value: true);
      await tester.pumpAndSettle();
      setCheckbox(tester, find.byType(ShadCheckbox).last, value: true);
      await tester.pumpAndSettle();

      // Subject empty — Send is blocked.
      await tester.tap(find.widgetWithText(ShadButton, 'Send'));
      await tester.pumpAndSettle();
      expect(sent, isNull);

      // Fill the subject (first input, above the message) → Send fires.
      await tester.enterText(find.byType(EditableText).first, 'U12 update');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, 'Send'));
      await tester.pumpAndSettle();
      expect(sent, isNotNull);
      expect(sent!.sendEmail, isTrue);
      expect(sent!.emailSubject, 'U12 update');
      expect(sent!.text, 'practice moved');
    },
  );
}
