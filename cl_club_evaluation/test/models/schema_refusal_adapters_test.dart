import 'package:cl_club_evaluation/src/models/evaluation_period_form_submit.dart';
import 'package:cl_club_evaluation/src/models/evaluation_start_form_submit.dart';
import 'package:cl_club_evaluation/src/models/evaluation_template_form_submit.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart'
    show EvaluationStartFormFields, EvaluationTemplateCreateFormFields;

/// A schema rejection (422) naming [fields], each with the reason "refused".
ServerException _rejection(List<List<Object>> fields) => ServerException(
  statusCode: 422,
  code: SdkErrorCode.validationError,
  message: 'refused',
  details: {
    ServerException.refusedFieldsKey: [
      for (final loc in fields) {'loc': loc, 'msg': 'refused'},
    ],
  },
);

/// A rejection that names nothing an evaluation form holds.
final ServerException _aboutNothing = _rejection([
  ['body'],
  ['body', 'notAField'],
]);

void main() {
  group('Issue 114: a schema rejection shows on the evaluation field it '
      'names', () {
    test('Issue 114: the start form puts it on the template, the member, '
        'the event and the period', () {
      expect(
        EvaluationStartFormSubmit.fieldErrorsFor(
          _rejection([
            ['body', 'templateId'],
            ['body', 'createdFor'],
            ['body', 'eventId'],
            ['body', 'periodStartUtc'],
            ['body', 'periodEndUtc'],
          ]),
        ).keys,
        {
          EvaluationStartFormFields.templateId,
          EvaluationStartFormFields.memberId,
          EvaluationStartFormFields.eventId,
          EvaluationStartFormFields.periodStartId,
          EvaluationStartFormFields.periodEndId,
        },
      );
      expect(EvaluationStartFormSubmit.fieldErrorsFor(_aboutNothing), isEmpty);
    });

    test('Issue 114: the Review Period editor puts it on the event and the '
        'period', () {
      expect(
        EvaluationPeriodFormSubmit.fieldErrorsFor(
          _rejection([
            ['body', 'eventId'],
            ['body', 'periodStartUtc'],
            ['body', 'periodEndUtc'],
          ]),
        ),
        {
          EvaluationStartFormFields.eventId: 'Refused',
          EvaluationStartFormFields.periodStartId: 'Refused',
          EvaluationStartFormFields.periodEndId: 'Refused',
        },
      );
      expect(EvaluationPeriodFormSubmit.fieldErrorsFor(_aboutNothing), isEmpty);
    });

    test('Issue 114: template create puts it on the name and the layout', () {
      expect(
        EvaluationTemplateFormSubmit.createFieldErrors(
          _rejection([
            ['body', 'name'],
            ['body', 'layout', 0, 'item', 'text'],
          ]),
        ).keys,
        {
          EvaluationTemplateCreateFormFields.nameId,
          EvaluationTemplateCreateFormFields.layoutId,
        },
      );
      expect(
        EvaluationTemplateFormSubmit.createFieldErrors(_aboutNothing),
        isEmpty,
      );
    });

    test('Issue 114: template rename shows the reason on the name', () {
      expect(
        EvaluationTemplateFormSubmit.renameRefusal(
          _rejection([
            ['body', 'name'],
          ]),
          fallback: 'Could not rename.',
        ),
        'Refused',
      );
      expect(
        EvaluationTemplateFormSubmit.renameRefusal(
          _aboutNothing,
          fallback: 'Could not rename.',
        ),
        'Could not rename.',
      );
    });
  });
}
