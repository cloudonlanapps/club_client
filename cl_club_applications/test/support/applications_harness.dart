import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'application_samples.dart';

/// The applications master with no server: it holds [initial], records
/// every call in [calls] and, while [failWith] is set, throws it from every
/// write and download. While [fitting] names more than one age category, a
/// member's form downloaded without a category is refused with them, as
/// the server does (club_client#337).
class FakeApplicationsMaster extends ClApplicationsMasterNotifier {
  FakeApplicationsMaster(this.initial);

  /// What the master loads.
  final Map<int, ApplicationTemplate> initial;

  /// Every call, in order: `save 5`, `update 5 title,languages`, ….
  final List<String> calls = [];

  /// The failure every write and download throws while set.
  Exception? failWith;

  /// The age categories the member fits; null for one or none.
  List<int>? fitting;

  @override
  Future<Map<int, ApplicationTemplate>> build() async => initial;

  ApplicationTemplate _write(String call, ApplicationTemplate next) {
    calls.add(call);
    final failure = failWith;
    if (failure != null) throw failure;
    replaceLocally(next);
    return next;
  }

  ApplicationTemplate _held(int id) => state.requireValue[id]!;

  ApplicationTemplate _moved(int id, ApplicationStatus to) =>
      _held(id).copyWith(status: to);

  @override
  Future<ApplicationTemplate> createApplication(
    ApplicationContent content,
  ) async => _write(
    'create ${content.title?.texts}',
    ApplicationSamples.template(id: 90, content: content),
  );

  @override
  Future<ApplicationTemplate> updateApplication(
    int id,
    ApplicationPatch patch,
  ) async => _write('update $id ${patch.toMap().keys.join(',')}', _held(id));

  @override
  Future<ApplicationTemplate> duplicateApplication(int id) async =>
      _write('duplicate $id', ApplicationSamples.template(id: 91));

  @override
  Future<ApplicationTemplate> saveApplication(int id) async =>
      _write('save $id', _moved(id, ApplicationStatus.saved));

  @override
  Future<ApplicationTemplate> publishApplication(int id) async =>
      _write('publish $id', _moved(id, ApplicationStatus.published));

  @override
  Future<ApplicationTemplate> unpublishApplication(int id) async =>
      _write('unpublish $id', _moved(id, ApplicationStatus.saved));

  @override
  Future<ApplicationTemplate> revertApplication(int id) async =>
      _write('revert $id', _moved(id, ApplicationStatus.draft));

  @override
  Future<void> deleteApplication(int id) async {
    calls.add('delete $id');
    final failure = failWith;
    if (failure != null) throw failure;
  }

  Future<Uint8List> _pdf(String call) async {
    calls.add(call);
    final failure = failWith;
    if (failure != null) throw failure;
    return Uint8List.fromList([37, 80, 68, 70]);
  }

  @override
  Future<Uint8List> downloadPreview(int id) => _pdf('preview $id');

  Future<Uint8List> _form(String call, int? category) async {
    final several = fitting;
    if (category == null && several != null && several.length > 1) {
      calls.add(call);
      throw ApplicationCategoryRequiredException(
        message: 'raw server words',
        categories: several,
      );
    }
    return _pdf(category == null ? call : '$call category $category');
  }

  @override
  Future<Uint8List> downloadOwnForm(int id, {int? category}) =>
      _form('own $id', category);

  @override
  Future<Uint8List> downloadMemberForm(
    int id,
    String username, {
    int? category,
  }) => _form('member $id $username', category);
}

/// A member's identity documents with no server.
class FakeIdentityDocs extends ClIdentityDocsMasterNotifier {
  FakeIdentityDocs(this.links);

  /// The documents.
  final List<MediaLink> links;

  @override
  Future<List<MediaLink>> build(String arg) async => links;
}

/// One identity document.
MediaLink identityDocument() => MediaLink(
  tag: kIdentityDocumentTag,
  media: const MediaRef(
    uuid: 'doc-1',
    mimeType: 'image/png',
    filename: 'doc-1.png',
  ),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// A signed-in user; an admin when [admin].
UserPrivate applicationsUser({bool admin = false}) => UserPrivate(
  username: admin ? 'admin_a' : 'member_a',
  displayName: admin ? 'Admin A' : 'Member A',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin),
  createdAtUtc: DateTime.utc(2024),
);

/// Mounts [child] with the applications on (or off, [enabled]), the master
/// [master], the label catalogue and clause library of the samples,
/// [documents] as every member's identity documents, [currentUser] as the
/// signed-in member (by default [applicationsUser], whose profile is blank)
/// and the extended profile on or off ([extendedProfile]).
Future<void> pumpApplications(
  WidgetTester tester,
  Widget child, {
  required FakeApplicationsMaster master,
  bool enabled = true,
  List<MediaLink> documents = const [],
  UserPrivate? currentUser,
  bool extendedProfile = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        applicationsProvider.overrideWithValue(enabled),
        currentUserProvider.overrideWithValue(
          currentUser ?? applicationsUser(),
        ),
        extendedProfileProvider.overrideWithValue(extendedProfile),
        clApplicationsMasterProvider.overrideWith(() => master),
        applicationLabelsProvider.overrideWith(
          (ref) async => ApplicationSamples.labels,
        ),
        applicationClausesProvider.overrideWith(
          (ref) async => ApplicationSamples.clauses,
        ),
        clIdentityDocsMasterProvider.overrideWith(
          () => FakeIdentityDocs(documents),
        ),
      ],
      child: ShadApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}
