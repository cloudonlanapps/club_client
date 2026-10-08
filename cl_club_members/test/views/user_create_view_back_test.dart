import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserForm, UserFormFields, UserFormState;
import 'package:cl_club_members/src/views/user_create_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show
        AuthNotifier,
        UsernameAvailability,
        authStateProvider,
        usernameAvailabilityProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClUsersMasterNotifier,
        clUsersMasterProvider,
        defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog, DiscardChangesPrompt;

class _Admin extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'admin',
    displayName: 'Admin',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    email: 'admin@example.test',
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );
}

/// Counts the creates the view sends on [host]; each waits for [hold] when
/// there is one.
class _Users extends ClUsersMasterNotifier {
  _Users(this.host, this.hold);

  final _Host host;
  final Completer<void>? hold;

  @override
  Future<Map<String, UserInfo>> build() async => {};

  @override
  Future<UserPrivate> createUser({
    required String username,
    required String email,
    required String passwordHash,
    required String phone,
    required DateTime dateOfBirthUtc,
    required Gender gender,
    String? firstName,
    String? middleName,
    String? lastName,
    String? bio,
    String? achievements,
    String? emergencyContact,
    String? medicalNotes,
    Address? address,
  }) async {
    host.sent++;
    await hold?.future;
    return UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: const UserRoles(),
      email: email,
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );
  }
}

/// What the view told its host, and how many creates were sent.
class _Host {
  final List<String> log = [];
  int sent = 0;
}

/// Presses the system back button.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Finder _input(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// Fills the form, the username confirmed available, and taps Create user.
Future<void> _fillAndCreate(WidgetTester tester) async {
  await tester.enterText(_input(UserFormFields.usernameId), 'robin');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check availability'));
  await tester.pumpAndSettle();
  await tester.enterText(_input(UserFormFields.firstNameId), 'Robin');
  await tester.enterText(_input(UserFormFields.phoneId), '9876543210');
  await tester.enterText(_input(UserFormFields.emailId), 'robin@example.test');
  tester
      .state<UserFormState>(find.byType(UserForm))
      .formKey
      .currentState!
      .setValue({
        UserFormFields.genderId: SignupGender.female,
        UserFormFields.dateOfBirthUtcId: DateTime(2010, 3, 4),
      });
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ShadButton, 'Create user'));
  await tester.pump();
}

/// Pushes the view over a first page, so a system back has a route to pop.
/// The host leaves by popping that route, as the app's router does. With
/// [hold], a create waits for it.
Future<_Host> _push(WidgetTester tester, {Completer<void>? hold}) async {
  tester.view.physicalSize = const Size(1024, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = _Host();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_Admin.new),
        clUsersMasterProvider.overrideWith(() => _Users(host, hold)),
        usernameAvailabilityProvider.overrideWith(
          (ref, username) async => UsernameAvailability.available,
        ),
        defaultCountryCodeProvider.overrideWithValue('91'),
      ],
      child: ShadApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ShadButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (routeContext) => Scaffold(
                    body: UserCreateView(
                      onCreated: () => host.log.add('created'),
                      onCancel: () {
                        host.log.add('cancelled');
                        Navigator.of(routeContext).pop();
                      },
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  group('Issue 98: system back on Create user', () {
    testWidgets(
      'Issue 98: Create user: system back after typing asks to discard, '
      'and stays until Discard is chosen',
      (tester) async {
        final host = await _push(tester);
        await tester.enterText(_input(UserFormFields.firstNameId), 'Robin');
        await tester.pump();

        await _systemBack(tester);

        expect(find.byType(ConfirmDialog), findsOneWidget);
        expect(find.text(DiscardChangesPrompt.title), findsOneWidget);
        expect(find.text(DiscardChangesPrompt.message), findsOneWidget);
        expect(find.byType(UserCreateView), findsOneWidget);
        expect(host.log, isEmpty);

        await tester.tap(find.text(DiscardChangesPrompt.keepEditingLabel));
        await tester.pumpAndSettle();

        expect(find.byType(UserCreateView), findsOneWidget);
        expect(host.log, isEmpty);

        await _systemBack(tester);
        await tester.tap(find.text(DiscardChangesPrompt.discardLabel));
        await tester.pumpAndSettle();

        expect(host.log, ['cancelled']);
        expect(find.byType(UserCreateView), findsNothing);
      },
    );

    testWidgets(
      'Issue 98: Create user: system back on an untouched form leaves '
      'at once',
      (tester) async {
        final host = await _push(tester);

        await _systemBack(tester);

        expect(find.byType(ConfirmDialog), findsNothing);
        expect(host.log, ['cancelled']);
        expect(find.byType(UserCreateView), findsNothing);
      },
    );

    testWidgets(
      'Issue 98: Create user: nothing leaves on system back while the '
      'save is in flight',
      (tester) async {
        final answer = Completer<void>();
        final host = await _push(tester, hold: answer);
        await _fillAndCreate(tester);
        expect(host.sent, 1);

        await _systemBack(tester);

        expect(find.byType(ConfirmDialog), findsNothing);
        expect(find.byType(UserCreateView), findsOneWidget);
        expect(host.log, isEmpty);

        answer.complete();
        await tester.pumpAndSettle();

        expect(host.log, ['created']);
      },
    );

    testWidgets('Issue 98: Create user: system back asks once anything was '
        'typed, though the username is not confirmed', (tester) async {
      final host = await _push(tester);
      await tester.enterText(_input(UserFormFields.usernameId), 'robin');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ShadButton>(find.widgetWithText(ShadButton, 'Create user'))
            .onPressed,
        isNull,
        reason: 'the username is not confirmed',
      );

      await _systemBack(tester);

      expect(find.text(DiscardChangesPrompt.title), findsOneWidget);
      expect(find.byType(UserCreateView), findsOneWidget);
      expect(host.log, isEmpty);
    });
  });
}
