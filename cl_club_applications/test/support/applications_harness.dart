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

  /// The patch of the last update.
  ApplicationPatch? lastPatch;

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
  ) async {
    lastPatch = patch;
    return _write('update $id ${patch.toMap().keys.join(',')}', _held(id));
  }

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

  @override
  Future<Uint8List> downloadBlankForm(int id) => _pdf('blank $id');

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

/// The club's library of texts with no server (club_client#389): it holds
/// [initial], records every call in [calls] and, while [failWith] is set,
/// throws it from every write.
class FakeApplicationLibraryMaster extends ClApplicationLibraryMasterNotifier {
  FakeApplicationLibraryMaster([this.initial = const {}]);

  /// What the master loads.
  final Map<int, ApplicationLibraryText> initial;

  /// Every call, in order: `create selection Name`, `update 7 kind,name`, ….
  final List<String> calls = [];

  /// The failure every write throws while set.
  Exception? failWith;

  /// The input of the last create.
  ApplicationLibraryTextInput? lastInput;

  /// The patch of the last update.
  ApplicationLibraryTextPatch? lastPatch;

  @override
  Future<Map<int, ApplicationLibraryText>> build() async => initial;

  void _fail() {
    final failure = failWith;
    if (failure != null) throw failure;
  }

  @override
  Future<ApplicationLibraryText> createLibraryText(
    ApplicationLibraryTextInput input,
  ) async {
    calls.add('create ${input.kind.wireName} ${input.name}');
    lastInput = input;
    _fail();
    final text = ApplicationSamples.libraryText(
      id: 70,
      name: input.name,
      kind: input.kind,
      heading: input.heading,
      text: input.text,
    );
    replaceLocally(text);
    return text;
  }

  @override
  Future<ApplicationLibraryText> updateLibraryText(
    int id,
    ApplicationLibraryTextPatch patch,
  ) async {
    calls.add('update $id ${patch.toMap().keys.join(',')}');
    lastPatch = patch;
    _fail();
    final text = state.requireValue[id]!.copyWith(
      name: patch.name,
      kind: patch.kind,
      text: patch.text,
      heading: patch.heading,
    );
    replaceLocally(text);
    return text;
  }

  @override
  Future<void> deleteLibraryText(int id) async {
    calls.add('delete $id');
    _fail();
    state = AsyncData({...state.requireValue}..remove(id));
  }
}

/// A member's identity documents with no server.
/// The club's labels, edited in memory (club_client#396): each edit is
/// recorded and stored, or refused with [failWith].
class FakeApplicationLabels extends ApplicationLabelsNotifier {
  FakeApplicationLabels([this.initial = ApplicationSamples.labels]);

  /// The labels the provider starts with.
  final ApplicationLabels initial;

  /// The edits made, in order.
  final List<String> calls = [];

  /// What an edit throws, when set.
  Exception? failWith;

  @override
  Future<ApplicationLabels> build() async => initial;

  @override
  Future<ApplicationLabel> updateLabel(String key, ApplicationText text) async {
    calls.add('update $key ${text.texts}');
    final failure = failWith;
    if (failure != null) throw failure;
    final current = state.requireValue;
    state = AsyncData(
      ApplicationLabels(
        languages: current.languages,
        labels: {...current.labels, key: text.texts},
      ),
    );
    return ApplicationLabel(key: key, text: text);
  }
}

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

/// [applicationsUser] with a date of birth the samples' "Open" age category
/// fits, so a published sample is listed for them (club_client#380).
UserPrivate eligibleMember({bool admin = false}) => applicationsUser(
  admin: admin,
).copyWith(dateOfBirthUtc: () => DateTime.utc(2000, 3, 4));

/// Mounts [child] with the applications on (or off, [enabled]), the master
/// [master], the club's [library] of texts (empty by default), the label
/// catalogue and clauses list of the samples,
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
  FakeApplicationLibraryMaster? library,
  FakeApplicationLabels? labels,
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
        clApplicationLibraryMasterProvider.overrideWith(
          () => library ?? FakeApplicationLibraryMaster(),
        ),
        applicationLabelsProvider.overrideWith(
          () => labels ?? FakeApplicationLabels(),
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
