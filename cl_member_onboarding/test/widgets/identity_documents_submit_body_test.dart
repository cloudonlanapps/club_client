import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/src/models/identity_documents_submit_strings.dart';
import 'package:cl_member_onboarding/src/models/onboarding_write_messages.dart';
import 'package:cl_member_onboarding/src/widgets/identity_documents_privacy_policy_dialog.dart';
import 'package:cl_member_onboarding/src/widgets/identity_documents_submit_body.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

const _consentRequired = 'Please agree to the Privacy Policy to continue.';

UserPrivate _user({UserStatus status = UserStatus.registered}) {
  return UserPrivate(
    username: 'u1',
    displayName: 'U One',
    status: status,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
    email: 'u1@example.com',
  );
}

IdentityDocumentSlot _slot(String id) {
  return IdentityDocumentSlot(
    id: id,
    uri: 'https://example.test/media/$id/download',
    mimeType: 'image/jpeg',
    sizeBytes: 0,
    fileName: '$id.jpg',
  );
}

/// Counts the submissions in place of the server.
class _FakeUsers extends ClUsersMasterNotifier {
  _FakeUsers({this.failure});

  /// What a submission fails with; null lets it through.
  final Exception? failure;

  int submissions = 0;

  @override
  Future<Map<String, UserInfo>> build() async => const {};

  @override
  Future<UserPrivate> submitForReviewForSelf() async {
    submissions++;
    final failure = this.failure;
    if (failure != null) throw failure;
    return _user(status: UserStatus.pending);
  }
}

/// A signed-in member, with no token storage behind it.
class _FakeAuth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _user();
}

