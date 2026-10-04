import 'package:cl_club_members/src/views/group_profile_view.dart'
    show GroupHeroImage;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart' show groupImageProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap({required bool canEdit}) {
  return ProviderScope(
    overrides: [
      groupImageProvider(1).overrideWith((ref) async => null),
      imageAuthHeadersProvider.overrideWith((ref) async => const {}),
    ],
    child: ShadApp(
      home: Scaffold(
        body: GroupHeroImage(groupId: 1, canEdit: canEdit),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 695: hero shows the edit pencil for an admin (canEdit true)',
    (tester) async {
      await tester.pumpWidget(_wrap(canEdit: true));
      await tester.pumpAndSettle();

      // No image set → placeholder shown, and the editable pencil overlaid.
      expect(find.byIcon(LucideIcons.users), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      // Nothing to remove yet, so no trash button.
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
    },
  );

  testWidgets(
    'Issue 695: hero hides the affordance for a non-admin (canEdit false)',
    (tester) async {
      await tester.pumpWidget(_wrap(canEdit: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.users), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    },
  );
}
