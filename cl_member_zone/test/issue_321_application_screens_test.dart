import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

/// A PDF action that does nothing.
final _pdfAction = PdfAction(
  label: 'Download',
  icon: LucideIcons.download,
  run: (_, _) async {},
);

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

class _Applications extends ClApplicationsMasterNotifier {
  @override
  Future<Map<int, ApplicationTemplate>> build() async => {
    3: ApplicationTemplate(
      id: 3,
      status: ApplicationStatus.draft,
      content: const ApplicationContent(),
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    ),
  };
}

class _Docs extends ClIdentityDocsMasterNotifier {
  @override
  Future<List<MediaLink>> build(String arg) async => const [];
}

UserPrivate _user({bool admin = false}) => UserPrivate(
  username: admin ? 'admin_a' : 'member_a',
  displayName: 'someone',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin),
  createdAtUtc: DateTime.utc(2024),
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required UserPrivate viewer,
  bool? applications = true,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        applicationsProvider.overrideWithValue(applications),
        clApplicationsMasterProvider.overrideWith(_Applications.new),
        clIdentityDocsMasterProvider.overrideWith(_Docs.new),
        applicationLabelsProvider.overrideWith(
          (ref) async => emptyApplicationLabels,
        ),
        applicationClausesProvider.overrideWith(
          (ref) async => emptyApplicationClauses,
        ),
      ],
      child: ShadApp(
        home: Scaffold(body: ShadToaster(child: screen)),
      ),
    ),
  );
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

const _denied = 'Access Denied';

void main() {
  Widget list() => ApplicationsScreen(onOpen: (_) {}, onHome: () {});
  Widget mine() => MyApplicationsScreen(
    pdfAction: _pdfAction,
    onOpenProfile: () {},
    onHome: () {},
  );
  Widget editor() => ApplicationScreen(
    applicationId: 3,
    onBack: () {},
    onDeleted: () {},
    pdfAction: _pdfAction,
    onHome: () {},
  );

  group('Issue 321: the Applications screens gate', () {
    testWidgets('Issue 380: any member opens their own list', (
      tester,
    ) async {
      await _pump(tester, mine(), viewer: _user());
      expect(find.byType(MyApplicationsView), findsOneWidget);
    });

    testWidgets('Issue 380: an admin opens their own list too', (
      tester,
    ) async {
      await _pump(tester, mine(), viewer: _user(admin: true));
      expect(find.byType(MyApplicationsView), findsOneWidget);
    });

    testWidgets('Issue 380: a member is refused the management list', (
      tester,
    ) async {
      await _pump(tester, list(), viewer: _user());
      expect(find.text(_denied), findsOneWidget);
      expect(find.byType(ApplicationsView), findsNothing);
    });

    testWidgets('Issue 380: an admin opens the management list', (
      tester,
    ) async {
      await _pump(tester, list(), viewer: _user(admin: true));
      expect(find.byType(ApplicationsView), findsOneWidget);
    });

    testWidgets('Issue 321: a member is refused the editor', (tester) async {
      await _pump(tester, editor(), viewer: _user());
      expect(find.text(_denied), findsOneWidget);
      expect(find.byType(ApplicationView), findsNothing);
    });

    testWidgets('Issue 321: an admin opens the editor', (tester) async {
      await _pump(tester, editor(), viewer: _user(admin: true));
      expect(find.byType(ApplicationView), findsOneWidget);
    });

    testWidgets('Issue 321: with applications off all three refuse', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        Column(
          children: [
            Expanded(child: mine()),
            Expanded(child: list()),
            Expanded(child: editor()),
          ],
        ),
        viewer: _user(admin: true),
        applications: false,
      );
      expect(find.text(_denied), findsNWidgets(3));
    });

    testWidgets('Issue 321: while the capability is unknown it waits', (
      tester,
    ) async {
      await _pump(
        tester,
        mine(),
        viewer: _user(),
        applications: null,
        settle: false,
      );
      expect(find.byType(ShadProgress), findsOneWidget);
      expect(find.text(_denied), findsNothing);
    });
  });
}
