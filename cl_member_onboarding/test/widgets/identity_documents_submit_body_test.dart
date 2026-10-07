import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/src/models/identity_documents_submit_strings.dart';
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
  int submissions = 0;

  @override
  Future<Map<String, UserInfo>> build() async => const {};

  @override
  Future<UserPrivate> submitForReviewForSelf() async {
    submissions++;
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
}) async {
  final users = _FakeUsers();
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
        home: Scaffold(
          body: IdentityDocumentsSubmitBody(
            currentUser: _user(),
            initialItems: items,
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
}
