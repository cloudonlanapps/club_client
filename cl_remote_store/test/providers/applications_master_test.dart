import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeCapabilities extends Fake implements CapabilitiesSource {
  _FakeCapabilities({required this.applications});

  final bool applications;

  @override
  Future<Capabilities> getCapabilities() async =>
      Capabilities(applications: applications);
}

ApplicationTemplate _template(
  int id, {
  ApplicationStatus status = ApplicationStatus.draft,
  String title = 'Trial',
}) => ApplicationTemplate(
  id: id,
  status: status,
  content: ApplicationContent(title: ApplicationText({'en': title})),
  createdAtUtc: DateTime.utc(2026, 10),
  updatedAtUtc: DateTime.utc(2026, 10),
);

class _FakeApplications extends Fake implements ApplicationSource {
  final Map<int, ApplicationTemplate> stored = {
    1: _template(1),
    2: _template(2, status: ApplicationStatus.saved),
  };
  int lists = 0;
  int labelReads = 0;
  int clauseReads = 0;
  final List<String> calls = [];
  Exception? failWith;

  @override
  Future<PaginatedList<ApplicationTemplate>> listApplications({
    ApplicationStatus? status,
    int offset = 0,
    int limit = 20,
  }) async {
    lists++;
    final items = stored.values.skip(offset).take(limit).toList();
    return PaginatedList(
      items: items,
      total: stored.length,
      limit: limit,
      offset: offset,
    );
  }

  ApplicationTemplate _move(int id, String call, ApplicationStatus to) {
    calls.add('$call $id');
    final failure = failWith;
    if (failure != null) throw failure;
    return stored[id] = stored[id]!.copyWith(status: to);
  }

  @override
  Future<ApplicationTemplate> createApplication(
    ApplicationContent content,
  ) async {
    calls.add('create');
    return stored[9] = ApplicationTemplate(
      id: 9,
      status: ApplicationStatus.draft,
      content: content,
      createdAtUtc: DateTime.utc(2026, 10),
      updatedAtUtc: DateTime.utc(2026, 10),
    );
  }

  @override
  Future<ApplicationTemplate> updateApplication(
    int id,
    ApplicationPatch patch,
  ) async {
    calls.add('update $id ${patch.toMap().keys.join(',')}');
    final failure = failWith;
    if (failure != null) throw failure;
    return stored[id] = stored[id]!.copyWith(
      content: stored[id]!.content.copyWith(title: patch.title),
    );
  }

  @override
  Future<ApplicationTemplate> duplicateApplication(int id) async {
    calls.add('duplicate $id');
    return stored[7] = _template(7);
  }

  @override
  Future<ApplicationTemplate> saveApplication(int id) async =>
      _move(id, 'save', ApplicationStatus.saved);

  @override
  Future<ApplicationTemplate> publishApplication(int id) async =>
      _move(id, 'publish', ApplicationStatus.published);

  @override
  Future<ApplicationTemplate> unpublishApplication(int id) async =>
      _move(id, 'unpublish', ApplicationStatus.saved);

  @override
  Future<ApplicationTemplate> revertApplication(int id) async =>
      _move(id, 'revert', ApplicationStatus.draft);

  @override
  Future<ApplicationTemplate> deleteApplication(int id) async {
    calls.add('delete $id');
    return stored.remove(id)!;
  }

  @override
  Future<List<int>> downloadPreview(int id) async => [1, id];

  @override
  Future<List<int>> downloadOwnForm(int id, {int? category}) async {
    final failure = failWith;
    if (failure != null) throw failure;
    return [2, id, ?category];
  }

  @override
  Future<List<int>> downloadMemberForm(
    int id,
    String username, {
    int? category,
  }) async => [3, id, username.length, ?category];

  @override
  Future<ApplicationLabels> getLabels() async {
    labelReads++;
    return const ApplicationLabels(
      languages: ['en', 'mr'],
      labels: {
        'field.full_name': {'en': 'Full name'},
      },
    );
  }

  @override
  Future<ApplicationClauseLibrary> getClauses() async {
    clauseReads++;
    return const ApplicationClauseLibrary(
      languages: ['en'],
      choices: {},
      clauses: {
        'rule.fee': ApplicationClause(kind: 'rule', text: {'en': 'Fee'}),
      },
    );
  }
}

UserInfo _user({bool admin = false}) => UserInfo(
  username: admin ? 'admin_a' : 'member_a',
  displayName: 'someone',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin),
);

Future<ProviderContainer> _container(
  _FakeApplications applications, {
  bool enabled = true,
  bool admin = true,
  bool signedIn = true,
}) async {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          applications: applications,
          capabilities: _FakeCapabilities(applications: enabled),
        ),
      ),
      currentUserProvider.overrideWith(
        (ref) => signedIn ? _user(admin: admin) : null,
      ),
    ],
  );
  addTearDown(c.dispose);
  await c.read(capabilitiesProvider.future);
  return c;
}

