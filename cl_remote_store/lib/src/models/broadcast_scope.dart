import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:meta/meta.dart';

/// What a [BroadcastScope] addresses.
enum BroadcastScopeKind { all, group, event, member }

/// Which Broadcast screen a broadcast is sent from: all members, one group,
/// one event or one member (club_client#252).
///
/// The screen's filter. It gives the screen's audience ([audience]), is
/// stored with every broadcast the screen sends as `payload.source`
/// ([toPayload]), and selects the sent broadcasts the screen lists
/// ([lists]). The server keeps `payload` as sent and returns it in the
/// list, so the source survives a narrowed send (Staff only, Choose
/// members), which goes out as a `users` audience the server cannot tie
/// back to a group or event.
///
/// Also the family key of the per-scope broadcast providers, so it has
/// value equality.
@immutable
class BroadcastScope {
  const BroadcastScope._(this.kind, {this.id, this.username});

  /// Every active member (`all_users`).
  const BroadcastScope.all() : this._(BroadcastScopeKind.all);

  /// The members of group [groupId] (`group`).
  const BroadcastScope.group(int groupId)
    : this._(BroadcastScopeKind.group, id: groupId);

  /// The members of event [eventId] (`event_members`).
  const BroadcastScope.event(int eventId)
    : this._(BroadcastScopeKind.event, id: eventId);

  /// One member alone (`users: [username]`).
  const BroadcastScope.member(String username)
    : this._(BroadcastScopeKind.member, username: username);

  /// The payload key the source is stored under.
  static const String payloadKey = 'source';

  final BroadcastScopeKind kind;

  /// The group or event id; null for [BroadcastScopeKind.all] and
  /// [BroadcastScopeKind.member].
  final int? id;

  /// The member's username; null except for [BroadcastScopeKind.member].
  final String? username;

  /// The screen's whole audience, sent when nothing narrows it.
  AudienceSelector get audience => switch (kind) {
    BroadcastScopeKind.all => const AudienceSelector.allUsers(),
    BroadcastScopeKind.group => AudienceSelector.group(id),
    BroadcastScopeKind.event => AudienceSelector.eventMembers(id),
    BroadcastScopeKind.member => AudienceSelector.users([username!]),
  };

  /// Whether the audience can be narrowed (Staff only, Choose members): not
  /// on the one-to-one screen.
  bool get canNarrow => kind != BroadcastScopeKind.member;

  /// The `payload.source` value: `{kind, id}`, the id an int for a group or
  /// event, the username for a member, absent for all members.
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'kind': kind.name,
    if (id != null) 'id': id,
    if (username != null) 'id': username,
  };

  /// The source stored in [payload], or null when it has none (a broadcast
  /// sent before club_client#252) or one this app does not read.
  static BroadcastScope? fromPayload(Map<String, dynamic> payload) {
    final raw = payload[payloadKey];
    if (raw is! Map) return null;
    final id = raw['id'];
    return switch (raw['kind']) {
      'all' => const BroadcastScope.all(),
      'group' when id is int => BroadcastScope.group(id),
      'event' when id is int => BroadcastScope.event(id),
      'member' when id is String => BroadcastScope.member(id),
      _ => null,
    };
  }

  /// Whether the screen of this scope lists [broadcast]: its source is this
  /// scope or, for a broadcast with no source, its audience is this scope's
  /// whole audience (so the all-members screen keeps the `all_users`
  /// broadcasts sent before sources were recorded).
  bool lists(Broadcast broadcast) {
    final source = fromPayload(broadcast.payload);
    if (source != null) return source == this;
    return broadcast.audienceSelector == audience;
  }

  @override
  bool operator ==(Object other) =>
      other is BroadcastScope &&
      other.kind == kind &&
      other.id == id &&
      other.username == username;

  @override
  int get hashCode => Object.hash(kind, id, username);

  @override
  String toString() =>
      'BroadcastScope(${kind.name}${id == null ? '' : ', $id'}'
      '${username == null ? '' : ', $username'})';
}
