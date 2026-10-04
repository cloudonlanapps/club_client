import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/src/widgets/identity_documents_submit_body.dart';
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

IdentityDocumentSlot _slot(String id) {
  return IdentityDocumentSlot(
    id: id,
    uri: 'https://example.test/media/$id/download',
    mimeType: 'image/jpeg',
    sizeBytes: 0,
    fileName: '$id.jpg',
  );
}

void main() {
  group('Issue 490: IdentityDocumentsSubmitBody', () {
    testWidgets('mounts the form and exposes submit / do-later / discard', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageAuthHeadersProvider.overrideWith(
              (ref) async => const <String, String>{},
            ),
          ],
          child: ShadApp(
            home: Scaffold(
              body: IdentityDocumentsSubmitBody(
                currentUser: _user(),
                initialItems: [_slot('a'), _slot('b')],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // (a) the form is present.
      expect(find.byType(IdentityDocumentsForm), findsOneWidget);
      // (b) submit and do-later affordances render.
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text("I'll do it later"), findsOneWidget);
      // (b) one discard affordance per uploaded slot (maxCount is 2, so the
      // two slots fill the form and no add tile is shown).
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });
  });
}
