// The field clusters of the user forms that hold the names and the
// account: the side-by-side pair, the names, the password and the
// username.
// Each is mounted alone in a bare ShadForm. A cluster has no validate() or
// isDirty of its own (the embedding form has) and no rule across fields;
// those points are tested on the forms.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_field_pair.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_name_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_password_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_username_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _first = UserFormFields.firstNameId;
const String _middle = UserFormFields.middleNameId;
const String _last = UserFormFields.lastNameId;
const String _nickname = UserFormFields.nicknameId;
const String _password = UserFormFields.passwordId;
const String _confirm = UserFormFields.confirmPasswordId;
const String _username = UserFormFields.usernameId;

/// Narrower than `UserFieldPair.sideBySideMinWidth` once padded.
const _narrow = Size(480, 2400);

void main() {
  group('Issue 61: UserFieldPair', () {
    Future<void> pump(WidgetTester tester, double width, double minWidth) =>
        pumpForm(
          tester,
          UserFieldPair(
            minWidth: minWidth,
            first: const SizedBox(key: Key('first'), height: 20),
            second: const SizedBox(key: Key('second'), height: 20),
          ),
          // pumpForm pads the form by 16 on each side.
          size: Size(width + 32, 600),
        );
    Rect rect(WidgetTester tester, String key) =>
        tester.getRect(find.byKey(Key(key)));

    testWidgets('Issue 61: at its minimum width the two sit side by side, '
        'equally wide, with the gap between', (tester) async {
      await pump(tester, 500, UserFieldPair.sideBySideMinWidth);

      final first = rect(tester, 'first');
      final second = rect(tester, 'second');
      expect(first.top, second.top);
      expect(first.width, second.width);
      expect(second.left - first.right, UserFieldPair.gap);
    });

    testWidgets('Issue 61: one pixel below its minimum width the second '
        'goes under the first, a row gap apart, each full width', (
      tester,
    ) async {
      await pump(tester, 499, UserFieldPair.sideBySideMinWidth);

      final first = rect(tester, 'first');
      final second = rect(tester, 'second');
      expect(second.top - first.bottom, 16);
      expect(first.width, 499);
      expect(second.width, 499);
    });

    testWidgets('Issue 61: always keeps a narrow pair side by side, and '
        'never keeps a wide one stacked', (tester) async {
      await pump(tester, 200, UserFieldPair.always);
      expect(rect(tester, 'first').top, rect(tester, 'second').top);

      await pump(tester, 1200, UserFieldPair.never);
      expect(
        rect(tester, 'second').top,
        greaterThan(rect(tester, 'first').top),
      );
    });
  });

  group('Issue 61: UserNameFields', () {
    testWidgets('Issue 61: it shows first, middle and last name, first and '
        'last marked required, and no nickname', (tester) async {
      await pumpCluster(tester, const UserNameFields());

      expect(rowLabels(tester), ['First name *', 'Middle name', 'Last name *']);
      expect(fieldIds(tester), [_first, _middle, _last]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: showNickname adds the nickname as the last row', (
      tester,
    ) async {
      await pumpCluster(tester, const UserNameFields(showNickname: true));

      expect(rowLabels(tester), [
        'First name *',
        'Middle name',
        'Last name *',
        'Nickname',
      ]);
      expect(fieldIds(tester), [_first, _middle, _last, _nickname]);
    });

    testWidgets('Issue 61: autofocus opens with the first name focused, and '
        'without it nothing is', (tester) async {
      await pumpCluster(tester, const UserNameFields(autofocus: true));
      expect(hasFocus(tester, _first), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpCluster(tester, const UserNameFields());
      expect(hasFocus(tester, _first), isFalse);
    });

    testWidgets('Issue 61: first and middle name sit side by side where '
        'there is room, stack where there is not, and follow pairMinWidth', (
      tester,
    ) async {
      await pumpCluster(tester, const UserNameFields());
      expect(sideBySide(tester, _first, _middle), isTrue);

      await pumpCluster(tester, const UserNameFields(), size: _narrow);
      expect(sideBySide(tester, _first, _middle), isFalse);

      await pumpCluster(
        tester,
        const UserNameFields(pairMinWidth: UserFieldPair.never),
      );
      expect(sideBySide(tester, _first, _middle), isFalse);

      await pumpCluster(
        tester,
        const UserNameFields(pairMinWidth: UserFieldPair.always),
        size: kPhoneSurface,
      );
      expect(sideBySide(tester, _first, _middle), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets("Issue 61: it starts from the form's values, puts what is "
        'typed under its ids, and has no rule of its own', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserNameFields(showNickname: true),
        initial: const {_first: 'Robin', _nickname: 'Rob'},
      );
      expect(editableOf(tester, _first).controller.text, 'Robin');
      expect(editableOf(tester, _nickname).controller.text, 'Rob');

      await enterField(tester, _first, '');
      await enterField(tester, _middle, ' K ');
      await enterField(tester, _last, 'Rao');

      expect(form.saveAndValidate(), isTrue);
      expect(form.value, {
        _first: '',
        _middle: ' K ',
        _last: 'Rao',
        _nickname: 'Rob',
      });
    });

    testWidgets('Issue 61: every name asks for the name keyboard', (
      tester,
    ) async {
      await pumpCluster(tester, const UserNameFields(showNickname: true));

      for (final id in [_first, _middle, _last, _nickname]) {
        expect(editableOf(tester, id).keyboardType, TextInputType.name);
      }
    });

    testWidgets('Issue 61: with enabled off every name is off', (tester) async {
      await pumpCluster(
        tester,
        const UserNameFields(enabled: false, showNickname: true),
      );

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_first, _middle, _last, _nickname]);
    });
  });

  group('Issue 61: UserPasswordFields', () {
    testWidgets('Issue 61: it shows the password and its confirmation, both '
        'required and hidden as typed', (tester) async {
      await pumpCluster(tester, const UserPasswordFields());

      expect(rowLabels(tester), ['Password *', 'Confirm password *']);
      expect(fieldIds(tester), [_password, _confirm]);
      expect(editableOf(tester, _password).obscureText, isTrue);
      expect(editableOf(tester, _confirm).obscureText, isTrue);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Re-type password'), findsOneWidget);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: an empty password and an empty confirmation are '
        'refused, each on its field', (tester) async {
      final form = await pumpCluster(tester, const UserPasswordFields());

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();

      expectMessageOn(_password, 'Password is required');
      expectMessageOn(_confirm, 'Please confirm the password');
    });

    testWidgets('Issue 61: a password of seven characters is refused on its '
        'field and one of eight is taken', (tester) async {
      final form = await pumpCluster(tester, const UserPasswordFields());
      await enterField(tester, _confirm, 'x');
      await enterField(tester, _password, '1234567');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      // The hint reads the same as the message; the hint is gone once
      // something is typed.
      expectMessageOn(_password, 'At least 8 characters');

      await enterField(tester, _password, '12345678');
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: it leaves whether the two match to the form', (
      tester,
    ) async {
      final form = await pumpCluster(tester, const UserPasswordFields());
      await enterField(tester, _password, 'secret-password');
      await enterField(tester, _confirm, 'another-password');

      expect(form.saveAndValidate(), isTrue);
      expect(form.value, {
        _password: 'secret-password',
        _confirm: 'another-password',
      });
    });

    testWidgets('Issue 61: with enabled off both are off', (tester) async {
      await pumpCluster(tester, const UserPasswordFields(enabled: false));

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_password, _confirm]);
    });
  });

  group('Issue 61: UserUsernameField', () {
    Future<List<(String, String?)>> pump(
      WidgetTester tester, {
      bool enabled = true,
      bool available = true,
    }) async {
      final reports = <(String, String?)>[];
      await pumpCluster(
        tester,
        UserUsernameField(
          enabled: enabled,
          onAvailabilityChanged: (username, confirmed) =>
              reports.add((username, confirmed)),
          checkAvailability: (_) async => available,
        ),
      );
      return reports;
    }

    testWidgets('Issue 61: it is one required row with its hint, focused '
        'when the form opens', (tester) async {
      await pump(tester);

      expect(rowLabels(tester), ['Username *']);
      expect(fieldIds(tester), [_username]);
      expect(find.text('unique-username'), findsOneWidget);
      expect(hasFocus(tester, _username), isTrue);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: it passes a confirmed username on, and a taken '
        'one as unconfirmed', (tester) async {
      final reports = await pump(tester);
      await checkUsername(tester, _username, 'robin');
      expect(reports.last, ('robin', 'robin'));

      await tester.pumpWidget(const SizedBox.shrink());
      final refused = await pump(tester, available: false);
      await checkUsername(tester, _username, 'robin');
      expect(refused.last, ('robin', null));
    });

    testWidgets('Issue 61: it holds the username to the username rules', (
      tester,
    ) async {
      final form = await pumpCluster(
        tester,
        UserUsernameField(
          onAvailabilityChanged: (_, _) {},
          checkAvailability: (_) async => true,
        ),
      );

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_username, 'Username is required');

      await enterField(tester, _username, 'ro');
      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_username, 'At least 3 characters');

      await enterField(tester, _username, 'rob');
      expect(form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: with enabled off it is off', (tester) async {
      await pump(tester, enabled: false);

      expectEveryFieldOff(tester);
    });
  });
}
