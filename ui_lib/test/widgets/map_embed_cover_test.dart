import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/map_embed_cover.dart';

/// A page inside a nested navigator, as the app's pages sit inside a
/// shell's navigator; the root navigator holds the shell's page.
Widget _shellWith(GlobalKey probe) => ShadApp(
  home: Navigator(
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (_) => SizedBox(key: probe),
    ),
  ),
);

void main() {
  testWidgets(
    'Issue 147: a map in a shell page sits in the page and the shell page',
    (tester) async {
      final probe = GlobalKey();
      await tester.pumpWidget(_shellWith(probe));

      final routes = routesAround(probe.currentContext!);

      expect(routes, hasLength(2));
      expect(anyCovered(routes), isFalse);
    },
  );

  testWidgets(
    'Issue 147: a dialog on the root navigator covers a map in a shell page',
    (tester) async {
      final probe = GlobalKey();
      await tester.pumpWidget(_shellWith(probe));
      final routes = routesAround(probe.currentContext!);

      // showShadDialog's default: the root navigator. The page's own
      // navigator is untouched, so its page stays current there.
      unawaited(
        showShadDialog<void>(
          context: probe.currentContext!,
          builder: (_) => const ShadDialog(title: Text('Archive event')),
        ),
      );
      await tester.pumpAndSettle();

      expect(routes.first.isCurrent, isTrue);
      expect(anyCovered(routes), isTrue);

      Navigator.of(tester.element(find.text('Archive event'))).pop();
      await tester.pumpAndSettle();

      expect(anyCovered(routes), isFalse);
    },
  );

  testWidgets(
    'Issue 147: a dialog on the nested navigator covers a map in its page',
    (tester) async {
      final probe = GlobalKey();
      await tester.pumpWidget(_shellWith(probe));
      final routes = routesAround(probe.currentContext!);

      unawaited(
        showShadDialog<void>(
          context: probe.currentContext!,
          useRootNavigator: false,
          builder: (_) => const ShadDialog(title: Text('Rename event')),
        ),
      );
      await tester.pumpAndSettle();

      expect(routes.first.isCurrent, isFalse);
      expect(anyCovered(routes), isTrue);
    },
  );
}
