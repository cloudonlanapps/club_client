import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

final _first = DateTime.utc(2030, 6, 15, 6);
final _second = DateTime.utc(2030, 6, 16, 6);

final _sessions = [
  EventCancellationSession(start: _first, label: 'Sat 15 Jun, 06:00'),
  EventCancellationSession(start: _second, label: 'Sun 16 Jun, 06:00'),
];

Future<GlobalKey<EventCancellationFormState>> _pump(
  WidgetTester tester, {
  List<EventCancellationSession> sessions = const [],
}) async {
  final key = GlobalKey<EventCancellationFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: EventCancellationForm(key: key, sessions: sessions),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Future<void> _typeReason(WidgetTester tester, String reason) async {
  await tester.enterText(find.byType(EditableText), reason);
  await tester.pump();
}

void main() {
  group('Issue 40: EventCancellationFormValidators', () {
    test('Issue 40: a reason is required', () {
      expect(
        EventCancellationFormValidators.reason('   '),
        EventCancellationFormValidators.reasonRequired,
      );
      expect(EventCancellationFormValidators.reason('Rink closed'), isNull);
    });

    test('Issue 40: a reason longer than the server accepts is refused', () {
      const limit = EventCancellationFormFields.reasonMaxLength;
      expect(EventCancellationFormValidators.reason('a' * limit), isNull);
      expect(
        EventCancellationFormValidators.reason('a' * (limit + 1)),
        EventCancellationFormValidators.reasonTooLong,
      );
    });

    test('Issue 40: a session is required', () {
      expect(
        EventCancellationFormValidators.fromSession(null),
        EventCancellationFormValidators.fromSessionRequired,
      );
      expect(EventCancellationFormValidators.fromSession(_first), isNull);
    });
  });

  group('Issue 40: EventCancellationForm', () {
    testWidgets('Issue 40: without a reason it does not validate', (
      tester,
    ) async {
      final key = await _pump(tester);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.text(EventCancellationFormValidators.reasonRequired),
        findsOneWidget,
      );
    });

    testWidgets('Issue 40: a one-off has a reason and no session to choose', (
      tester,
    ) async {
      final key = await _pump(tester);
      expect(find.text('Cancel from *'), findsNothing);

      await _typeReason(tester, '  Rink closed  ');

      expect(key.currentState!.validate(), {
        EventCancellationFormFields.fromSessionId: null,
        EventCancellationFormFields.reasonId: 'Rink closed',
      });
    });

    testWidgets('Issue 40: a camp starts from the next session by default', (
      tester,
    ) async {
      final key = await _pump(tester, sessions: _sessions);
      expect(find.text('Cancel from *'), findsOneWidget);
      expect(find.text('Sat 15 Jun, 06:00'), findsOneWidget);

      await _typeReason(tester, 'Rink closed');

      expect(key.currentState!.validate(), {
        EventCancellationFormFields.fromSessionId: _first,
        EventCancellationFormFields.reasonId: 'Rink closed',
      });
    });

    testWidgets('Issue 40: a later session can be chosen', (tester) async {
      final key = await _pump(tester, sessions: _sessions);
      await _typeReason(tester, 'Rink closed');

      await tester.tap(find.text('Sat 15 Jun, 06:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sun 16 Jun, 06:00').last);
      await tester.pumpAndSettle();

      expect(
        key.currentState!
            .validate()![EventCancellationFormFields.fromSessionId],
        _second,
      );
    });
  });
}
