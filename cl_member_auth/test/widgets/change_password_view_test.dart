import 'package:cl_club_forms/cl_club_forms.dart' show ChangePasswordFormFields;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// Pumps the view with [onChangePassword] in place of the server call.
Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function(String current, String next) onChangePassword,
  VoidCallback? onSuccess,
  VoidCallback? onCancel,
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: ChangePasswordView(
              onSuccess: onSuccess ?? () {},
              onCancel: onCancel ?? () {},
              onChangePassword:
                  ({required currentPassword, required newPassword}) =>
                      onChangePassword(currentPassword, newPassword),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillAndUpdate(WidgetTester tester) async {
  await tester.enterText(_field(ChangePasswordFormFields.currentId), 'old-one');
  await tester.enterText(_field(ChangePasswordFormFields.nextId), 'new-pass-1');
  await tester.enterText(
    _field(ChangePasswordFormFields.confirmId),
    'new-pass-1',
  );
  await tester.tap(find.widgetWithText(ShadButton, 'Update password'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: ChangePasswordView owns the title, the buttons and the '
      'save', () {
    testWidgets('Issue 53: Update validates the form, then changes the '
        'password with its values', (tester) async {
      final calls = <(String, String)>[];
      var succeeded = 0;
      await _pump(
        tester,
        onChangePassword: (current, next) async => calls.add((current, next)),
        onSuccess: () => succeeded++,
      );

      expect(find.text('Change password'), findsOneWidget);

      await tester.tap(find.widgetWithText(ShadButton, 'Update password'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.text('Current password is required'), findsOneWidget);

      await _fillAndUpdate(tester);

      expect(calls, [('old-one', 'new-pass-1')]);
      expect(succeeded, 1);
      expect(find.text('Password updated.'), findsOneWidget);
    });

    testWidgets('Issue 53: a current password the server refuses shows on '
        'that field', (tester) async {
      var succeeded = 0;
      await _pump(
        tester,
        onChangePassword: (_, _) async => throw const ServerException(
          statusCode: 401,
          code: SdkErrorCode.invalidCredentials,
          message: 'raw server text',
        ),
        onSuccess: () => succeeded++,
      );

      await _fillAndUpdate(tester);

      expect(succeeded, 0);
      expect(
        find.descendant(
          of: _field(ChangePasswordFormFields.currentId),
          matching: find.text('Current password is incorrect'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
      // The form takes input again for a retry.
      expect(
        tester
            .widget<ShadInputFormField>(
              _field(ChangePasswordFormFields.currentId),
            )
            .enabled,
        isTrue,
      );
    });

    testWidgets('Issue 53: Cancel calls onCancel', (tester) async {
      var cancelled = 0;
      await _pump(
        tester,
        onChangePassword: (_, _) async {},
        onCancel: () => cancelled++,
      );

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, 1);
    });
  });
}
