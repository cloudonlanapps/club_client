// Issue 329: the admin leaves the Club details page while the profile
// options save is still in flight. The card is gone when the save ends;
// its toast still shows, through the app's toaster, and nothing throws.
import 'dart:async';

import 'package:cl_club_admin/cl_club_admin.dart';
import 'package:cl_club_admin/src/constants/profile_options_messages.dart';
import 'package:cl_club_admin/src/widgets/profile_options_card.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show ProfileOptionsFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ProfileOptionsNotifier,
        capabilitiesProvider,
        clClubIdentityMasterProvider,
        profileOptionsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import 'support/admin_test_scope.dart';

const _stored = ProfileOptions(
  positions: [
    ProfilePosition(value: 'Goalie', label: {'en': 'Goalie'}),
  ],
  languages: [ProfileLanguage(code: 'en', name: 'English')],
);

/// Holds each save until the test ends it.
class _PendingOptions extends ProfileOptionsNotifier {
  final pending = Completer<ProfileOptions>();

  @override
  Future<ProfileOptions> build() async => _stored;

  @override
  Future<ProfileOptions> save(ProfileOptions options) => pending.future;
}

Finder _inCard(Finder matching) => find.descendant(
  of: find.byKey(ProfileOptionsCard.cardKey),
  matching: matching,
);

/// Opens the editor, adds a language and taps Save; the save stays in
/// flight. Then the page is replaced, as when the admin navigates away.
Future<_PendingOptions> _saveThenLeave(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1100, 5000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = _PendingOptions();
  final onPage = ValueNotifier(true);
  addTearDown(onPage.dispose);
  await tester.pumpWidget(
    adminScope(
      overrides: [
        clClubIdentityMasterProvider.overrideWith(
          () => StubClubIdentity(const ClubIdentity(name: 'Example Club')),
        ),
        capabilitiesProvider.overrideWith(
          (ref) async => const Capabilities(extendedProfile: true),
        ),
        profileOptionsProvider.overrideWith(() => stub),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: onPage,
        builder: (context, show, _) => show
            ? ClubIdentityView(currentUser: adminViewer(superAdmin: true))
            : const Text('another page'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(_inCard(find.byType(SectionEditButton)));
  await tester.pumpAndSettle();
  await tester.tap(_inCard(find.text('Add language')));
  await tester.pumpAndSettle();
  final inputs = find.descendant(
    of: find.byWidgetPredicate(
      (w) =>
          w is ShadFormBuilderField &&
          w.id == ProfileOptionsFormFields.languagesId,
    ),
    matching: find.byType(EditableText),
  );
  // The new language's name and code, its two inputs (Issue 396).
  await tester.enterText(inputs.first, 'Tamil');
  await tester.enterText(inputs.last, 'ta');
  await tester.pump();
  await tester.tap(_inCard(find.widgetWithText(ShadButton, 'Save')));
  await tester.pump();

  onPage.value = false;
  await tester.pumpAndSettle();
  expect(find.byKey(ProfileOptionsCard.cardKey), findsNothing);
  expect(find.text('another page'), findsOneWidget);
  return stub;
}

void main() {
  group('Issue 329: leaving Club details while profile options save', () {
    testWidgets('Issue 329: a save that succeeds after the card is gone '
        'shows its toast and throws nothing', (tester) async {
      final stub = await _saveThenLeave(tester);

      stub.pending.complete(_stored);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(ProfileOptionsMessages.saved), findsOneWidget);
    });

    testWidgets('Issue 329: a save that fails after the card is gone '
        'shows its toast and throws nothing', (tester) async {
      final stub = await _saveThenLeave(tester);

      stub.pending.completeError(
        const ServerException(
          statusCode: 500,
          code: 'INTERNAL_ERROR',
          message: 'down',
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(ProfileOptionsMessages.saveFailed), findsOneWidget);
    });
  });
}
