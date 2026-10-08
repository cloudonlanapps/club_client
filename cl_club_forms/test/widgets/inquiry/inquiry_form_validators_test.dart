import 'package:cl_club_forms/src/widgets/inquiry/inquiry_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

const _required = 'required';
const _invalid = 'invalid';

String? _email(String value) => InquiryFormValidators.email(
  value,
  requiredMessage: _required,
  invalidMessage: _invalid,
);

void main() {
  test('Issue 84: the name is required', () {
    expect(
      InquiryFormValidators.name('', requiredMessage: _required),
      _required,
    );
    expect(
      InquiryFormValidators.name('   ', requiredMessage: _required),
      _required,
    );
    expect(
      InquiryFormValidators.name('Robin', requiredMessage: _required),
      isNull,
    );
  });

  test('Issue 84: the email is required and shaped like an address', () {
    expect(_email(''), _required);
    expect(_email('  '), _required);
    for (final malformed in ['robin', 'robin@', 'robin@example', 'a b@c.d']) {
      expect(_email(malformed), _invalid, reason: malformed);
    }
    expect(_email('robin@example.test'), isNull);
    expect(_email('  robin@example.test  '), isNull);
  });

  test('Issue 84: the phone is optional and taken as typed', () {
    for (final typed in ['', '98765 43210', '+44 98765 43210', 'call me']) {
      expect(InquiryFormValidators.phone(typed), isNull, reason: typed);
    }
  });

  test('Issue 84: the message is required only when the host says so', () {
    String? message(String value, {required bool required}) =>
        InquiryFormValidators.message(
          value,
          required: required,
          requiredMessage: _required,
        );

    expect(message('', required: true), _required);
    expect(message('  \n ', required: true), _required);
    expect(message('Hello', required: true), isNull);
    expect(message('', required: false), isNull);
  });
}
