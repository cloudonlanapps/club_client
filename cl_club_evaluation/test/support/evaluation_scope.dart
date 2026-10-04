/// Stub masters, fixtures and a provider scope for the evaluation views
/// (club_core#173).
library;

import 'dart:typed_data';

import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart' show apiBaseUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A fixed instant for fixtures.
final DateTime t0 = DateTime.utc(2026, 9);

/// The template library, recording writes; [failWith] makes every write
/// throw it.
class StubTemplates extends ClEvaluationTemplatesMasterNotifier {
  StubTemplates(this.templates, {this.failWith});

  final Map<int, sdk.EvaluationTemplate> templates;
  final Exception? failWith;
  final List<String> calls = [];

  /// The layout of the last template created.
  List<sdk.EvaluationLayoutEntry<sdk.EvaluationTemplateItem>>? createdLayout;

  @override
  Future<Map<int, sdk.EvaluationTemplate>> build() async => templates;

  sdk.EvaluationTemplate record(String call, int id) {
    calls.add(call);
    if (failWith case final e?) throw e;
    return templates[id] ?? template(id);
  }

  @override
  Future<sdk.EvaluationTemplate> createTemplate({
    required String name,
    required List<sdk.EvaluationLayoutEntry<sdk.EvaluationTemplateItem>> layout,
  }) async {
    createdLayout = layout;
    return record('create $name ${layout.length}', 99);
  }

  @override
  Future<sdk.EvaluationTemplate> deleteTemplate(int id) async =>
      record('delete $id', id);

  @override
  Future<sdk.EvaluationTemplate> restoreTemplate(int id) async =>
      record('restore $id', id);

  @override
  Future<sdk.EvaluationTemplate> renameTemplate(int id, String name) async =>
      record('rename $id $name', id);

  @override
  Future<sdk.EvaluationTemplate> updateLayout(
    int id,
    List<sdk.EvaluationLayoutEntry<int>> layout,
  ) async => record('layout $id', id);

  @override
  Future<sdk.EvaluationTemplate> addItem(
    int templateId,
    sdk.EvaluationTemplateItem item, {
    String? section,
  }) async =>
      record('add $templateId ${item.type.wireName} $section', templateId);

  @override
  Future<sdk.EvaluationTemplate> replaceItem(
    int templateId,
    int itemId,
    sdk.EvaluationTemplateItem item,
  ) async => record('replace $templateId $itemId', templateId);

  @override
  Future<sdk.EvaluationTemplate> removeItem(int templateId, int itemId) async =>
      record('remove $templateId $itemId', templateId);
}

/// The caller's evaluations, recording writes. [saveError] makes
/// `saveEvaluation` throw it; [createError] makes `createEvaluation` throw;
/// [uploadError] makes `uploadEvidence` throw; [periodError] makes
/// `updateEvaluation` throw.
class StubEvaluations extends ClEvaluationsMasterNotifier {
  StubEvaluations(
    this.evaluations, {
    this.saveError,
    this.createError,
    this.uploadError,
    this.periodError,
  });

  final Map<int, sdk.EvaluationStaffView> evaluations;
  final Exception? periodError;
  final Exception? saveError;
  final Exception? createError;
  final Exception? uploadError;
  final List<String> calls = [];

  @override
  Future<Map<int, sdk.EvaluationStaffView>> build() async => evaluations;

  sdk.EvaluationStaffView record(String call, int id) {
    calls.add(call);
    return evaluations[id] ?? staffView(id);
  }

  @override
  Future<sdk.EvaluationStaffView> createEvaluation({
    required int templateId,
    required String createdFor,
    int? eventId,
    DateTime? periodStartUtc,
    DateTime? periodEndUtc,
  }) async {
    calls.add('create $templateId $createdFor $eventId');
    if (createError case final e?) throw e;
    return staffView(42, templateId: templateId, createdFor: createdFor);
  }

