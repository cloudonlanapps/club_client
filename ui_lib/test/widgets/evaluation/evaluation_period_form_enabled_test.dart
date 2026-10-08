import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/models/evaluation_start_options.dart'
    show EvaluationStartEvent;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

/// Whether the event select of the one period form on screen is on.
bool _selectOn(WidgetTester tester) => tester
    .widget<ShadSelectFormField<EvaluationStartEvent>>(
      find.byType(ShadSelectFormField<EvaluationStartEvent>),
    )
    .enabled;

/// Whether each date field of the one period form on screen is on.
List<bool> _datesOn(WidgetTester tester) => [
  for (final field in tester.widgetList<CLDatePickerFormField>(
    find.byType(CLDatePickerFormField),
  ))
    field.enabled,
];

void main() {
  group('Issue 91: EvaluationPeriodForm can be turned off', () {
    testWidgets('Issue 91: the event select and both dates are on by '
        'default', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(wrapEvaluation(const EvaluationPeriodForm()));
      await tester.pumpAndSettle();

      expect(_selectOn(tester), isTrue);
      expect(_datesOn(tester), [true, true]);
    });

    testWidgets('Issue 91: turned off, the event select and both dates are '
        'off', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        wrapEvaluation(const EvaluationPeriodForm(enabled: false)),
      );
      await tester.pumpAndSettle();

      expect(_selectOn(tester), isFalse);
      expect(_datesOn(tester), [false, false]);
    });
  });
}
