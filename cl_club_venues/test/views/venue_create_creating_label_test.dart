// Issue 108: while the venue is created, Create venue is off and reads
// "Creating…", written with one character.
import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart' show VenueFormFields;
import 'package:cl_club_venues/src/views/venue_create_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A venues master whose create waits on [held].
class _HeldVenues extends ClVenuesMasterNotifier {
  _HeldVenues(this.held);

  final Completer<void> held;

  @override
  Future<Map<int, Venue>> build() async => {};

  @override
  Future<Venue> createVenue({
    required String name,
    bool isDefault = false,
    String? address,
    String? description,
    String? mapUri,
    bool isFeatured = false,
  }) async {
    await held.future;
    return Venue(
      id: 1,
      name: name,
      isDefault: isDefault,
      createdAtUtc: DateTime.utc(2025),
      updatedAtUtc: DateTime.utc(2025),
    );
  }
}

void main() {
  testWidgets('Issue 108: Create venue reads "Creating…" on a button that '
      'is off while the venue is created', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final held = Completer<void>();
    final log = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clVenuesMasterProvider.overrideWith(() => _HeldVenues(held)),
        ],
        child: ShadApp(
          home: Scaffold(
            body: VenueCreateView(
              onCreated: () => log.add('created'),
              onCancel: () => log.add('cancelled'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == VenueFormFields.nameId,
      ),
      'Main Arena',
    );
    await tester.pump();

    await tester.tap(find.text('Create venue'));
    await tester.pump();

    expect(find.text('Create venue'), findsNothing);
    expect(find.text('Creating...'), findsNothing);
    expect(
      tester
          .widget<ShadButton>(find.widgetWithText(ShadButton, 'Creating…'))
          .onPressed,
      isNull,
    );

    held.complete();
    await tester.pumpAndSettle();
    expect(log, ['created']);
  });
}
