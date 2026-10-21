import 'package:cl_club_forms/cl_club_forms.dart' show VenueFormFields;
import 'package:cl_club_venues/src/utils/venue_write_messages.dart';
import 'package:cl_club_venues/src/views/venue_create_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Stores every create.
class _Venues extends ClVenuesMasterNotifier {
  int creates = 0;

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
    creates++;
    return Venue(
      id: 1,
      name: name,
      createdAtUtc: DateTime.utc(2025),
      updatedAtUtc: DateTime.utc(2025),
    );
  }
}

void main() {
  testWidgets('Issue 194: a host whose onCreated throws is not reported as '
      'a failed create', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final venues = _Venues();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clVenuesMasterProvider.overrideWith(() => venues)],
        child: ShadApp(
          home: Scaffold(
            body: VenueCreateView(
              onCreated: () => throw StateError('navigation'),
              onCancel: () {},
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

    // Create venue, as its button does; the host's fault reaches the
    // caller instead of being read as a failed create.
    final view = tester.state<VenueCreateViewState>(
      find.byType(VenueCreateView),
    );
    await expectLater(view.submit(), throwsStateError);
    await tester.pumpAndSettle();

    expect(venues.creates, 1);
    expect(find.text('Venue "Main Arena" created.'), findsOneWidget);
    expect(find.text(venueCreateFailedMessage), findsNothing);
  });
}
