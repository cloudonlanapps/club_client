import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart'
    show ServerConfig, serverConfigProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PickedImage;

/// An inquiries master that serves [inbox] and records what the view asks.
class StubInquiries extends ClInquiriesMasterNotifier {
  StubInquiries(this.inbox);

  InquiryInbox inbox;
  final List<InquiryFilter> filters = [];
  final List<String> handledCalls = [];
  final List<int> deleted = [];

  @override
  Future<InquiryInbox> build() async => inbox;

  @override
  Future<void> setFilter(InquiryFilter filter) async {
    filters.add(filter);
    inbox = inbox.copyWith(filter: filter);
    state = AsyncData(inbox);
  }

  @override
  Future<Inquiry> setHandled(int id, {required bool handled}) async {
    handledCalls.add('$id $handled');
    final row = inbox.page.items.firstWhere((i) => i.id == id);
    return row.copyWith(
      handledAtUtc: () => handled ? DateTime.utc(2026, 9, 28) : null,
      handledBy: () => handled ? 'viewer' : null,
    );
  }

  @override
  Future<void> deleteInquiry(int id) async => deleted.add(id);
}

/// A site media master that serves [saved], records saves and uploads, and
/// refuses a save with [refuseWith] when set.
class StubSiteMedia extends ClSiteMediaMasterNotifier {
  StubSiteMedia(this.saved);

  Map<String, MediaRef> saved;
  final List<Map<String, MediaRef>> saves = [];
  final List<String> uploads = [];
  ServerException? refuseWith;

  @override
  Future<Map<String, MediaRef>> build() async => saved;

  @override
  Future<void> save(Map<String, MediaRef> slots) async {
    final refusal = refuseWith;
    if (refusal != null) throw refusal;
    saves.add(slots);
    saved = slots;
    state = AsyncData(slots);
  }

  @override
  Future<MediaRef> uploadPublic({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    uploads.add(filename);
    return const MediaRef(
      uuid: 'uuid-uploaded',
      mimeType: 'image/webp',
      filename: 'uploaded.webp',
    );
  }
}

/// A club identity master that serves [saved], records saves, and refuses
/// a save with [refuseWith], or fails it with [failWith], when set.
class StubClubIdentity extends ClClubIdentityMasterNotifier {
  StubClubIdentity(this.saved);

  ClubIdentity saved;
  final List<ClubIdentity> saves = [];
  ServerException? refuseWith;
  Error? failWith;

  @override
  Future<ClubIdentity> build() async => saved;

  @override
  Future<ClubIdentity> save(ClubIdentity identity) async {
    final refusal = refuseWith;
    if (refusal != null) throw refusal;
    final failure = failWith;
    if (failure != null) throw failure;
    saves.add(identity);
    saved = identity;
    state = AsyncData(identity);
    return identity;
  }
}

/// A media library that serves [items].
class StubLibrary extends ClMediaLibraryNotifier {
  StubLibrary(this.items);
  final List<Media> items;
  @override
  Future<List<Media>> build() async => items;
}

Media libraryMedia(
  String uuid, {
  List<String> roles = const ['public'],
  String type = 'image',
}) => Media(
  id: uuid.hashCode,
  uuid: uuid,
  originalFilename: '$uuid.png',
  mediaType: type,
  mimeType: type == 'video' ? 'video/mp4' : 'image/webp',
  originalMimeType: 'image/png',
  filename: '$uuid.webp',
  fileSize: 10,
  preserveOriginal: false,
  conversionStatus: 'completed',
  accessRoles: roles,
  isEncrypted: false,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// A valid 1×1 PNG, for the upload preview.
const List<int> onePixelPng = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, //
  0, 0, 0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, //
  84, 120, 156, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254, 13, 239, 70, 184, //
  0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
];

/// Overrides for the site media screen: the masters stubbed, a server
/// origin for thumbnails, and a picker that returns [onePixelPng].
List<Override> siteMediaOverrides({
  required StubSiteMedia siteMedia,
  List<Media> library = const [],
}) => [
  clSiteMediaMasterProvider.overrideWith(() => siteMedia),
  clMediaLibraryProvider.overrideWith(() => StubLibrary(library)),
  serverConfigProvider.overrideWithValue(
    const ServerConfig(baseUrl: 'https://api.example.test/v1'),
  ),
  imagePickerProvider.overrideWithValue(
    () async => const PickedImage(
      bytes: onePixelPng,
      filename: 'hero.png',
      mimeType: 'image/png',
    ),
  ),
];

UserPrivate adminViewer({bool superAdmin = false}) => UserPrivate(
  username: 'viewer',
  displayName: 'viewer',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

Inquiry inquiry(
  int id, {
  InquiryKind kind = InquiryKind.contact,
  String message = 'Hello there',
  String? phone,
  Map<String, dynamic>? extra,
  bool handled = false,
}) => Inquiry(
  id: id,
  kind: kind,
  name: 'Sender $id',
  email: 'sender$id@example.com',
  phone: phone,
  message: message,
  extra: extra,
  createdAtUtc: DateTime.utc(2026, 9, 20, 10),
  handledAtUtc: handled ? DateTime.utc(2026, 9, 21, 10) : null,
  handledBy: handled ? 'someadmin' : null,
);

InquiryInbox inboxOf(
  List<Inquiry> items, {
  InquiryFilter filter = InquiryFilter.open,
  int? unhandled,
}) => InquiryInbox(
  filter: filter,
  page: PaginatedList<Inquiry>(
    items: items,
    total: items.length,
    limit: inquiryPageSize,
    offset: 0,
  ),
  unhandledCount: unhandled ?? items.where((i) => !i.isHandled).length,
);

/// A provider scope with the admin masters stubbed.
Widget adminScope({
  required Widget child,
  StubInquiries? inquiries,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      if (inquiries != null)
        clInquiriesMasterProvider.overrideWith(() => inquiries),
      ...overrides,
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}
