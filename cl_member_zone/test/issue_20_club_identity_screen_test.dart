import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({bool superAdmin = false}) => UserPrivate(
  username: 'u1',
  displayName: 'Test User',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._u);
  final UserPrivate? _u;
  @override
  Future<UserPrivate?> build() async => _u;
}

class _StubClubIdentity extends ClClubIdentityMasterNotifier {
  @override
  Future<ClubIdentity> build() async => const ClubIdentity(name: 'Stub Club');
}

class _StubProfileOptions extends ProfileOptionsNotifier {
  @override
  Future<ProfileOptions> build() async => const ProfileOptions(
    positions: [],
    languages: [ProfileLanguage(code: 'en', name: 'English')],
  );
}

class _StubLibrary extends ClApplicationLibraryMasterNotifier {
  @override
  Future<Map<int, ApplicationLibraryText>> build() async => const {};
}

class _StubLabels extends ApplicationLabelsNotifier {
  @override
  Future<ApplicationLabels> build() async => const ApplicationLabels(
    languages: ['en', 'mr'],
    labels: {
      'field.full_name': {'en': 'Full name'},
    },
  );
}

/// The screen for [user]; with [applications] and [extendedProfile] given,
/// the server's capabilities say so and the Profile options and the
/// Library read stubs.
Widget _wrap(
  UserPrivate user, {
  bool? applications,
  bool extendedProfile = false,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuth(user)),
    clClubIdentityMasterProvider.overrideWith(_StubClubIdentity.new),
    if (applications != null) ...[
      capabilitiesProvider.overrideWith(
        (ref) async => Capabilities(
          applications: applications,
          extendedProfile: extendedProfile,
        ),
      ),
      profileOptionsProvider.overrideWith(_StubProfileOptions.new),
      clApplicationLibraryMasterProvider.overrideWith(_StubLibrary.new),
      applicationLabelsProvider.overrideWith(_StubLabels.new),
    ],
  ],
  child: ShadApp(
    home: Scaffold(body: ClubIdentityScreen(onHome: () {})),
  ),
);

const Key _library = ValueKey('application.library');
const Key _labels = ValueKey('application.labels');
const Key _profileOptions = ValueKey('clubIdentity.section.profileOptions');

void main() {
  group('Issue 20: ClubIdentityScreen gating', () {
    testWidgets('Issue 20: an admin who is not super-admin is denied', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user()));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('Stub Club'), findsNothing);
    });

    testWidgets('Issue 20: a super-admin sees the club details', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_user(superAdmin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsNothing);
      expect(find.text('Club details'), findsOneWidget);
      expect(find.text('Stub Club'), findsOneWidget);
    });
  });

  group('Issue 399: the Library card on Club details', () {
    testWidgets('Issue 399: shows after Profile options while applications '
        'are on', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(superAdmin: true),
          applications: true,
          extendedProfile: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_profileOptions), findsOneWidget);
      expect(find.byKey(_library), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(_library)).dy,
        greaterThan(tester.getBottomLeft(find.byKey(_profileOptions)).dy),
      );
      expect(
        find.descendant(
          of: find.byKey(_library),
          matching: find.widgetWithText(ShadButton, 'Add text'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 399: shows nothing while applications are off', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(superAdmin: true),
          applications: false,
          extendedProfile: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_profileOptions), findsOneWidget);
      expect(find.byKey(_library), findsNothing);
      expect(find.text('Add text'), findsNothing);
    });
  });

  group('Issue 396: the Labels card on Club details', () {
    testWidgets('Issue 396: shows after the Library card while applications '
        'are on, a blank translation Required', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(superAdmin: true),
          applications: true,
          extendedProfile: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_labels), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(_labels)).dy,
        greaterThan(tester.getBottomLeft(find.byKey(_library)).dy),
      );
      expect(
        find.descendant(
          of: find.byKey(_labels),
          matching: find.text('Required'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 396: shows nothing while applications are off', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          _user(superAdmin: true),
          applications: false,
          extendedProfile: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_labels), findsNothing);
    });
  });
}
