import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A network monitor the test moves by hand; it counts the checks asked of
/// it and runs none.
class ManualNetworkStatus extends NetworkStatusNotifier {
  ManualNetworkStatus(super.ref);

  int checks = 0;

  @override
  void checkNow() => checks++;

  /// The status shown to the app.
  NetworkStatus get status => state;

  set status(NetworkStatus value) => state = value;
}

Future<ManualNetworkStatus> pumpPage(WidgetTester tester) async {
  late ManualNetworkStatus monitor;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        networkStatusProvider.overrideWith(
          (ref) => monitor = ManualNetworkStatus(ref),
        ),
      ],
      child: const ShadApp(
        home: Scaffold(
          body: NetworkStatusWrapper(
            child: Center(child: TextField(key: Key('typed'))),
          ),
        ),
      ),
    ),
  );
  return monitor;
}

void main() {
  for (final status in [
    NetworkStatus.offline,
    NetworkStatus.serverUnavailable,
  ]) {
    testWidgets(
      'Issue 163: the page keeps what was typed and its focus while '
      '${status.name}',
      (tester) async {
        final monitor = await pumpPage(tester);
        final field = find.byKey(const Key('typed'));
        await tester.tap(field);
        await tester.enterText(field, 'half a note');
        await tester.pump();
        final state = tester.state<EditableTextState>(
          find.byType(EditableText),
        );

        monitor.status = status;
        await tester.pump();

        expect(find.byType(NetworkFailureScreen), findsNothing);
        expect(find.byType(NetworkFailureBanner), findsOneWidget);
        expect(find.text('half a note'), findsOneWidget);
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(state),
        );
        expect(state.widget.focusNode.hasFocus, isTrue);

        monitor.status = NetworkStatus.online;
        await tester.pump();

        expect(find.byType(NetworkFailureBanner), findsNothing);
        expect(find.text('half a note'), findsOneWidget);
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(state),
        );
        expect(state.widget.focusNode.hasFocus, isTrue);
      },
    );
  }

  testWidgets(
    'Issue 163: Try Again on the banner asks for a network check',
    (tester) async {
      final monitor = await pumpPage(tester);
      monitor.status = NetworkStatus.offline;
      await tester.pump();

      expect(find.text('No Internet Connection'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(monitor.checks, 1);
    },
  );
}
