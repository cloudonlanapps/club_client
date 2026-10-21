import 'package:cl_club_members/src/utils/join_request_decisions.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

JoinRequest _request(JoinRequestStatus status) => JoinRequest(
  id: 7,
  groupId: 1,
  groupName: 'Juniors',
  username: 'robin',
  status: status,
  requestedAt: 0,
);

/// Answers approve and reject with the decided request, or throws
/// [failure] when one is set.
class _Requests extends ClGroupRequestsMasterNotifier {
  _Requests(this.failure);

  final Exception? failure;
  final calls = <String>[];

  @override
  Future<Map<int, JoinRequest>> build(int groupId) async => {
    7: _request(JoinRequestStatus.pending),
  };

  @override
  Future<JoinRequest> approve(int requestId) async {
    calls.add('approve $requestId');
    final failure = this.failure;
    if (failure != null) throw failure;
    return _request(JoinRequestStatus.approved);
  }

  @override
  Future<JoinRequest> reject(int requestId, {String? reason}) async {
    calls.add('reject $requestId ${reason ?? '-'}');
    final failure = this.failure;
    if (failure != null) throw failure;
    return _request(JoinRequestStatus.rejected);
  }
}

/// Counts the loads of the requester's own list of requests.
class _MyRequests extends ClMyJoinRequestsMasterNotifier {
  _MyRequests(this.onBuild);

  final VoidCallback onBuild;

  @override
  Future<Map<int, JoinRequest>> build(String username) async {
    onBuild();
    return const {};
  }
}

class _Harness {
  _Harness(this.requests);

  final _Requests requests;
  final busy = <bool>[];
  bool? result;
  int myRequestLoads = 0;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required bool approve,
  Exception? failure,
}) async {
  final h = _Harness(_Requests(failure));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clGroupRequestsMasterProvider.overrideWith(() => h.requests),
        clMyJoinRequestsMasterProvider.overrideWith(
          () => _MyRequests(() => h.myRequestLoads++),
        ),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                // The requester's list is on screen, as on their profile.
                ref.watch(clMyJoinRequestsMasterProvider('robin'));
                return TextButton(
                  onPressed: () async {
                    h.result = approve
                        ? await approveJoinRequest(
                            context,
                            groupId: 1,
                            requestId: 7,
                            onBusy: h.busy.add,
                          )
                        : await rejectJoinRequest(
                            context,
                            groupId: 1,
                            requestId: 7,
                            onBusy: h.busy.add,
                          );
                  },
                  child: const Text('decide'),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('decide'));
  await tester.pumpAndSettle();
  return h;
}

/// Confirms the reject-reason dialog with [reason].
Future<void> _confirmReject(WidgetTester tester, String reason) async {
  await tester.enterText(find.byType(EditableText), reason);
  await tester.tap(find.widgetWithText(ShadButton, 'Reject'));
  await tester.pumpAndSettle();
}

const _unreachable = ServerException(
  statusCode: 403,
  code: 'FORBIDDEN',
  message: 'denied',
);

void main() {
  group('Issue 226: one approve / reject join-request flow', () {
    testWidgets('Issue 226: approve succeeds, says so and refreshes the '
        'requests of the requester', (tester) async {
      final h = await _pump(tester, approve: true);

      expect(h.requests.calls, ['approve 7']);
      expect(h.result, isTrue);
      expect(h.busy, [true, false]);
      expect(find.text('Request approved.'), findsOneWidget);
      expect(h.myRequestLoads, 2, reason: 'reloaded once after the approve');
    });

    testWidgets('Issue 226: an approve the server refuses for eligibility '
        'says why', (tester) async {
      final h = await _pump(
        tester,
        approve: true,
        failure: const ServerException(
          statusCode: 422,
          code: SdkErrorCode.notEligible,
          message: 'raw',
        ),
      );

      expect(h.result, isFalse);
      expect(h.busy, [true, false]);
      expect(find.text('No longer eligible for this group.'), findsOneWidget);
      expect(h.myRequestLoads, 1);
    });

    testWidgets('Issue 226: an approve that fails off the server is the '
        'fixed message', (tester) async {
      final h = await _pump(
        tester,
        approve: true,
        failure: Exception('socket closed'),
      );

      expect(h.result, isFalse);
      expect(h.busy, [true, false]);
      expect(find.textContaining('socket closed'), findsNothing);
    });

    testWidgets('Issue 226: reject sends the reason, says so and refreshes '
        'the requests of the requester', (tester) async {
      final h = await _pump(tester, approve: false);
      await _confirmReject(tester, '  full  ');

      expect(h.requests.calls, ['reject 7 full']);
      expect(h.result, isTrue);
      expect(h.busy, [true, false]);
      expect(find.text('Request rejected.'), findsOneWidget);
      expect(h.myRequestLoads, 2);
    });

    testWidgets('Issue 226: a refused reject says so and keeps the list', (
      tester,
    ) async {
      final h = await _pump(tester, approve: false, failure: _unreachable);
      await _confirmReject(tester, '');

      expect(h.requests.calls, ['reject 7 -']);
      expect(h.result, isFalse);
      expect(h.busy, [true, false]);
      expect(find.text('Could not reject: denied'), findsOneWidget);
      expect(h.myRequestLoads, 1);
    });
  });
}
