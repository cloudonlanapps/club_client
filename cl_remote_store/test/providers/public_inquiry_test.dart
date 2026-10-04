import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_public_source.dart';

void main() {
  group('Issue 53: the public inquiry form', () {
    test('Issue 53: fetches the fill-time token', () async {
      final source = FakePublicSource()..token = 'tok';
      final container = publicContainer(source);

      final token = await container
          .read(clPublicInquiryProvider.notifier)
          .formToken();

      expect(token, 'tok');
    });

    test('Issue 53: submits the inquiry as given', () async {
      final source = FakePublicSource();
      final container = publicContainer(source);

      await container
          .read(clPublicInquiryProvider.notifier)
          .submit(
            kind: InquiryKind.interest,
            name: 'Ann',
            email: 'ann@example.com',
            message: '',
            token: 'tok',
            phone: '123',
            extra: const {'age': 'u12'},
          );

      expect(source.inquiries.single, {
        'kind': InquiryKind.interest,
        'name': 'Ann',
        'email': 'ann@example.com',
        'message': '',
        'token': 'tok',
        'phone': '123',
        'extra': {'age': 'u12'},
        'website': null,
      });
    });

    test('Issue 53: a refused submission is rethrown to the form', () async {
      final source = FakePublicSource()
        ..failWith = const ServerException(
          statusCode: 429,
          code: 'RATE_LIMITED',
          message: 'slow down',
        );
      final container = publicContainer(source);

      await expectLater(
        container
            .read(clPublicInquiryProvider.notifier)
            .submit(
              kind: InquiryKind.contact,
              name: 'Ann',
              email: 'ann@example.com',
              message: 'Hi',
              token: 'tok',
            ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