Future<_FakeUsers> _pump(
  WidgetTester tester, {
  required List<IdentityDocumentSlot> items,
  Exception? failure,
}) async {
  final users = _FakeUsers(failure: failure);
  await tester.binding.setSurfaceSize(const Size(1024, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        imageAuthHeadersProvider.overrideWith(
          (ref) async => const <String, String>{},
        ),
        clUsersMasterProvider.overrideWith(() => users),
        authStateProvider.overrideWith(_FakeAuth.new),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: IdentityDocumentsSubmitBody(
              currentUser: _user(),
              initialItems: items,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return users;
}

ShadButton _submitButton(WidgetTester tester) => tester.widget<ShadButton>(
  find.widgetWithText(ShadButton, IdentityDocumentsSubmitStrings.submit),
);

Future<void> _tickConsent(WidgetTester tester) async {
  tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).onChanged?.call(true);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 490: IdentityDocumentsSubmitBody', () {
    testWidgets('mounts the step and exposes submit / do-later / discard', (
      tester,
    ) async {
      await _pump(tester, items: [_slot('a'), _slot('b')]);

      // (a) the uploader and the consent form are present.
      expect(find.byType(IdentityDocumentsUploader), findsOneWidget);
      expect(find.byType(IdentityDocumentsConsentForm), findsOneWidget);
      // (b) submit and do-later affordances render.
      expect(find.text(IdentityDocumentsSubmitStrings.submit), findsOneWidget);
      expect(find.text(IdentityDocumentsSubmitStrings.doLater), findsOneWidget);
      // (b) one discard affordance per uploaded slot (maxCount is 2, so the
      // two slots fill the uploader and no add tile is shown).
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });
  });

  group('Issue 51: the submit-documents step', () {
    testWidgets('Issue 51: the intro and the collapsed tips belong to it', (
      tester,
    ) async {
      await _pump(tester, items: [_slot('a')]);
      expect(find.text(IdentityDocumentsSubmitStrings.intro), findsOneWidget);
      expect(
        find.text(IdentityDocumentsSubmitStrings.tipsTitle),
        findsOneWidget,
      );
      expect(
        find.text(IdentityDocumentsSubmitStrings.tips.first),
        findsNothing,
      );
    });

    testWidgets('Issue 51: with no document Submit is disabled, and says why', (
      tester,
    ) async {
      final users = await _pump(tester, items: const []);
      await _tickConsent(tester);

      expect(_submitButton(tester).onPressed, isNull);
      expect(
        find.text(IdentityDocumentsSubmitStrings.needsDocument),
        findsOneWidget,
      );
      expect(users.submissions, 0);
    });

    testWidgets('Issue 51: Submit without consent asks for it and sends '
        'nothing', (tester) async {
      final users = await _pump(tester, items: [_slot('a')]);

      expect(
        find.text(IdentityDocumentsSubmitStrings.needsDocument),
        findsNothing,
      );
      expect(_submitButton(tester).onPressed, isNotNull);
      _submitButton(tester).onPressed!();
      await tester.pumpAndSettle();

      expect(find.text(_consentRequired), findsOneWidget);
      expect(users.submissions, 0);
    });

    testWidgets('Issue 51: with a document and consent, Submit sends the '
        'application for review', (tester) async {
      final users = await _pump(tester, items: [_slot('a')]);
      await _tickConsent(tester);

      _submitButton(tester).onPressed!();
      await tester.pumpAndSettle();

      expect(find.text(_consentRequired), findsNothing);
      expect(users.submissions, 1);
    });
  });

  group('Issue 107: the privacy policy of the submit-documents step', () {
    /// Opens the policy as a tap on the link of the consent line does.
    Future<void> openPolicy(WidgetTester tester) async {
      tester
          .widget<IdentityDocumentsConsentForm>(
            find.byType(IdentityDocumentsConsentForm),
          )
          .onShowPolicy();
      await tester.pumpAndSettle();
    }

    testWidgets('Issue 107: a tap on the Privacy Policy link opens the '
        'policy, which says what the documents are used for', (tester) async {
      await _pump(tester, items: [_slot('a')]);
      expect(find.byType(IdentityDocumentsPrivacyPolicyDialog), findsNothing);

      final line = tester.getRect(
        find.text('I agree to the Privacy Policy.', findRichText: true),
      );
      await tester.tapAt(line.centerLeft + Offset(line.width * 0.75, 0));
      await tester.pumpAndSettle();

      expect(find.byType(IdentityDocumentsPrivacyPolicyDialog), findsOneWidget);
      expect(find.text('How we handle your Aadhaar'), findsOneWidget);
      for (final part in [
        'We only use your Aadhaar to confirm your name and date of birth',
        'We will never use it for marketing',
        'Only authorised reviewers can see your files',
      ]) {
        expect(find.textContaining(part), findsOneWidget, reason: part);
      }
    });

    testWidgets('Issue 107: Close takes the policy away and leaves the '
        'consent as it was', (tester) async {
      final users = await _pump(tester, items: [_slot('a')]);
      await _tickConsent(tester);
      await openPolicy(tester);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(IdentityDocumentsPrivacyPolicyDialog), findsNothing);
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        isTrue,
      );
      expect(users.submissions, 0);
    });

    testWidgets('Issue 107: the policy fits a phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ShadApp(
          home: Scaffold(body: IdentityDocumentsPrivacyPolicyDialog()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('How we handle your Aadhaar'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ShadDialog)).width,
        lessThanOrEqualTo(390),
      );
    });
  });

  group('Issue 97: IdentityDocumentsSubmitBody shows a failed submission '
      'where it belongs', () {
    Future<void> submit(WidgetTester tester) async {
      await _tickConsent(tester);
      _submitButton(tester).onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('Issue 97: a submission the server refuses for want of a '
        'document says so inline in the consent form, with no toast', (
      tester,
    ) async {
      final users = await _pump(
        tester,
        items: [_slot('a')],
        failure: const ServerException(
          statusCode: 422,
          code: SdkErrorCode.identityDocumentRequired,
          message: 'raw failure text',
        ),
      );
      await submit(tester);

      expect(users.submissions, 1);
      expect(
        find.descendant(
          of: find.byType(IdentityDocumentsConsentForm),
          matching: find.text(IdentityDocumentsSubmitStrings.needsDocument),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('raw failure text'), findsNothing);
      expect(_submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('Issue 97: a submission that fails for another reason is a '
        'toast, and Submit is on again', (tester) async {
      await _pump(
        tester,
        items: [_slot('a')],
        failure: const ServerException(
          statusCode: 409,
          code: SdkErrorCode.invalidState,
          message: 'raw failure text',
        ),
      );
      await submit(tester);

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text(submissionFailedMessage), findsOneWidget);
      expect(find.textContaining('raw failure text'), findsNothing);
      expect(_submitButton(tester).onPressed, isNotNull);
    });
  });
}
