import 'package:flutter/widgets.dart';

/// An organizer or a coach as `EventStaffForm` shows one: form-local,
/// so the form needs no picker or SDK type. The host maps to and from its
/// own.
@immutable
class EventStaffMember {
  const EventStaffMember({required this.username, required this.displayName});

  /// Identifies the member; what the form returns.
  final String username;

  /// The member's name as shown.
  final String displayName;

  /// One or two capitals standing for [displayName] in an avatar.
  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is EventStaffMember &&
      other.username == username &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(username, displayName);

  @override
  String toString() =>
      'EventStaffMember(username: $username, displayName: $displayName)';
}
