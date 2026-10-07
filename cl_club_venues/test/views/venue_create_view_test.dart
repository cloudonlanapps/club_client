import 'package:cl_club_forms/cl_club_forms.dart' show VenueFormFields;
import 'package:cl_club_venues/src/models/venue_form_helpers.dart';
import 'package:cl_club_venues/src/views/venue_create_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Records the creates the view sends, and refuses them with [refusal] when
/// one is set.
class _Venues extends ClVenuesMasterNotifier {
  _Venues({this.refusal});

  final Exception? refusal;
  final List<({String name, bool isDefault})> created = [];

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
    created.add((name: name, isDefault: isDefault));
    final refused = refusal;
    if (refused != null) throw refused;
    return Venue(
      id: 1,
      name: name,
      isDefault: isDefault,
      createdAtUtc: DateTime.utc(2025),
      updatedAtUtc: DateTime.utc(2025),
    );
  }
}

Future<({_Venues venues, List<String> log})> _pump(
  WidgetTester tester, {
  Exception? refusal,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final venues = _Venues(refusal: refusal);
  final log = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clVenuesMasterProvider.overrideWith(() => venues)],
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
  return (venues: venues, log: log);
}

Finder _input(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 55: the create-venue view drives the form', () {
    testWidgets('Issue 55: Create venue with no name creates nothing and '
        'shows the message on the name', (tester) async {
      final host = await _pump(tester);
      expect(find.text('New Venue'), findsOneWidget);

      await _tap(tester, 'Create venue');

      expect(host.venues.created, isEmpty);
      expect(host.log, isEmpty);
      expect(find.text('Venue name is required'), findsOneWidget);
    });

    testWidgets('Issue 55: Create venue validates the form, creates the '
        'venue and reports it', (tester) async {
      final host = await _pump(tester);
      await tester.enterText(_input(VenueFormFields.nameId), ' Main Arena ');
      await tester.pump();

      await _tap(tester, 'Create venue');

      expect(host.venues.created.single.name, 'Main Arena');
      expect(host.log, ['created']);
    });

    testWidgets('Issue 55: a second default venue the server refuses shows '
        'on the Default venue switch, and the view stays', (tester) async {
      final host = await _pump(
        tester,
        refusal: const ServerException(
          statusCode: 409,
          code: SdkErrorCode.defaultVenueExists,
          message: 'A default venue already exists',
        ),
      );
      await tester.enterText(_input(VenueFormFields.nameId), 'Main Arena');
      await tester.tap(find.byType(ShadSwitch).first);
      await tester.pumpAndSettle();

      await _tap(tester, 'Create venue');

      expect(host.venues.created.single.isDefault, isTrue);
      expect(host.log, isEmpty);
      expect(
        find.text(VenueFormSubmit.defaultVenueExistsMessage),
        findsOneWidget,
      );
      // The action is back on once the create has answered.
      expect(find.text('Create venue'), findsOneWidget);
    });
  });
}
