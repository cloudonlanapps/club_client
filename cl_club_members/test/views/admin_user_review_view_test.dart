import 'package:cl_club_members/cl_club_members.dart' show AdminUserReviewView;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show AdminUserReviewForm;

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  _StubUsersMasterNotifier(this._users);
  final Map<String, UserInfo> _users;

  String? lastApproved;
  String? lastApprovedReason;
  String? lastReconsidered;
  String? lastReconsiderReason;
  String? lastBlocked;
  String? lastBlockReason;

  @override
  Future<Map<String, UserInfo>> build() async => _users;

  @override
  Future<UserInfo> approveUser(
    String username, {
    String? resolutionReason,
  }) async {
    lastApproved = username;
    lastApprovedReason = resolutionReason;
    return _users[username]!.copyWith(status: UserStatus.active);
  }

  @override
  Future<UserInfo> reconsiderUser(String username, String reason) async {
    lastReconsidered = username;
    lastReconsiderReason = reason;
    return _users[username]!.copyWith(status: UserStatus.registered);
  }

  @override
  Future<UserInfo> blockUser(
    String username, {
    String? resolutionReason,
  }) async {
    lastBlocked = username;
    lastBlockReason = resolutionReason;
    return _users[username]!.copyWith(status: UserStatus.blocked);
  }
}

class _StubIdentityDocsNotifier extends ClIdentityDocsMasterNotifier {
  _StubIdentityDocsNotifier(this._byUsername, [this._buildCounts]);
  final Map<String, List<MediaLink>> _byUsername;

  /// Optional external counter — if supplied, increments per build() call
  /// per username. Lets tests assert that `ref.invalidate(...)` actually
  /// refetched (issue #684).
  final Map<String, int>? _buildCounts;

  @override
  Future<List<MediaLink>> build(String username) async {
    final counts = _buildCounts;
    if (counts != null) {
      counts[username] = (counts[username] ?? 0) + 1;
    }
    return _byUsername[username] ?? const [];
  }
}

UserPrivate _admin() => UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

UserInfo _pending(String username) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

UserInfo _registered(String username) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.registered,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

UserPrivate _pendingPrivate(String username) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  dateOfBirthUtc: DateTime.utc(2000, 6, 15),
  gender: Gender.male,
);

