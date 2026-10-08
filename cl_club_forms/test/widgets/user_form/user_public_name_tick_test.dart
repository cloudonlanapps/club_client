// Issue 68, the public-name tick of a coach's own profile: it stays one
// field of the form however often the public-profile tick is toggled.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_public_name_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _useName = UserFormFields.useNamePubliclyId;
const String _publicProfile = UserFormFields.isPublicProfileId;

/// Whether the tick with [id] is ticked, as drawn.
bool _ticked(WidgetTester tester, String id) => tester
    .widget<ShadCheckbox>(
      find.descendant(of: fieldWithId(id), matching: find.byType(ShadCheckbox)),
    )
    .value;

void main() {
  group('Issue 68: the public-name tick keeps its place in the form', () {
    testWidgets('Issue 68: it stays registered however often the profile '
        'tick is toggled', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(canEditPublicProfile: true),
        initial: const {_publicProfile: true, _useName: true},
      );
      final field = form.fields[_useName];
      expect(field, isNotNull);

      for (var toggle = 1; toggle <= 4; toggle++) {
        await tapCheckbox(tester, _publicProfile);

        expect(
          form.fields[_useName],
          same(field),
          reason: 'after $toggle toggles',
        );
      }
    });

    testWidgets('Issue 68: making the profile non-public unticks it, and '
        'making it public again gives it the value it opened with', (
      tester,
    ) async {
      final form = await pumpCluster(
        tester,
        const UserPublicNameFields(canEditPublicProfile: true),
        initial: const {_publicProfile: true, _useName: true},
      );

      await tapCheckbox(tester, _publicProfile);
      expect(form.value[_useName], isFalse);
      expect(_ticked(tester, _useName), isFalse);

      await tapCheckbox(tester, _publicProfile);
      expect(form.value[_useName], isTrue);
      expect(_ticked(tester, _useName), isTrue);

      await tapCheckbox(tester, _useName);
      expect(form.value[_useName], isFalse);
      expect(_ticked(tester, _useName), isFalse);
    });

    testWidgets('Issue 68: after the profile tick is toggled, a refusal for '
        'the public name shows on its tick', (tester) async {
      const refused = 'Refused by the server.';
      final key = GlobalKey<UserPersonalDetailsFormState>();
      await pumpForm(
        tester,
        UserPersonalDetailsForm(
          key: key,
          initialValues: const {
            UserFormFields.firstNameId: 'Robin',
            _publicProfile: true,
            _useName: true,
          },
          canEditPublicProfile: true,
        ),
      );
      final state = key.currentState!;

      await tapCheckbox(tester, _publicProfile);
      await tapCheckbox(tester, _publicProfile);
      state.showErrors(fieldErrors: const {_useName: refused});
      await tester.pumpAndSettle();

      expectMessageOn(_useName, refused);
      expect(state.formError, isNull);
    });

    testWidgets('Issue 68: after a toggle, the form still returns the '
        'public name and resets it with the other fields', (tester) async {
      final key = GlobalKey<UserPersonalDetailsFormState>();
      await pumpForm(
        tester,
        UserPersonalDetailsForm(
          key: key,
          initialValues: const {
            UserFormFields.firstNameId: 'Robin',
            _publicProfile: true,
            _useName: true,
          },
          canEditPublicProfile: true,
        ),
      );
      final state = key.currentState!;

      await tapCheckbox(tester, _publicProfile);
      expect(state.isDirty, isTrue);
      expect(state.validate(), containsPair(_useName, false));

      state.formKey.currentState!.reset();
      await tester.pumpAndSettle();

      expect(_ticked(tester, _useName), isTrue);
      expect(state.isDirty, isFalse);
    });
  });
}