void main() {
  group('Issue 321: applicationsProvider', () {
    test(
      'Issue 321: is null until the server answers, then its flag',
      () async {
        final c = ProviderContainer(
          overrides: [
            secureClientProvider.overrideWith(
              (ref) async => fakeSecureClient(
                capabilities: _FakeCapabilities(applications: true),
              ),
            ),
          ],
        );
        addTearDown(c.dispose);
        expect(c.read(applicationsProvider), isNull);
        await c.read(capabilitiesProvider.future);
        expect(c.read(applicationsProvider), isTrue);
      },
    );
  });

  group('Issue 321: clApplicationsMasterProvider', () {
    test('Issue 321: loads every template by id', () async {
      final source = _FakeApplications();
      final c = await _container(source);
      final map = await c.read(clApplicationsMasterProvider.future);
      expect(map.keys, [1, 2]);
      expect(source.lists, 1);
    });

    test(
      'Issue 321: is empty, with no call, while applications are off',
      () async {
        final source = _FakeApplications();
        final c = await _container(source, enabled: false);
        expect(await c.read(clApplicationsMasterProvider.future), isEmpty);
        expect(source.lists, 0);
      },
    );

    test(
      'Issue 321: is empty, with no call, when no one is signed in',
      () async {
        final source = _FakeApplications();
        final c = await _container(source, signedIn: false);
        expect(await c.read(clApplicationsMasterProvider.future), isEmpty);
        expect(source.lists, 0);
      },
    );

    test(
      'Issue 321: create, duplicate and update fold the answer in',
      () async {
        final source = _FakeApplications();
        final c = await _container(source);
        await c.read(clApplicationsMasterProvider.future);
        final notifier = c.read(clApplicationsMasterProvider.notifier);

        await notifier.createApplication(const ApplicationContent());
        await notifier.duplicateApplication(1);
        await notifier.updateApplication(
          1,
          ApplicationPatch(
            title: () => const ApplicationText({'en': 'X'}),
          ),
        );

        final map = c.read(clApplicationsMasterProvider).value!;
        expect(map.keys, containsAll([1, 2, 7, 9]));
        expect(map[1]!.content.title!.texts, {'en': 'X'});
        expect(source.calls, ['create', 'duplicate 1', 'update 1 title']);
      },
    );

    test('Issue 321: the moves replace the template with the answer', () async {
      final source = _FakeApplications();
      final c = await _container(source);
      await c.read(clApplicationsMasterProvider.future);
      final notifier = c.read(clApplicationsMasterProvider.notifier);

      await notifier.saveApplication(1);
      expect(
        c.read(clApplicationsMasterProvider).value![1]!.status,
        ApplicationStatus.saved,
      );
      await notifier.publishApplication(1);
      await notifier.unpublishApplication(1);
      await notifier.revertApplication(1);
      expect(
        c.read(clApplicationsMasterProvider).value![1]!.status,
        ApplicationStatus.draft,
      );
      expect(source.calls, ['save 1', 'publish 1', 'unpublish 1', 'revert 1']);
    });

    test('Issue 321: delete removes the template', () async {
      final source = _FakeApplications();
      final c = await _container(source);
      await c.read(clApplicationsMasterProvider.future);
      await c.read(clApplicationsMasterProvider.notifier).deleteApplication(2);
      expect(c.read(clApplicationsMasterProvider).value!.keys, [1]);
    });

    test('Issue 321: a refused move is rethrown and changes nothing', () async {
      final source = _FakeApplications()
        ..failWith = const ApplicationIncompleteException(
          message: 'incomplete',
          missing: [
            ApplicationMissingText(field: 'title', languages: ['mr']),
          ],
        );
      final c = await _container(source);
      await c.read(clApplicationsMasterProvider.future);
      await expectLater(
        c.read(clApplicationsMasterProvider.notifier).saveApplication(1),
        throwsA(isA<ApplicationIncompleteException>()),
      );
      expect(
        c.read(clApplicationsMasterProvider).value![1]!.status,
        ApplicationStatus.draft,
      );
      expect(source.lists, 1, reason: 'a 4xx refusal does not reload');
    });

    test('Issue 321: the downloads give the PDF bytes', () async {
      final source = _FakeApplications();
      final c = await _container(source);
      final notifier = c.read(clApplicationsMasterProvider.notifier);
      expect(await notifier.downloadPreview(4), [1, 4]);
      expect(await notifier.downloadOwnForm(4), [2, 4]);
      expect(await notifier.downloadMemberForm(4, 'abc'), [3, 4, 3]);
    });

    test('Issue 343: a download passes on the age category it names', () async {
      final source = _FakeApplications();
      final c = await _container(source);
      final notifier = c.read(clApplicationsMasterProvider.notifier);
      expect(await notifier.downloadOwnForm(4, category: 1), [2, 4, 1]);
      expect(
        await notifier.downloadMemberForm(4, 'abc', category: 0),
        [3, 4, 3, 0],
      );
    });
  });

  group('Issue 321: the label catalogue and clause library', () {
    test('Issue 321: an admin reads both', () async {
      final source = _FakeApplications();
      final c = await _container(source);
      final labels = await c.read(applicationLabelsProvider.future);
      final clauses = await c.read(applicationClausesProvider.future);
      expect(labels.languages, ['en', 'mr']);
      expect(clauses.clauses.keys, ['rule.fee']);
    });

    test('Issue 321: a member reads neither, with no call', () async {
      final source = _FakeApplications();
      final c = await _container(source, admin: false);
      expect(
        await c.read(applicationLabelsProvider.future),
        emptyApplicationLabels,
      );
      expect(
        await c.read(applicationClausesProvider.future),
        emptyApplicationClauses,
      );
      expect(source.labelReads + source.clauseReads, 0);
    });

    test('Issue 321: neither is read while applications are off', () async {
      final source = _FakeApplications();
      final c = await _container(source, enabled: false);
      await c.read(applicationLabelsProvider.future);
      await c.read(applicationClausesProvider.future);
      expect(source.labelReads + source.clauseReads, 0);
    });
  });
}
