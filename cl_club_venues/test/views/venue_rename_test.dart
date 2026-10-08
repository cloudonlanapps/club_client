import 'package:cl_club_forms/cl_club_forms.dart'
    show RenameForm, RenameFormFields;
import 'package:cl_club_venues/src/views/venue_profile_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final _venue = Venue(
  id: 4,
  name: 'Main Arena',
  isDefault: false,
  createdAtUtc: DateTime.utc(2025),
  updatedAtUtc: DateTime.utc(2025),
);

/// Records the renames the section sends, and refuses them with [refusal]
/// when one is set.
class _Venues extends ClVenuesMasterNotifier {
  _Venues({this.refusal});

  final Exception? refusal;
  final List<String?> renamed = [];

  @override
  Future<Map<int, Venue>> build() async => {_venue.id: _venue};

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
    renamed.add(name);
    final refused = refusal;
    if (refused != null) throw refused;
    return _venue;
  }
}

Future<_Venues> _pump(WidgetTester tester, {Exception? refusal}) async {
  final venues = _Venues(refusal: refusal);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clVenuesMasterProvider.overrideWith(() => venues)],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VenueManagementSection(venue: _venue, onDeleted: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return venues;
}

Finder _nameField() => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == RenameFormFields.valueId,
);

Future<void> _rename(WidgetTester tester, String name) async {
  await tester.tap(find.text('Rename'));
  await tester.pumpAndSettle();
  await tester.enterText(_nameField(), name);
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 95: Venue Management renames while the dialog is open', () {
    testWidgets('Issue 95: a refused venue rename leaves the dialog open '
        'with the typed name and the message on the field', (tester) async {
      final venues = await _pump(tester, refusal: Exception('refused'));

      await _rename(tester, 'Side Rink');

      expect(venues.renamed, ['Side Rink']);
      expect(_nameField(), findsOneWidget);
      expect(find.text('Side Rink'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RenameForm),
          matching: find.text(VenueManagementSectionState.renameFailedMessage),
        ),
        findsOneWidget,
      );
      expect(find.text('Venue renamed.'), findsNothing);
    });

    testWidgets('Issue 95: a saved venue rename closes the dialog and says '
        'so', (tester) async {
      final venues = await _pump(tester);

      await _rename(tester, 'Side Rink');

      expect(venues.renamed, ['Side Rink']);
      expect(_nameField(), findsNothing);
      expect(find.text('Venue renamed.'), findsOneWidget);
    });
  });
}
