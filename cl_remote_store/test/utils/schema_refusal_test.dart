import 'package:cl_club_forms/cl_club_forms.dart' show AgeEligibilityFormFields;
import 'package:cl_remote_store/src/utils/age_schema_fields.dart';
import 'package:cl_remote_store/src/utils/schema_refusal.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// A schema rejection as the SDK builds it from the server's 422 list.
ServerException _rejection(List<Map<String, Object?>> fields) =>
    ServerException(
      statusCode: 422,
      code: SdkErrorCode.validationError,
      message: fields.map((f) => f['msg']).join('; '),
      details: {ServerException.refusedFieldsKey: fields},
    );

void main() {
  group('Issue 114: the refused fields of a schema rejection', () {
    test('Issue 114: each refused field is read with its path, without the '
        'part of the request it came in, and its reason', () {
      final refused = schemaRefusedFields(
        _rejection([
          {
            'loc': ['body', 'email'],
            'msg': 'value is not a valid email address',
            'type': 'value_error',
          },
          {
            'loc': ['body', 'address', 'pincode'],
            'msg': 'String should have at most 10 characters',
            'type': 'string_too_long',
          },
        ]),
      );

      expect(refused.map((f) => f.path), ['email', 'address.pincode']);
      expect(refused.first.message, 'Value is not a valid email address');
    });

    test('Issue 114: a list index is part of the path', () {
      final refused = schemaRefusedFields(
        _rejection([
          {
            'loc': ['body', 'sessions', 1, 'startMinute'],
            'msg': 'Input should be greater than or equal to 0',
            'type': 'greater_than_equal',
          },
        ]),
      );

      expect(refused.single.path, 'sessions.1.startMinute');
    });

    test("Issue 114: the validator's own prefix is left out of the reason", () {
      final refused = schemaRefusedFields(
        _rejection([
          {
            'loc': ['body', 'phone'],
            'msg': 'Value error, phone must hold 7 to 15 digits',
            'type': 'value_error',
          },
        ]),
      );

      expect(refused.single.message, 'Phone must hold 7 to 15 digits');
    });

    test('Issue 114: a refusal with no reason reads as a fixed message', () {
      final refused = schemaRefusedFields(
        _rejection([
          {
            'loc': ['body', 'phone'],
            'msg': null,
            'type': 'value_error',
          },
        ]),
      );

      expect(refused.single.message, schemaRefusalFallbackMessage);
    });

    test('Issue 114: a refusal of the request as a whole names no field', () {
      final refused = schemaRefusedFields(
        _rejection([
          {
            'loc': ['body'],
            'msg': 'Value error, give a first or a last name',
            'type': 'value_error',
          },
        ]),
      );

      expect(refused, isEmpty);
    });

    test('Issue 114: any other error names no field', () {
      expect(
        schemaRefusedFields(
          const ServerException(
            statusCode: 422,
            code: SdkErrorCode.cutoffTooSoon,
            message: 'too soon',
            details: {
              ServerException.refusedFieldsKey: [
                {
                  'loc': ['body', 'cutoffTimeUtc'],
                  'msg': 'x',
                },
              ],
            },
          ),
        ),
        isEmpty,
      );
      expect(
        schemaRefusedFields(
          const ServerException(
            statusCode: 422,
            code: SdkErrorCode.validationError,
            message: 'joined reasons',
          ),
        ),
        isEmpty,
        reason: 'a rejection that kept no field names',
      );
      expect(schemaRefusedFields(Exception('offline')), isEmpty);
    });
  });

  group('Issue 114: a schema rejection on the fields of a form', () {
    const fieldIds = {
      'email': 'email_id',
      'address.pincode': 'pincode_id',
      'sessions': 'timetable_id',
    };

    test('Issue 114: a refused field the form holds takes its reason', () {
      final errors = schemaFieldErrors(
        _rejection([
          {
            'loc': ['body', 'email'],
            'msg': 'value is not a valid email address',
          },
          {
            'loc': ['body', 'address', 'pincode'],
            'msg': 'String should have at most 10 characters',
          },
        ]),
        fieldIds,
      );

      expect(errors, {
        'email_id': 'Value is not a valid email address',
        'pincode_id': 'String should have at most 10 characters',
      });
    });

    test('Issue 114: a field inside one the form holds as a whole shows on '
        'that one', () {
      final errors = schemaFieldErrors(
        _rejection([
          {
            'loc': ['body', 'sessions', 1, 'startMinute'],
            'msg': 'Input should be greater than or equal to 0',
          },
        ]),
        fieldIds,
      );

      expect(errors.keys, ['timetable_id']);
    });

    test('Issue 114: the first reason stays on a field refused twice', () {
      final errors = schemaFieldErrors(
        _rejection([
          {
            'loc': ['body', 'sessions', 0, 'startMinute'],
            'msg': 'first',
          },
          {
            'loc': ['body', 'sessions', 1, 'startMinute'],
            'msg': 'second',
          },
        ]),
        fieldIds,
      );

      expect(errors, {'timetable_id': 'First'});
    });

    test('Issue 114: a field the form does not hold is left out', () {
      final errors = schemaFieldErrors(
        _rejection([
          {
            'loc': ['body', 'version'],
            'msg': 'Field required',
          },
          {
            'loc': ['body', 'address'],
            'msg': 'Input should be an object',
          },
        ]),
        fieldIds,
      );

      expect(errors, isEmpty);
    });

    test('Issue 114: any other error gives no field message', () {
      expect(
        schemaFieldErrors(
          const ServerException(
            statusCode: 409,
            code: SdkErrorCode.conflict,
            message: 'taken',
          ),
          fieldIds,
        ),
        isEmpty,
      );
    });
  });

  test('Issue 114: a refused age shows on the part of the bound it names, '
      'and a bound refused as a whole on its years', () {
    expect(
      schemaFieldErrors(
        _rejection([
          {
            'loc': ['body', 'minAge', 'months'],
            'msg': 'Input should be less than or equal to 11',
          },
          {
            'loc': ['body', 'maxAge'],
            'msg': 'Input should be an object',
          },
          {
            'loc': ['body', 'strictAge'],
            'msg': 'Input should be a valid boolean',
          },
        ]),
        ageSchemaFieldIds,
      ).keys,
      {
        AgeEligibilityFormFields.minAgeMonthsId,
        AgeEligibilityFormFields.maxAgeYearsId,
        AgeEligibilityFormFields.strictAgeId,
      },
    );
  });
}
