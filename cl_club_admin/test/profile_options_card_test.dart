// Issue 320: the club's profile options on the Club details page — shown
// only while the extended profile is on, edited in place with
// ProfileOptionsForm and saved as the whole document.
import 'package:cl_club_admin/cl_club_admin.dart';
import 'package:cl_club_admin/src/constants/profile_options_messages.dart';
import 'package:cl_club_admin/src/models/profile_options_form_helpers.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import 'support/admin_test_scope.dart';

const _stored = ProfileOptions(
  positions: [
    ProfilePosition(
      value: 'Forward',
      label: {'en': 'Forward', 'mr': 'फॉरवर्ड'},
    ),
    ProfilePosition(value: 'Goalie', label: {'en': 'Goalie'}),
  ],
  languages: ['English', 'Marathi'],
);

/// Serves [stored] and records each save, or refuses it with [refuseWith].
class _StubOptions extends ProfileOptionsNotifier {
  _StubOptions(this.stored);

  ProfileOptions stored;
  final List<ProfileOptions> saves = [];
  ServerException? refuseWith;

  @override
  Future<ProfileOptions> build() async => stored;

  @override
  Future<ProfileOptions> save(ProfileOptions options) async {
    final refusal = refuseWith;
    if (refusal != null) throw refusal;
    saves.add(options);
    stored = options;
    state = AsyncData(options);
    return options;
  }
}

Future<_StubOptions> _pump(
  WidgetTester tester, {
  bool extendedProfile = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 5000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = _StubOptions(_stored);
  await tester.pumpWidget(
    adminScope(
      overrides: [
        clClubIdentityMasterProvider.overrideWith(
          () => StubClubIdentity(const ClubIdentity(name: 'Example Club')),
        ),
        capabilitiesProvider.overrideWith(
          (ref) async => Capabilities(extendedProfile: extendedProfile),
        ),
        profileOptionsProvider.overrideWith(() => stub),
      ],
      child: ClubIdentityView(currentUser: adminViewer(superAdmin: true)),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

Finder _inCard(Finder matching) => find.descendant(
  of: find.byKey(ProfileOptionsCard.cardKey),
  matching: matching,
);

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

void main() {
  group('Issue 320: the profile options on Club details', () {
    testWidgets('Issue 320: there is no such section while the extended '
        'profile is off', (tester) async {
      await _pump(tester, extendedProfile: false);

      expect(find.byKey(ProfileOptionsCard.cardKey), findsNothing);
    });

    testWidgets('Issue 320: it reads the positions with their labels and '
        'the languages', (tester) async {
      await _pump(tester);

      expect(_inCard(find.text(ProfileOptionsMessages.title)), findsOneWidget);
      expect(_inCard(find.textContaining('फॉरवर्ड')), findsOneWidget);
      expect(_inCard(find.textContaining('Goalie')), findsOneWidget);
      expect(_inCard(find.text('English, Marathi')), findsOneWidget);
    });

    testWidgets('Issue 320: the editor labels positions in English, '
        'Marathi and Hindi', (tester) async {
      await _pump(tester);

      await tester.tap(_inCard(find.byType(SectionEditButton)));
      await tester.pumpAndSettle();

      for (final name in ['English', 'Marathi', 'Hindi']) {
        expect(_inCard(find.text(name)), findsWidgets);
      }
    });

    testWidgets('Issue 320: an added language is saved with the rest of the '
        'options', (tester) async {
      final stub = await _pump(tester);

      await tester.tap(_inCard(find.byType(SectionEditButton)));
      await tester.pumpAndSettle();
      await tester.tap(_inCard(find.text('Add language')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: _field(ProfileOptionsFormFields.languagesId),
              matching: find.byType(EditableText),
            )
            .last,
        'Tamil',
      );
      await tester.pump();
      await tester.tap(_inCard(find.widgetWithText(ShadButton, 'Save')));
      await tester.pumpAndSettle();

      expect(stub.saves, [
        _stored.copyWith(languages: ['English', 'Marathi', 'Tamil']),
      ]);
      expect(find.text(ProfileOptionsMessages.saved), findsOneWidget);
    });

    testWidgets('Issue 320: a schema refusal shows on the field it names, '
        'and the editor stays open', (tester) async {
      final stub = await _pump(tester)
        ..refuseWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.validationError,
          message: 'raw server text',
          details: {
            ServerException.refusedFieldsKey: [
              {
                'loc': ['body', 'languages', 1],
                'msg': 'Value error, a language appears twice',
              },
            ],
          },
        );

      await tester.tap(_inCard(find.byType(SectionEditButton)));
      await tester.pumpAndSettle();
      await tester.tap(_inCard(find.text('Add language')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: _field(ProfileOptionsFormFields.languagesId),
              matching: find.byType(EditableText),
            )
            .last,
        'Tamil',
      );
      await tester.pump();
      await tester.tap(_inCard(find.widgetWithText(ShadButton, 'Save')));
      await tester.pumpAndSettle();

      expect(stub.saves, isEmpty);
      expect(
        find.descendant(
          of: _field(ProfileOptionsFormFields.languagesId),
          matching: find.text('A language appears twice'),
        ),
        findsOneWidget,
      );
      expect(find.text('raw server text'), findsNothing);
    });
  });

  group('Issue 320: the profile options adapter', () {
    test('Issue 320: the stored options become the form values and back', () {
      final values = buildProfileOptionsFormInitialValues(_stored);
      expect(ProfileOptionsFormSubmit.optionsOf(values), _stored);
    });
  });
}
