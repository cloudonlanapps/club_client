import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StubNotificationsMaster extends ClNotificationsMasterNotifier {
  int? lastDeletedId;
  bool shouldThrow = false;

  @override
  Future<Map<int, AppNotification>> build() async {
    return const <int, AppNotification>{};
  }

  @override
  Future<void> deleteNotification(int id) async {
    if (shouldThrow) throw StateError('boom');
    lastDeletedId = id;
  }
}

ProviderContainer _container(StubNotificationsMaster stub) {
  return ProviderContainer(
    overrides: [
      clNotificationsMasterProvider.overrideWith(() => stub),
    ],
  );
}

Widget _wrap(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: ShadApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('renders the removed-event message + event id', (tester) async {
    final stub = StubNotificationsMaster();
    final container = _container(stub);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _wrap(
        RemovedEventView(eventId: 573, onDismissed: () {}),
        container,
      ),
    );
    expect(find.text('This event has been removed.'), findsOneWidget);
    expect(
      find.text('Event #573 no longer exists on the server.'),
      findsOneWidget,
    );
  });

  testWidgets('hides Delete notification when no sourceNotificationId', (
    tester,
  ) async {
    final stub = StubNotificationsMaster();
    final container = _container(stub);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _wrap(
        RemovedEventView(eventId: 1, onDismissed: () {}),
        container,
      ),
    );
    expect(find.text('Delete notification'), findsNothing);
  });

  testWidgets(
    'with sourceNotificationId: Delete calls master notifier',
    (tester) async {
      final stub = StubNotificationsMaster();
      final container = _container(stub);
      addTearDown(container.dispose);
      var dismissed = false;
      await tester.pumpWidget(
        _wrap(
          RemovedEventView(
            eventId: 1,
            sourceNotificationId: 62,
            onDismissed: () => dismissed = true,
          ),
          container,
        ),
      );
      expect(find.text('Delete notification'), findsOneWidget);
      await tester.tap(find.text('Delete notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(stub.lastDeletedId, 62);
      expect(dismissed, isTrue);
    },
  );

  testWidgets('Delete failure leaves the view on screen', (tester) async {
    final stub = StubNotificationsMaster()..shouldThrow = true;
    final container = _container(stub);
    addTearDown(container.dispose);
    var dismissed = false;
    await tester.pumpWidget(
      _wrap(
        RemovedEventView(
          eventId: 1,
          sourceNotificationId: 7,
          onDismissed: () => dismissed = true,
        ),
        container,
      ),
    );
    await tester.tap(find.text('Delete notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Delete notification'), findsOneWidget);
    expect(dismissed, isFalse);
    // Issue 138: the failure is reported, in fixed text.
    expect(find.text(uncertainWriteMessage), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
  });
}
