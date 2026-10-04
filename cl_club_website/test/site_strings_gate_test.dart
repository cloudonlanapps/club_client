import 'dart:async';

import 'package:cl_club_website/cl_club_website.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _PendingStrings extends SiteStringsNotifier {
  @override
  Future<SiteStrings> build() => Completer<SiteStrings>().future;
}

class _LoadedStrings extends SiteStringsNotifier {
  @override
  Future<SiteStrings> build() async => SiteStrings(const {'navHome': 'Start'});
}

class _FailedStrings extends SiteStringsNotifier {
  @override
  Future<SiteStrings> build() async => throw StateError('no ARB');
}

Widget _gated(SiteStringsNotifier Function() notifier) => ProviderScope(
  overrides: [siteStringsProvider.overrideWith(notifier)],
  child: ShadApp(
    home: SiteStringsGate(
      child: Builder(
        builder: (context) => Text(SiteStrings.of(context).navHome),
      ),
    ),
  ),
);

void main() {
  testWidgets('Issue 52: holds the page back while the copy loads', (
    tester,
  ) async {
    await tester.pumpWidget(_gated(_PendingStrings.new));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  testWidgets('Issue 52: puts the loaded copy in scope for SiteStrings.of', (
    tester,
  ) async {
    await tester.pumpWidget(_gated(_LoadedStrings.new));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Issue 52: says so plainly when the copy cannot load', (
    tester,
  ) async {
    await tester.pumpWidget(_gated(_FailedStrings.new));
    await tester.pumpAndSettle();

    expect(find.text('The site could not load.'), findsOneWidget);
  });
}
