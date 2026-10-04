import 'dart:convert';

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:meta/meta.dart';

/// A published evaluation's media as its member sees it (club_core#173):
/// the stored member copy PDF, and the evidence on its public items by
/// item id.
@immutable
class EvaluationMemberMedia {
  const EvaluationMemberMedia({required this.evidence, this.memberCopy});

  /// Splits the tag-grouped listing: `member_copy` is the member copy,
  /// an item id is that item's evidence, and any other tag is ignored.
  factory EvaluationMemberMedia.fromGrouped(
    Map<String, List<MediaLink>> grouped,
  ) {
    final copies = grouped[EvaluationMediaTags.memberCopy] ?? const [];
    final evidence = <int, List<MediaLink>>{};
    for (final entry in grouped.entries) {
      final itemId = EvaluationMediaTags.itemIdOf(entry.key);
      if (itemId != null) evidence[itemId] = List.unmodifiable(entry.value);
    }
    return EvaluationMemberMedia(
      memberCopy: copies.isEmpty ? null : copies.last,
      evidence: Map.unmodifiable(evidence),
    );
  }

  factory EvaluationMemberMedia.fromMap(Map<String, dynamic> map) {
    final copy = map['memberCopy'] as Map<String, dynamic>?;
    final evidence = (map['evidence'] as Map<String, dynamic>?) ?? const {};
    return EvaluationMemberMedia(
      memberCopy: copy == null ? null : MediaLink.fromMap(copy),
      evidence: {
        for (final e in evidence.entries)
          int.parse(e.key): [
            for (final link in e.value as List)
              MediaLink.fromMap(link as Map<String, dynamic>),
          ],
      },
    );
  }

  factory EvaluationMemberMedia.fromJson(String source) =>
      EvaluationMemberMedia.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// The member copy PDF stored on publish; null when none is stored.
  final MediaLink? memberCopy;

  /// Evidence links by item id.
  final Map<int, List<MediaLink>> evidence;

  /// The evidence on item [itemId]; empty when it has none.
  List<MediaLink> evidenceFor(int itemId) => evidence[itemId] ?? const [];

  /// A copy with the given fields replaced.
  EvaluationMemberMedia copyWith({
    MediaLink? Function()? memberCopy,
    Map<int, List<MediaLink>>? evidence,
  }) {
    return EvaluationMemberMedia(
      memberCopy: memberCopy != null ? memberCopy() : this.memberCopy,
      evidence: evidence ?? this.evidence,
    );
  }

  /// This listing as a map.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'memberCopy': memberCopy?.toMap(),
    'evidence': {
      for (final e in evidence.entries)
        '${e.key}': e.value.map((l) => l.toMap()).toList(),
    },
  };

  /// This listing as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationMemberMedia(memberCopy: ${memberCopy?.mediaUuid}, '
      'evidence: ${evidence.keys.toList()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EvaluationMemberMedia ||
        other.memberCopy != memberCopy ||
        other.evidence.length != evidence.length) {
      return false;
    }
    for (final e in evidence.entries) {
      if (!listEquals(other.evidence[e.key], e.value)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    memberCopy,
    Object.hashAllUnordered(
      evidence.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))),
    ),
  );
}
