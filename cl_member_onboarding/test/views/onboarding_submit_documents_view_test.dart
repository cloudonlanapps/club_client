import 'package:cl_member_onboarding/src/providers/my_identity_doc_slots.dart';
import 'package:cl_member_onboarding/src/views/onboarding_submit_documents_view.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

UserPrivate _user() {
  return UserPrivate(
    username: 'u1',
    displayName: 'U One',
    status: UserStatus.registered,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
    email: 'u1@example.com',
  );
}

void main() {
  group('Issue 490: OnboardingSubmitDocumentsView error branch', () {
    testWidgets('renders ErrorView with a retry action when slots fail', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clMyIdentityDocSlotsProvider.overrideWith(
              (ref) => AsyncValue<List<IdentityDocumentSlot>>.error(
                Exception('boom'),
                StackTrace.empty,
              ),
            ),
          ],
          child: ShadApp(
            home: Scaffold(
              body: OnboardingSubmitDocumentsView(
                currentUser: _user(),
                onHome: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Could not load your documents'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
