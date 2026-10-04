import 'package:cl_member_onboarding/src/views/onboarding_welcome_view.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({
  required UserStatus status,
  String? adminReviewNote,
}) {
  return UserPrivate(
    username: 'u1',
    displayName: 'U One',
    status: status,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
    adminReviewNote: adminReviewNote,
    firstName: 'Una',
    lastName: 'One',
    email: 'u1@example.com',
    phone: '+10000000000',
    dateOfBirthUtc: DateTime.utc(2000),
    gender: Gender.female,
  );
}

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  group('Issue 379: OnboardingWelcomeView variants', () {
    testWidgets('renders intro card when registered with no note', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingWelcomeView(
            currentUser: _user(status: UserStatus.registered),
            onContinue: () {},
            onSubmitForReview: () {},
            identityVerification: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome aboard - almost!'), findsOneWidget);
      expect(find.widgetWithText(ShadButton, 'Continue'), findsOneWidget);
    });

    testWidgets('renders SubmittedConfirmation when status is pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingWelcomeView(
            currentUser: _user(status: UserStatus.pending),
            onContinue: () {},
            onSubmitForReview: () {},
            identityVerification: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thanks for signing up!'), findsOneWidget);
      expect(
        find.widgetWithText(ShadButton, 'Back to sign in'),
        findsOneWidget,
      );
    });

    testWidgets(
      'reapply variant renders banner and reapply CTA when note is set',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _wrap(
            OnboardingWelcomeView(
              currentUser: _user(
                status: UserStatus.registered,
                adminReviewNote: 'Please correct your phone number.',
              ),
              onContinue: () {},
              onSubmitForReview: () {},
              identityVerification: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Update your registration'), findsOneWidget);
        expect(find.text('Please correct your phone number.'), findsOneWidget);
        // Username pinned, not editable.
        expect(
          find.widgetWithText(ShadButton, 'Submit changes'),
          findsOneWidget,
        );
      },
    );

    testWidgets('intro card Continue button calls onContinue', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          OnboardingWelcomeView(
            currentUser: _user(status: UserStatus.registered),
            onContinue: () => calls++,
            onSubmitForReview: () {},
            identityVerification: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ShadButton, 'Continue'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('Issue 494: asserts when called with an out-of-gate status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          OnboardingWelcomeView(
            currentUser: _user(status: UserStatus.active),
            onContinue: () {},
            onSubmitForReview: () {},
            identityVerification: true,
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });

  group('Issue 84: identity verification follows the server', () {
    Future<(List<String>,)> pumpIntro(
      WidgetTester tester, {
      required bool identityVerification,
    }) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _wrap(
          OnboardingWelcomeView(
            currentUser: _user(status: UserStatus.registered),
            onContinue: () => calls.add('continue'),
            onSubmitForReview: () => calls.add('submit'),
            identityVerification: identityVerification,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (calls,);
    }

    testWidgets('on: the intro asks for an identity document and continues '
        'to the document step', (tester) async {
      final (calls,) = await pumpIntro(tester, identityVerification: true);

      expect(find.textContaining('identity document'), findsOneWidget);
      await tester.tap(find.widgetWithText(ShadButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(calls, ['continue']);
    });

    testWidgets('off: the intro asks for no document and submits for review '
        'directly', (tester) async {
      final (calls,) = await pumpIntro(tester, identityVerification: false);

      expect(find.textContaining('document'), findsNothing);
      await tester.tap(find.widgetWithText(ShadButton, 'Submit for review'));
      await tester.pumpAndSettle();
      expect(calls, ['submit']);
    });

    for (final on in [true, false]) {
      testWidgets('pending confirmation names no document '
          '(verification ${on ? 'on' : 'off'})', (tester) async {
        await tester.pumpWidget(
          _wrap(
            OnboardingWelcomeView(
              currentUser: _user(status: UserStatus.pending),
              onContinue: () {},
              onSubmitForReview: () {},
              identityVerification: on,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thanks for signing up!'), findsOneWidget);
        expect(find.textContaining('Aadhaar'), findsNothing);
        expect(
          find.textContaining('reviewing your application'),
          findsOneWidget,
        );
      });
    }
  });
}
