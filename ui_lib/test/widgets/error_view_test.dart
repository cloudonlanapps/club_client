import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/error_view.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  group('ErrorView', () {
    testWidgets('Issue 250: renders title only with Home action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'Something went wrong',
            onHome: () {},
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Show error code'), findsNothing);
    });

    testWidgets('Issue 250: renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'Access Denied',
            subtitle: 'You do not have permission to view this page.',
            onHome: () {},
          ),
        ),
      );

      expect(find.text('Access Denied'), findsOneWidget);
      expect(
        find.text('You do not have permission to view this page.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 250: errorCode toggle reveals raw error block', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'Could not load event',
            errorCode: 'SocketException: Connection refused (port 8155)',
            onHome: () {},
          ),
        ),
      );

      // Toggle present, raw error hidden initially.
      expect(find.text('Show error code'), findsOneWidget);
      expect(
        find.text('SocketException: Connection refused (port 8155)'),
        findsNothing,
      );

      // Tap toggle — raw error appears and label flips.
      await tester.tap(find.text('Show error code'));
      await tester.pumpAndSettle();

      expect(find.text('Hide error code'), findsOneWidget);
      expect(
        find.text('SocketException: Connection refused (port 8155)'),
        findsOneWidget,
      );

      // Tap again — collapses.
      await tester.tap(find.text('Hide error code'));
      await tester.pumpAndSettle();
      expect(
        find.text('SocketException: Connection refused (port 8155)'),
        findsNothing,
      );
    });

    testWidgets('Issue 250: action row shows only Home by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'Error',
            onHome: () {},
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets(
      'Issue 250: action row shows Home + Back when onBack provided',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ErrorView(
              title: 'Error',
              onHome: () {},
              onBack: () {},
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      },
    );

    testWidgets(
      'Issue 250: action row shows Home + Retry when onRetry provided',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ErrorView(
              title: 'Error',
              onHome: () {},
              onRetry: () {},
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Back'), findsNothing);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 250: action row shows Home + Back + Retry when both provided',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ErrorView(
              title: 'Error',
              onHome: () {},
              onBack: () {},
              onRetry: () {},
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets('Issue 250: invokes onHome / onBack / onRetry callbacks', (
      tester,
    ) async {
      var home = 0;
      var back = 0;
      var retry = 0;
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'Error',
            onHome: () => home++,
            onBack: () => back++,
            onRetry: () => retry++,
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.tap(find.text('Back'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(home, 1);
      expect(back, 1);
      expect(retry, 1);
    });

    testWidgets('Issue 250: destructive tone uses destructive color; '
        'neutral uses mutedForeground', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'Boom',
            tone: ErrorTone.destructive,
            onHome: () {},
          ),
        ),
      );
      final destructiveIcon = tester.widget<Icon>(find.byType(Icon).first);

      await tester.pumpWidget(
        _wrap(
          ErrorView(
            title: 'No access',
            tone: ErrorTone.neutral,
            onHome: () {},
          ),
        ),
      );
      final neutralIcon = tester.widget<Icon>(find.byType(Icon).first);

      expect(destructiveIcon.color, isNot(equals(neutralIcon.color)));
    });
  });
}
