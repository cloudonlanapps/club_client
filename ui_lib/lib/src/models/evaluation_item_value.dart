import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'evaluation_choice.dart';
import 'evaluation_item_kind.dart';
import 'evaluation_rating_scale.dart';

/// One item of an evaluation template, as the item editor, the layout
/// editor, the fill form and the read body need it. Form-local and SDK-free:
/// the host's adapter maps it to and from the SDK's item variants.
///
/// [text] is the question (markdown) of a question, or the markdown of an
/// info text. Kind-specific fields are ignored by kinds they do not apply to:
/// [scale] (rating), [labelTrue] / [labelFalse] (yes / no), [choices]
/// (single and multiple choice). [requireCommentFor] holds answer values —
/// `int` for a rating, `bool` for yes / no, the choice value `String` for
/// choices. [originItemId] is set on a copy of another template's question:
/// the item it was first copied from.
@immutable
class EvaluationItemValue {
  /// An item of [kind].
  const EvaluationItemValue({
    required this.kind,
    this.id,
    this.originItemId,
    this.text = '',
    this.isRequired = false,
    this.isPrivate = false,
    this.allowEvidence = false,
    this.showCommentArea = false,
    this.requireCommentFor = const [],
    this.scale,
    this.labelTrue,
    this.labelFalse,
    this.choices = const [],
  });

  /// A new, empty item of [kind], as the add bar creates it: no id, and a
  /// five-star scale for a rating.
  factory EvaluationItemValue.newOfKind(EvaluationItemKind kind) =>
      EvaluationItemValue(
        kind: kind,
        scale: kind == EvaluationItemKind.rating
            ? const EvaluationRatingScale.stars()
            : null,
      );

  /// Builds an item from [toMap]'s output.
  factory EvaluationItemValue.fromMap(Map<String, dynamic> map) =>
      EvaluationItemValue(
        kind: EvaluationItemKind.values.byName(map['kind'] as String),
        id: map['id'] as int?,
        originItemId: map['originItemId'] as int?,
        text: map['text'] as String? ?? '',
        isRequired: map['isRequired'] as bool? ?? false,
        isPrivate: map['isPrivate'] as bool? ?? false,
        allowEvidence: map['allowEvidence'] as bool? ?? false,
        showCommentArea: map['showCommentArea'] as bool? ?? false,
        requireCommentFor: List<Object>.from(
          map['requireCommentFor'] as List? ?? const [],
        ),
        scale: map['scale'] == null
            ? null
            : EvaluationRatingScale.fromMap(
                map['scale'] as Map<String, dynamic>,
              ),
        labelTrue: map['labelTrue'] as String?,
        labelFalse: map['labelFalse'] as String?,
        choices: [
          for (final c in map['choices'] as List? ?? const [])
            EvaluationChoice.fromMap(c as Map<String, dynamic>),
        ],
      );

  /// Builds an item from [toJson]'s output.
  factory EvaluationItemValue.fromJson(String source) =>
      EvaluationItemValue.fromMap(json.decode(source) as Map<String, dynamic>);

  /// The server's id; `null` for an item not yet created.
  final int? id;

  /// For a copied question, the item it was first copied from; `null`
  /// otherwise. A copy keeps its origin's type and answer domain.
  final int? originItemId;

  /// What the item is.
  final EvaluationItemKind kind;

  /// The question (markdown), or an info text's markdown.
  final String text;

  /// Whether saving needs an answer.
  final bool isRequired;

  /// Whether the item and its answer are hidden from the member.
  final bool isPrivate;

  /// Whether the answer may carry evidence.
  final bool allowEvidence;

  /// Whether a coach note area shows under the answer.
  final bool showCommentArea;

  /// The answer values that make the coach note required.
  final List<Object> requireCommentFor;

  /// A rating's scale.
  final EvaluationRatingScale? scale;

  /// A yes / no question's label for yes; `null` for the default.
  final String? labelTrue;

  /// A yes / no question's label for no; `null` for the default.
  final String? labelFalse;

  /// A choice question's choices, in order.
  final List<EvaluationChoice> choices;

  /// A copy with the given fields replaced; nullable fields take a getter so
  /// they can be cleared.
  EvaluationItemValue copyWith({
    int? Function()? id,
    int? Function()? originItemId,
    EvaluationItemKind? kind,
    String? text,
    bool? isRequired,
    bool? isPrivate,
    bool? allowEvidence,
    bool? showCommentArea,
    List<Object>? requireCommentFor,
    EvaluationRatingScale? Function()? scale,
    String? Function()? labelTrue,
    String? Function()? labelFalse,
    List<EvaluationChoice>? choices,
  }) => EvaluationItemValue(
    id: id != null ? id() : this.id,
    originItemId: originItemId != null ? originItemId() : this.originItemId,
    kind: kind ?? this.kind,
    text: text ?? this.text,
    isRequired: isRequired ?? this.isRequired,
    isPrivate: isPrivate ?? this.isPrivate,
    allowEvidence: allowEvidence ?? this.allowEvidence,
    showCommentArea: showCommentArea ?? this.showCommentArea,
    requireCommentFor: requireCommentFor ?? this.requireCommentFor,
    scale: scale != null ? scale() : this.scale,
    labelTrue: labelTrue != null ? labelTrue() : this.labelTrue,
    labelFalse: labelFalse != null ? labelFalse() : this.labelFalse,
    choices: choices ?? this.choices,
  );

  /// The item as a map.
  Map<String, dynamic> toMap() => {
    'id': id,
    'originItemId': originItemId,
    'kind': kind.name,
    'text': text,
    'isRequired': isRequired,
    'isPrivate': isPrivate,
    'allowEvidence': allowEvidence,
    'showCommentArea': showCommentArea,
    'requireCommentFor': requireCommentFor,
    'scale': scale?.toMap(),
    'labelTrue': labelTrue,
    'labelFalse': labelFalse,
    'choices': [for (final c in choices) c.toMap()],
  };

  /// The item as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationItemValue(id: $id, originItemId: $originItemId, '
      'kind: $kind, text: $text, '
      'isRequired: $isRequired, isPrivate: $isPrivate, '
      'allowEvidence: $allowEvidence, showCommentArea: $showCommentArea, '
      'requireCommentFor: $requireCommentFor, scale: $scale, '
      'labelTrue: $labelTrue, labelFalse: $labelFalse, choices: $choices)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationItemValue &&
          other.id == id &&
          other.originItemId == originItemId &&
          other.kind == kind &&
          other.text == text &&
          other.isRequired == isRequired &&
          other.isPrivate == isPrivate &&
          other.allowEvidence == allowEvidence &&
          other.showCommentArea == showCommentArea &&
          listEquals(other.requireCommentFor, requireCommentFor) &&
          other.scale == scale &&
          other.labelTrue == labelTrue &&
          other.labelFalse == labelFalse &&
          listEquals(other.choices, choices);

  @override
  int get hashCode => Object.hash(
    id,
    originItemId,
    kind,
    text,
    isRequired,
    isPrivate,
    allowEvidence,
    showCommentArea,
    Object.hashAll(requireCommentFor),
    scale,
    labelTrue,
    labelFalse,
    Object.hashAll(choices),
  );
}
