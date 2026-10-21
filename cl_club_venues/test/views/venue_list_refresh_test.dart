import 'dart:async';

import 'package:cl_club_venues/src/views/venue_list_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider, venueImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Loads at once the first time; every reload waits for [reload].
class _Venues extends ClVenuesMasterNotifier {
  _Venues(this.reload);

  final Completer<void> reload;
  int builds = 0;

  @override
  Future<Map<int, Venue>> build() async {
    if (builds++ > 0) await reload.future;
    return {
      1: Venue(
        id: 1,
        name: 'Riverside Rink',
        createdAtUtc: DateTime.utc(2025),
        updatedAtUtc: DateTime.utc(2025),
      ),
    };
  }
}

void main() {
  testWidgets('Issue 194: pull-to-refresh ends only once the venues have '
      'reloaded', (tester) async {
    final reload = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clVenuesMasterProvider.overrideWith(() => _Venues(reload)),
          venueImageProvider(1).overrideWith((ref) async => null),
          imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        ],
        child: ShadApp(
          home: Scaffold(
            body: VenueListView(onVenueTap: (_) {}, onCreateVenue: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Riverside Rink'), findsOneWidget);

    var done = false;
    unawaited(
      tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh()
          .then((_) => done = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(done, isFalse);

    reload.complete();
    await tester.pumpAndSettle();
    expect(done, isTrue);
  });
}