  @override
  Future<sdk.EvaluationStaffView> updateEvaluation(
    int id, {
    int? Function()? eventId,
    DateTime? Function()? periodStartUtc,
    DateTime? Function()? periodEndUtc,
  }) async {
    String sent(Object? Function()? getter) =>
        getter == null ? '-' : '${getter()}';
    calls.add(
      'update $id event=${sent(eventId)} start=${sent(periodStartUtc)} '
      'end=${sent(periodEndUtc)}',
    );
    if (periodError case final e?) throw e;
    return evaluations[id] ?? staffView(id);
  }

  @override
  Future<sdk.EvaluationStaffView> deleteEvaluation(int id) async =>
      record('delete $id', id);

  @override
  Future<sdk.EvaluationStaffView> putAnswer(
    int id,
    int itemId,
    sdk.EvaluationAnswerInput answer,
  ) async => record('put $id $itemId ${answer.toMap()}', id);

  @override
  Future<sdk.EvaluationStaffView> clearAnswer(int id, int itemId) async =>
      record('clear $id $itemId', id);

  @override
  Future<sdk.EvaluationStaffView> uploadEvidence(
    int id,
    int itemId, {
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    calls.add('upload $id $itemId $filename $contentType');
    if (uploadError case final e?) throw e;
    return evaluations[id] ?? staffView(id);
  }

  @override
  Future<sdk.EvaluationStaffView> detachEvidence(
    int id,
    int itemId,
    String mediaUuid,
  ) async => record('detach $id $itemId $mediaUuid', id);

  @override
  Future<sdk.EvaluationStaffView> saveEvaluation(int id) async {
    calls.add('save $id');
    if (saveError case final e?) throw e;
    return evaluations[id]!.copyWith(status: sdk.EvaluationStatus.saved);
  }

  @override
  Future<sdk.EvaluationStaffView> publishEvaluation(int id) async =>
      record('publish $id', id);
}

/// A template with [layout] over [items]; [inUse] when an evaluation uses
/// it.
sdk.EvaluationTemplate template(
  int id, {
  String name = 'Skating',
  List<sdk.EvaluationLayoutEntry<int>> layout = const [],
  List<sdk.EvaluationTemplateItem> items = const [],
  bool inUse = false,
}) => sdk.EvaluationTemplate(
  id: id,
  name: name,
  createdBy: 'admin',
  layout: layout,
  items: items,
  inUse: inUse,
  createdAtUtc: t0,
  updatedAtUtc: t0,
);

/// An evaluation as its owner reads it.
sdk.EvaluationStaffView staffView(
  int id, {
  int templateId = 1,
  String createdFor = 'ana',
  sdk.EvaluationStatus status = sdk.EvaluationStatus.draft,
  int? eventId,
  List<sdk.EvaluationAnswer> answers = const [],
  DateTime? periodStartUtc,
  DateTime? periodEndUtc,
  String? owner,
}) => sdk.EvaluationStaffView(
  id: id,
  templateId: templateId,
  createdFor: createdFor,
  createdBy: 'coach',
  owner: owner,
  status: status,
  eventId: eventId,
  periodStartUtc: periodStartUtc,
  periodEndUtc: periodEndUtc,
  answers: answers,
  createdAtUtc: t0,
  updatedAtUtc: t0,
  publishedAtUtc: status == sdk.EvaluationStatus.published ? t0 : null,
);

/// A logged-in user.
sdk.UserPrivate viewer(
  String username, {
  bool admin = false,
  bool coach = false,
}) => sdk.UserPrivate(
  username: username,
  displayName: username,
  status: sdk.UserStatus.active,
  isSuperAdmin: false,
  roles: sdk.UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

/// Another user, as the users master holds them.
sdk.UserInfo userInfo(String username, String name, {bool coach = false}) =>
    sdk.UserInfo(
      username: username,
      displayName: name,
      status: sdk.UserStatus.active,
      isSuperAdmin: false,
      roles: sdk.UserRoles(isCoach: coach),
    );

/// An event coached by [coaches].
sdk.Event event(int id, String title, {List<String> coaches = const []}) =>
    sdk.Event(
      id: id,
      title: title,
      description: '',
      type: sdk.EventType.programme,
      visibility: sdk.Visibility.public,
      venueId: 1,
      startTimeUtc: t0,
      endTimeUtc: t0,
      createdAtUtc: t0,
      updatedAtUtc: t0,
      coachNames: coaches,
    );

/// The users master, fixed.
class StubUsers extends ClUsersMasterNotifier {
  StubUsers(this.users);
  final Map<String, sdk.UserInfo> users;
  @override
  Future<Map<String, sdk.UserInfo>> build() async => users;
}

/// The events master, fixed.
class StubEnrollments extends ClEnrollmentsMasterNotifier {
  StubEnrollments(this.enrollments);
  final Map<int, Map<String, sdk.EnrollmentStatus>> enrollments;
  @override
  Future<Map<String, sdk.EnrollmentStatus>> build(int arg) async =>
      enrollments[arg] ?? const {};
}

class StubEvents extends ClEventsMasterNotifier {
  StubEvents(this.events);
  final Map<int, sdk.Event> events;
  @override
  Future<Map<int, sdk.Event>> build() async => events;
}

/// The bytes [fixedPdfReader] serves.
final Uint8List fixedPdfBytes = Uint8List.fromList(const [37, 80, 68, 70]);

/// A media reader serving [fixedPdfBytes] for any file.
Future<Uint8List> fixedPdfReader(sdk.MediaRef media) async => fixedPdfBytes;

/// A scope with evaluations [on], the masters stubbed, every username shown
/// by its name in [users], private media read by [readBytes] and fetched
/// with [authHeaders], and [child] in a shadcn app.
Widget evaluationScope({
  required Widget child,
  bool? on = true,
  StubTemplates? templates,
  StubEvaluations? evaluations,
  List<sdk.EvaluationMemberView> memberViews = const [],
  EvaluationMemberMedia? memberMedia,
  EvaluationMemberMedia? ownerMedia,
  Map<String, sdk.UserInfo> users = const {},
  Map<int, sdk.Event> events = const {},
  Map<int, Map<String, sdk.EnrollmentStatus>> enrollments = const {},
  List<sdk.EvaluationTemplateItemHit> hits = const [],
  MediaBytesReader readBytes = fixedPdfReader,
  Map<String, String> authHeaders = const {},
}) {
  String nameOf(String username) => users[username]?.displayName ?? username;
  return ProviderScope(
    overrides: [
      evaluationsProvider.overrideWithValue(on),
      apiBaseUrlProvider.overrideWithValue('https://api.test'),
      clEvaluationTemplatesMasterProvider.overrideWith(
        () => templates ?? StubTemplates({}),
      ),
      clEvaluationsMasterProvider.overrideWith(
        () => evaluations ?? StubEvaluations({}),
      ),
      clMemberEvaluationsProvider.overrideWith(
        (ref, username) async =>
            memberViews.where((v) => v.createdFor == username).toList(),
      ),
      clMemberEvaluationMediaProvider.overrideWith(
        (ref, key) async => memberMedia,
      ),
      clEvaluationMediaProvider.overrideWith((ref, id) async => ownerMedia),
      clUserInfoProvider.overrideWith(
        (ref, username) async => userInfo(username, nameOf(username)),
      ),
      clMyEventDetailProvider.overrideWith(
        (ref, key) async => events[key.eventId] ?? event(key.eventId, 'Event'),
      ),
      clUsersMasterProvider.overrideWith(() => StubUsers(users)),
      clEventsMasterProvider.overrideWith(() => StubEvents(events)),
      clEnrollmentsMasterProvider.overrideWith(
        () => StubEnrollments(enrollments),
      ),
      clEvaluationItemSearchProvider.overrideWith((ref, query) async => hits),
      clMediaBytesReaderProvider.overrideWithValue(readBytes),
      imageAuthHeadersProvider.overrideWith((ref) async => authHeaders),
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}

/// A tall surface so long views lay out without scrolling.
Future<void> tallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