MediaLink _docLink(String uuid) {
  final now = DateTime.utc(2024);
  return MediaLink(
    tag: 'identity_document',
    media: MediaRef(
      uuid: uuid,
      mimeType: 'image/jpeg',
      filename: '$uuid-doc.jpg',
    ),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

Widget _wrap({
  required _StubUsersMasterNotifier usersStub,
  required String username,
  VoidCallback? onBack,
  Map<String, UserPrivate> privates = const {},
  Map<String, List<MediaLink>> documents = const {},
  Map<String, int>? identityDocsBuildCounts,
  Capabilities capabilities = const Capabilities(),
  ValueListenable<bool>? visible,
}) {
  final overrides = <Override>[
    serverConfigProvider.overrideWithValue(
      const ServerConfig(baseUrl: 'https://api.test.example.com/v1'),
    ),
    capabilitiesProvider.overrideWith((ref) async => capabilities),
    clUsersMasterProvider.overrideWith(() => usersStub),
    for (final entry in privates.entries)
      clUserPrivateProvider(entry.key).overrideWith((ref) async => entry.value),
    clIdentityDocsMasterProvider.overrideWith(
      () => _StubIdentityDocsNotifier(documents, identityDocsBuildCounts),
    ),
  ];
  return ProviderScope(
    overrides: overrides,
    child: ShadApp(
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: visible ?? ValueNotifier(true),
          builder: (context, shown, _) => shown
              ? AdminUserReviewView(
                  currentUser: _admin(),
                  username: username,
                  onBack: onBack ?? () {},
                )
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 380: non-pending or missing user shows the "nothing to review" '
    'state',
    (tester) async {
      final stub = _StubUsersMasterNotifier(const {});
      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'ghost',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing to review'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    },
  );

  testWidgets(
    'Issue 380: pending user mounts the form with three actions',
    (tester) async {
      final pending = _pending('alpha');
      final stub = _StubUsersMasterNotifier({pending.username: pending});

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: pending.username,
          privates: {pending.username: _pendingPrivate(pending.username)},
          documents: {
            pending.username: [_docLink('doc1')],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 503: pending user shows DOB DD/MM/YYYY and gender as Boy/Girl/Other/Unspecified',
    (tester) async {
      final pending = _pending('alpha');
      final stub = _StubUsersMasterNotifier({pending.username: pending});

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: pending.username,
          privates: {pending.username: _pendingPrivate(pending.username)},
          documents: {
            pending.username: [_docLink('doc1')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Issue 503 / 507: Gender.male -> 'Boy'; dob 2000-06-15 -> '15/06/2000';
      // rendered as a single combined h4 line joined by " · ".
      expect(find.text('DOB: 15/06/2000 · Boy'), findsOneWidget);
      // Old form-style labels are gone.
      expect(find.text('Date of birth'), findsNothing);
      expect(find.text('Gender'), findsNothing);
    },
  );

  testWidgets(
    'Issue 507: on mobile, search input is collapsed to a search icon; '
    'tapping the icon reveals the input and the suggestion body with '
    'a "type to search" guidance message',
    (tester) async {
      // Phone-sized surface (< 600 logical pixels wide, but wide enough
      // that the action row buttons fit horizontally).
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(560, 900);
      addTearDown(tester.view.reset);

      final pending = _pending('alpha');
      final stub = _StubUsersMasterNotifier({pending.username: pending});

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: pending.username,
          privates: {pending.username: _pendingPrivate(pending.username)},
          documents: {
            pending.username: [_docLink('doc1')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Collapsed state: no inline search input, just a search icon.
      expect(find.widgetWithText(ShadInput, 'Search users…'), findsNothing);
      final searchIcon = find.widgetWithIcon(IconButton, Icons.search);
      expect(searchIcon, findsOneWidget);

      // Tapping the icon expands the input + suggestion surface even
      // though the query is still empty — the pager is no longer
      // visible behind it.
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ShadInput, 'Search users…'), findsOneWidget);
      expect(find.text('Type to search by name or @handle'), findsOneWidget);
      expect(
        find.text('Start typing a name or @handle to find a pending user.'),
        findsOneWidget,
      );
      // Pager UI is hidden while the search surface is up.
      expect(find.text('1 / 1'), findsNothing);
    },
  );

  testWidgets(
    'Issue 380: tapping Approve invokes approveUser and calls onBack',
    (tester) async {
      final pending = _pending('alpha');
      final stub = _StubUsersMasterNotifier({pending.username: pending});
      var backCount = 0;

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: pending.username,
          onBack: () => backCount++,
          privates: {pending.username: _pendingPrivate(pending.username)},
          documents: {
            pending.username: [_docLink('doc1')],
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(stub.lastApproved, 'alpha');
      expect(stub.lastApprovedReason, isNull);
      expect(backCount, 1);
    },
  );

  testWidgets(
    'Issue 684: AdminReviewPage invalidates clIdentityDocsMasterProvider '
    "on mount so the admin sees the user's latest identity docs "
    '(not a cached set from a previous review session)',
    (tester) async {
      final pending = _pending('alpha');
      final stub = _StubUsersMasterNotifier({pending.username: pending});
      final buildCounts = <String, int>{};
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: pending.username,
          privates: {pending.username: _pendingPrivate(pending.username)},
          documents: {
            pending.username: [_docLink('doc1')],
          },
          identityDocsBuildCounts: buildCounts,
          visible: visible,
        ),
      );
      await tester.pumpAndSettle();
      final firstOpen = buildCounts[pending.username] ?? 0;
      expect(firstOpen, greaterThanOrEqualTo(1));

      // Close the review and open it again in the same provider container:
      // before the fix the cached documents from the first open were reused.
      // AdminReviewPage invalidates the provider in initState, so the second
      // open fetches again. (Since #84 the documents load only once the
      // capabilities arrive, so the first open builds once, after the
      // invalidate; counting builds within one open no longer shows the
      // refresh.)
      visible.value = false;
      await tester.pumpAndSettle();
      visible.value = true;
      await tester.pumpAndSettle();

      expect(
        buildCounts[pending.username],
        greaterThan(firstOpen),
        reason:
            'AdminReviewPage.initState should invalidate the '
            'identity-docs provider, triggering a refetch on every mount.',
      );
    },
  );

  testWidgets(
    'Issue 680: registered users are excluded from the review swipe '
    '(reject → user leaves slot)',
    (tester) async {
      // alpha is still awaiting admin action (pending).
      // bravo was previously "rejected" — server transitioned them to
      // `registered` and they are now waiting on the user to resubmit.
      // bravo must NOT appear in the admin review swipe.
      final alpha = _pending('alpha');
      final bravo = _registered('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: alpha.username,
          privates: {alpha.username: _pendingPrivate(alpha.username)},
          documents: {
            alpha.username: [_docLink('doc-a')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Only alpha should be in the swipe — counter reads "1 / 1", not
      // "1 / 2". Bravo is filtered out by `_isPending`.
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.text('1 / 2'), findsNothing);
    },
  );

  testWidgets(
    'Issue 470: PageView lists all pending users with a counter',
    (tester) async {
      final alpha = _pending('alpha');
      final bravo = _pending('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'alpha',
          privates: {
            'alpha': _pendingPrivate('alpha'),
            'bravo': _pendingPrivate('bravo'),
          },
          documents: {
            'alpha': [_docLink('doc-a')],
            'bravo': [_docLink('doc-b')],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
    },
  );

  testWidgets(
    "Issue 470: ?username=X opens at that user's page",
    (tester) async {
      final alpha = _pending('alpha');
      final bravo = _pending('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'bravo',
          privates: {
            'alpha': _pendingPrivate('alpha'),
            'bravo': _pendingPrivate('bravo'),
          },
          documents: {
            'alpha': [_docLink('doc-a')],
            'bravo': [_docLink('doc-b')],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 470: selection on user A does not bleed onto user B after swipe',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final alpha = _pending('alpha');
      final bravo = _pending('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'alpha',
          privates: {
            'alpha': _pendingPrivate('alpha'),
            'bravo': _pendingPrivate('bravo'),
          },
          documents: {
            'alpha': [_docLink('doc-a')],
            'bravo': [_docLink('doc-b')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // On user A: tap Reject — the reason dialog opens.
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Reject'), findsOneWidget);

      // Cancel the dialog and swipe to user B by tapping Next. User B
      // must show a fresh page (no reason dialog, no in-flight state).
      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Confirm Reject'), findsNothing);
      expect(find.text('Confirm Approve'), findsNothing);
      expect(find.text('Confirm Block'), findsNothing);
    },
  );

  testWidgets(
    'Issue 470: typed reason on user A does not appear on user B',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final alpha = _pending('alpha');
      final bravo = _pending('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'alpha',
          privates: {
            'alpha': _pendingPrivate('alpha'),
            'bravo': _pendingPrivate('bravo'),
          },
          documents: {
            'alpha': [_docLink('doc-a')],
            'bravo': [_docLink('doc-b')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // Issue 507: reason input lives in a modal dialog now. Open the
      // dialog on user A, type a draft, cancel it, then swipe to user B
      // and reopen the dialog — the new dialog must start empty.
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      const secret = 'reason-only-on-alpha';
      // The first ShadInput on screen is the pager-level search box;
      // the second is the reason field inside the dialog.
      await tester.enterText(find.byType(ShadInput).at(1), secret);
      await tester.pumpAndSettle();
      expect(find.text(secret), findsOneWidget);

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text(secret), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      // Fresh dialog on user B — the draft from user A is not carried.
      expect(find.text(secret), findsNothing);
    },
  );

  testWidgets(
    'Issue 470: search box shows suggestions; selecting one jumps the pager',
    (tester) async {
      final alpha = _pending('alpha');
      final bravo = _pending('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'alpha',
          privates: {
            'alpha': _pendingPrivate('alpha'),
            'bravo': _pendingPrivate('bravo'),
          },
          documents: {
            'alpha': [_docLink('doc-a')],
            'bravo': [_docLink('doc-b')],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(ShadInput, 'Search users…'),
        'brav',
      );
      await tester.pumpAndSettle();

      // Body has swapped: pager counter is gone, results header + bravo row
      // are visible. Tapping the row clears the search and jumps the pager.
      expect(find.text('1 / 2'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('@bravo'), findsOneWidget);

      await tester.tap(find.text('@bravo'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 470: action on multi-user list does not call onBack',
    (tester) async {
      final alpha = _pending('alpha');
      final bravo = _pending('bravo');
      final stub = _StubUsersMasterNotifier({
        alpha.username: alpha,
        bravo.username: bravo,
      });
      var backCount = 0;

      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'alpha',
          onBack: () => backCount++,
          privates: {
            'alpha': _pendingPrivate('alpha'),
            'bravo': _pendingPrivate('bravo'),
          },
          documents: {
            'alpha': [_docLink('doc-a')],
            'bravo': [_docLink('doc-b')],
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(stub.lastApproved, 'alpha');
      expect(backCount, 0);
    },
  );

  group('Issue 84: identity documents follow the server', () {
    testWidgets('off: the review neither fetches nor shows documents', (
      tester,
    ) async {
      final builds = <String, int>{};
      final stub = _StubUsersMasterNotifier({'newbie': _pending('newbie')});
      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'newbie',
          privates: {'newbie': _pendingPrivate('newbie')},
          identityDocsBuildCounts: builds,
          capabilities: const Capabilities(identityVerification: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(builds, isEmpty);
      expect(find.text('No documents on file.'), findsNothing);
      expect(find.text('Approve'), findsOneWidget);
    });

    testWidgets('on: the documents section is shown', (tester) async {
      final builds = <String, int>{};
      final stub = _StubUsersMasterNotifier({'newbie': _pending('newbie')});
      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'newbie',
          privates: {'newbie': _pendingPrivate('newbie')},
          identityDocsBuildCounts: builds,
        ),
      );
      await tester.pumpAndSettle();

      expect(builds['newbie'], greaterThanOrEqualTo(1));
      expect(find.text('No documents on file.'), findsOneWidget);
    });
  });

  testWidgets(
    'Issue 90: a document that fails to load is labelled with its file name',
    (tester) async {
      final stub = _StubUsersMasterNotifier({'newbie': _pending('newbie')});
      await tester.pumpWidget(
        _wrap(
          usersStub: stub,
          username: 'newbie',
          privates: {'newbie': _pendingPrivate('newbie')},
          documents: {
            'newbie': [_docLink('doc1')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // The slot carries the stored name, which the thumbnail's error
      // placeholder shows instead of the generic "Image".
      final form = tester.widget<AdminUserReviewForm>(
        find.byType(AdminUserReviewForm),
      );
      expect(form.data.documents.single.fileName, 'doc1-doc.jpg');
    },
  );
}
