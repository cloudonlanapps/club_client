import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart' show LocationEditForm;
import 'package:cl_club_forms/src/widgets/location_edit/location_edit_form_fields.dart'
    show LocationEditFormFields;
import 'package:cl_club_venues/src/views/venue_profile_view.dart'
    show VenueLocationCard;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Holds every update until [answer] completes, then refuses it.
class _HeldVenues extends ClVenuesMasterNotifier {
  final Completer<void> answer = Completer<void>();

  @override
  Future<Map<int, Venue>> build() async => {};

  @override
  Future<Venue> updateVenue(
    int id, {
    String? name,
    bool? isDefault,
    String? Function()? address,
    String? Function()? description,
    String? Function()? mapUri,
    bool? isFeatured,
  }) async {
    await answer.future;
    throw const ServerException(
      statusCode: 500,
      code: 'INTERNAL',
      message: 'raw server text',
    );
  }
}

bool _formOn(WidgetTester tester) =>
    tester.widget<LocationEditForm>(find.byType(LocationEditForm)).enabled;

void main() {
  testWidgets('Issue 91: the venue Location form is off while its save is in '
      'flight, and on again once it is refused', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final venues = _HeldVenues();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clVenuesMasterProvider.overrideWith(() => venues)],
        child: ShadApp(
          home: ShadToaster(
            child: Scaffold(
              body: SingleChildScrollView(
                child: VenueLocationCard(
                  venue: Venue(
                    id: 1,
                    name: 'Main rink',
                    isDefault: false,
                    address: '1 Rink Road',
                    createdAtUtc: DateTime.utc(2025),
                    updatedAtUtc: DateTime.utc(2025),
                  ),
                  canEdit: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is ShadInputFormField && w.id == LocationEditFormFields.addressId,
      ),
      '2 Rink Road',
    );
    expect(_formOn(tester), isTrue);

    await tester.tap(find.widgetWithText(ShadButton, 'Save'));
    await tester.pump();
    expect(_formOn(tester), isFalse);

    venues.answer.complete();
    await tester.pumpAndSettle();
    expect(_formOn(tester), isTrue);
  });
}
