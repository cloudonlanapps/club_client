import 'package:cl_club_website/src/models/inquiry_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClPublicInquiryNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what one inquiry submission carried.
class _RecordingNotifier extends ClPublicInquiryNotifier {
  int calls = 0;
  String? phone;
  Map<String, dynamic>? extra;
  String? website;

  @override
  Future<void> submit({
    required InquiryKind kind,
    required String name,
    required String email,
    required String message,
    required String token,
    String? phone,
    Map<String, dynamic>? extra,
    String? website,
  }) async {
    calls += 1;
    this.phone = phone;
    this.extra = extra;
    this.website = website;
  }
}

Future<_RecordingNotifier> _submit(
  String typed,
  String code, {
  Map<String, String> answers = const {},
  String honeypot = '',
}) async {
  final notifier = _RecordingNotifier();
  await InquiryFormSubmit.create(
    notifier: notifier,
    defaultCountryCode: code,
    kind: InquiryKind.contact,
    name: 'Robin Example',
    email: 'robin@example.test',
    message: 'Hello',
    token: 'token',
    phone: typed,
    answers: answers,
    honeypot: honeypot,
  );
  expect(notifier.calls, 1);
  return notifier;
}

void main() {
  group('Issue 31: InquiryFormSubmit.create stores an international phone', () {
    for (final typed in ['98765 43210', '09876543210']) {
      for (final code in ['91', '44']) {
        test('Issue 31: "$typed" with country code $code', () async {
          expect((await _submit(typed, code)).phone, '+${code}9876543210');
        });
      }
    }

    test('Issue 31: + and 00 keep their own country code', () async {
      expect((await _submit('+44 98765 43210', '91')).phone, '+449876543210');
      expect((await _submit('0044 98765-43210', '91')).phone, '+449876543210');
    });

    test('Issue 31: no phone is sent as none', () async {
      expect((await _submit('', '91')).phone, isNull);
      expect((await _submit('   ', '91')).phone, isNull);
    });

    test('Issue 31: answers and the honeypot travel as before', () async {
      final empty = await _submit('', '91');
      expect(empty.extra, isNull);
      expect(empty.website, isNull);

      final filled = await _submit(
        '',
        '91',
        answers: {'ageGroup': 'adult'},
        honeypot: 'https://spam.example.test',
      );
      expect(filled.extra, {'ageGroup': 'adult'});
      expect(filled.website, 'https://spam.example.test');
    });
  });
}
