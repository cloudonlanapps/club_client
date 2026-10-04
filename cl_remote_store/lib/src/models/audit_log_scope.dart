import 'package:meta/meta.dart';

/// What an [AuditLogScope] targets.
enum AuditLogScopeKind { global, event, group, venue, user }

/// Immutable key describing *which* slice of the audit log to fetch.
///
/// Used as the family key for `clAuditLogMasterProvider`, so each entity (and
/// the global feed) gets its own cached page. Construct via the named
/// factories — they bake in the server `verbose` level appropriate to each
/// entity:
///
/// - [AuditLogScope.global] — the full feed (super-admin only); no scope
///   params.
/// - [AuditLogScope.event] — `resourceType=event`, `verbose=3` (also includes
///   the event's occurrence and media-link rows).
/// - [AuditLogScope.group] / [AuditLogScope.venue] — `verbose=2` (also media
///   links).
/// - [AuditLogScope.user] — `username` scope (rows where the user is actor or
///   target).
@immutable
class AuditLogScope {
  const AuditLogScope._({
    required this.kind,
    this.resourceId,
    this.username,
    this.verbose = 1,
  });

  /// The unscoped global feed (super-admin only).
  const AuditLogScope.global() : this._(kind: AuditLogScopeKind.global);

  /// An event's history, widened to its occurrence and media-link rows.
  const AuditLogScope.event(int eventId)
    : this._(
        kind: AuditLogScopeKind.event,
        resourceId: eventId,
        verbose: 3,
      );

  /// A group's history, widened to its media-link rows.
  const AuditLogScope.group(int groupId)
    : this._(
        kind: AuditLogScopeKind.group,
        resourceId: groupId,
        verbose: 2,
      );

  /// A venue's history, widened to its media-link rows.
  const AuditLogScope.venue(int venueId)
    : this._(
        kind: AuditLogScopeKind.venue,
        resourceId: venueId,
        verbose: 2,
      );

  /// A user's history (rows where they are the actor or the target).
  const AuditLogScope.user(String username)
    : this._(kind: AuditLogScopeKind.user, username: username);

  final AuditLogScopeKind kind;

  /// The numeric entity id for event / group / venue scopes; null otherwise.
  final int? resourceId;

  /// The username for a user scope; null otherwise.
  final String? username;

  /// Server `verbose` level (entity scopes only).
  final int verbose;

  /// `resourceType` wire value for the server, or null for global/user scopes.
  String? get resourceType => switch (kind) {
    AuditLogScopeKind.event => 'event',
    AuditLogScopeKind.group => 'group',
    AuditLogScopeKind.venue => 'venue',
    AuditLogScopeKind.global || AuditLogScopeKind.user => null,
  };

  /// `resourceId` wire value (string) for the server, or null.
  String? get resourceIdWire => resourceId?.toString();

  /// Whether this is the super-admin-only global feed.
  bool get isGlobal => kind == AuditLogScopeKind.global;

  @override
  bool operator ==(Object other) =>
      other is AuditLogScope &&
      other.kind == kind &&
      other.resourceId == resourceId &&
      other.username == username &&
      other.verbose == verbose;

  @override
  int get hashCode => Object.hash(kind, resourceId, username, verbose);

  @override
  String toString() =>
      'AuditLogScope(${kind.name}, id: $resourceId, user: $username)';
}
