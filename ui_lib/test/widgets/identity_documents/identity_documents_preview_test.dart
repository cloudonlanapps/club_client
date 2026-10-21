import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/identity_documents/identity_document_slot.dart';
import 'package:ui_lib/src/widgets/identity_documents/identity_documents_preview.dart';

const slot = IdentityDocumentSlot(
  id: 'doc-1',
  uri: 'http://localhost/doc-1.png',
  mimeType: 'image/png',
  sizeBytes: 10,
  fileName: 'passport.png',
);

void main() {
  testWidgets(
    'Issue 246: the preview opened inside a nested navigator is pushed on '
    'the root navigator, and its close button returns to where it was opened',
    (tester) async {
      final nestedKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('shell chrome'),
                Expanded(
                  child: Navigator(
                    key: nestedKey,
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (context) => Center(
                        child: TextButton(
                          onPressed: () => showIdentityDocumentsPreview(
                            context: context,
                            items: const [slot],
                            initialItemId: 'doc-1',
                          ),
                          child: const Text('open'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final page = find.byType(IdentityDocumentsPreviewPage);
      expect(page, findsOneWidget);
      expect(
        find.descendant(of: find.byKey(nestedKey), matching: page),
        findsNothing,
        reason: 'the preview must not open inside the nested navigator',
      );
      final route = ModalRoute.of(tester.element(page))!;
      expect(route, isA<PageRoute<void>>());
      expect((route as PageRoute<void>).fullscreenDialog, isTrue);
      expect(
        Navigator.of(tester.element(page)),
        isNot(nestedKey.currentState),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(page, findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(find.text('shell chrome'), findsOneWidget);
    },
  );
}
