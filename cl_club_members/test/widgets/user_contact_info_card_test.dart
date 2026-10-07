import 'package:cl_club_forms/cl_club_forms.dart' show UserContactForm;
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/recording_url_launcher.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _user({
  String username = 'robin',
  String phone = '+10000000001',
  String? emergencyContact,
  bool isAdmin = false,
}) => UserPrivate(
  username: username,
  displayName: 'Robin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: isAdmin),
  email: '$username@example.test',
  phone: phone,
  emergencyContact: emergencyContact,
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

/// Pumps the card for [user] as seen by [viewer] (an admin who is someone
/// else when not given), recording what its buttons would open.
Future<RecordingUrlLauncher> _pump(
  WidgetTester tester, {
  required bool canEdit,
  UserPrivate? user,
  UserPrivate? viewer,
}) async {
  final original = UrlLauncherPlatform.instance;
  final launcher = RecordingUrlLauncher();
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = original);
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          () => _StubAuthNotifier(
            viewer ?? _user(username: 'viewer', isAdmin: true),
          ),
        ),
        defaultCountryCodeProvider.overrideWithValue('91'),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserContactInfoCard(
              user: user ?? _user(),
              canEdit: canEdit,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return launcher;
}

Finder _button(String label) => find.widgetWithText(ShadButton, label);

void main() {
  group("Issue 53: the member's contact card", () {
    testWidgets('Issue 53: shows the contact fields it has, read-only', (
      tester,
    ) async {
      await _pump(tester, canEdit: false);

      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('robin'), findsOneWidget);
      expect(find.text('robin@example.test'), findsOneWidget);
      expect(find.text('+10000000001'), findsOneWidget);
      expect(find.text('Emergency Contact'), findsNothing);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    });

    testWidgets('Issue 53: an editor gets the edit pencil', (tester) async {
      await _pump(tester, canEdit: true);

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });
  });

  group("Issue 32: the member's contact card reaches the member", () {
    testWidgets("Issue 32: on a member's profile the phone has Call and "
        'WhatsApp and the email has Email', (tester) async {
      final launcher = await _pump(tester, canEdit: false);

      await tester.tap(_button('Call'));
      await tester.pumpAndSettle();
      await tester.tap(_button('WhatsApp'));
      await tester.pumpAndSettle();
      await tester.tap(_button('Email'));
      await tester.pumpAndSettle();

      expect(launcher.launched, [
        'tel:+10000000001',
        'https://wa.me/10000000001',
        'mailto:robin@example.test',
      ]);
    });

    testWidgets('Issue 32: for a stored bare number WhatsApp opens wa.me '
        'with the default country code in front', (tester) async {
      final launcher = await _pump(
        tester,
        canEdit: false,
        user: _user(phone: '9876543210'),
      );

      await tester.tap(_button('WhatsApp'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://wa.me/919876543210']);
    });

    testWidgets('Issue 32: the emergency contact shows its name and '
        'relation as text and its number with Call only', (tester) async {
      final launcher = await _pump(
        tester,
        canEdit: false,
        viewer: _user(),
        user: _user(emergencyContact: 'Asha Rao (Parent) : +91 98765 43210'),
      );

      expect(find.text('Emergency Contact'), findsOneWidget);
      expect(find.text('Asha Rao (Parent)'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Asha Rao (Parent) : +91 98765 43210'), findsNothing);
      expect(_button('WhatsApp'), findsNothing);

      await tester.tap(_button('Call'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['tel:+919876543210']);
    });

    testWidgets('Issue 32: an emergency contact that holds no number stays '
        'plain text', (tester) async {
      for (final stored in ['Ask at the front desk', 'Asha : after 6 pm']) {
        await _pump(
          tester,
          canEdit: false,
          viewer: _user(),
          user: _user(emergencyContact: stored),
        );

        expect(find.text(stored), findsOneWidget);
        expect(find.byType(ShadButton), findsNothing);
      }
    });

    testWidgets('Issue 32: on their own profile a member has no buttons on '
        'their phone and email, and the emergency contact keeps Call', (
      tester,
    ) async {
      final launcher = await _pump(
        tester,
        canEdit: true,
        viewer: _user(),
        user: _user(emergencyContact: 'Asha Rao (Parent) : 9876543210'),
      );

      expect(find.text('robin@example.test'), findsOneWidget);
      expect(find.text('+10000000001'), findsOneWidget);
      expect(_button('WhatsApp'), findsNothing);
      expect(_button('Email'), findsNothing);
      expect(_button('Call'), findsOneWidget);

      await tester.tap(_button('Call'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['tel:9876543210']);
    });

    testWidgets('Issue 32: the inline editor carries no contact buttons', (
      tester,
    ) async {
      await _pump(
        tester,
        canEdit: true,
        user: _user(emergencyContact: 'Asha Rao (Parent) : 9876543210'),
      );
      expect(_button('Call'), findsNWidgets(2));

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      expect(find.byType(UserContactForm), findsOneWidget);
      expect(_button('Call'), findsNothing);
      expect(_button('WhatsApp'), findsNothing);
      expect(_button('Email'), findsNothing);
    });
  });
}
