import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/image_upload/image_upload_affordance.dart';

void main() {
  testWidgets(
    'Issue 693: a second tap while onReplace is in flight is ignored',
    (tester) async {
      var replaceCalls = 0;
      final gate = Completer<void>();
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Center(
              child: ImageUploadAffordance(
                onReplace: () {
                  replaceCalls++;
                  return gate.future;
                },
              ),
            ),
          ),
        ),
      );

      // First tap starts the (still-pending) replace flow.
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();
      expect(replaceCalls, 1);

      // Second tap while the flow is in flight must be a no-op.
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();
      expect(replaceCalls, 1);

      // Releasing the flow leaves the guard reset for a future tap.
      gate.complete();
      await tester.pumpAndSettle();
      expect(replaceCalls, 1);

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();
      expect(replaceCalls, 2);
    },
  );

  testWidgets(
    'Issue 693: trash button is hidden when onRemove is null',
    (tester) async {
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Center(
              child: ImageUploadAffordance(onReplace: () async {}),
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
    },
  );

  testWidgets(
    'Issue 693: trash button shows and fires when onRemove is supplied',
    (tester) async {
      var removeCalls = 0;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Center(
              child: ImageUploadAffordance(
                onReplace: () async {},
                onRemove: () async => removeCalls++,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pump();
      expect(removeCalls, 1);
    },
  );

  testWidgets(
    'Issue 693: spinner shows only while uploading, not at rest',
    (tester) async {
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Center(
              child: ImageUploadAffordance(onReplace: () async {}),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Center(
              child: ImageUploadAffordance(
                uploading: true,
                onReplace: () async {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
