import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _form({bool? identityDocumentsRequired}) => ShadApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: SignupForm(
        username: null,
        initialValues: null,
        identityDocumentsRequired: identityDocumentsRequired,
        onCheckUsernameAvailable: (_) async => true,
        onSubmit:
            ({
              required email,
              required phone,
              required dateOfBirthUtc,
              required gender,
              username,
              password,
              firstName,
              middleName,
              lastName,
            }) async => const SignupSubmitResult(),
        onSubmitSuccess: () {},
      ),
    ),
  ),
);

void main() {
  group('Issue 84: SignupForm intro follows identity verification', () {
    testWidgets('on: says identity documents will be asked for', (
      tester,
    ) async {
      await tester.pumpWidget(_form(identityDocumentsRequired: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('identity documents'), findsOneWidget);
    });

    for (final state in [false, null]) {
      testWidgets('${state == null ? 'unknown' : 'off'}: names no document', (
        tester,
      ) async {
        await tester.pumpWidget(_form(identityDocumentsRequired: state));
        await tester.pumpAndSettle();

        expect(find.textContaining('document'), findsNothing);
        expect(
          find.textContaining('An admin will review your application'),
          findsOneWidget,
        );
      });
    }
  });
}
