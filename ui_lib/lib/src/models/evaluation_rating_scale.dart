import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'evaluation_rating_style.dart';

/// A rating question's scale: stars or a range over [min]..[max], or
/// labelled [levels] valued 1..n by their order. Form-local and SDK-free.
@immutable
class EvaluationRatingScale {
  /// A scale of [style]; [min] and [max] apply to stars and ranges,
  /// [levels] to labelled levels.
  const EvaluationRatingScale({
    required this.style,
    this.min = defaultMin,
    this.max = defaultMax,
    this.levels = const [],
  });

  /// Stars valued [min]..[max].
  const EvaluationRatingScale.stars({
    this.min = defaultMin,
    this.max = defaultMax,
  }) : style = EvaluationRatingStyle.stars,
       levels = const [];

  /// A slider over [min]..[max].
  const EvaluationRatingScale.range({required this.min, required this.max})
    : style = EvaluationRatingStyle.range,
      levels = const [];

  /// Labelled [levels], lowest first, valued 1..n.
  const EvaluationRatingScale.levels(this.levels)
    : style = EvaluationRatingStyle.levels,
      min = defaultMin,
      max = defaultMax;

  /// Builds a scale from [toMap]'s output.
  factory EvaluationRatingScale.fromMap(Map<String, dynamic> map) =>
      EvaluationRatingScale(
        style: EvaluationRatingStyle.values.byName(
          map['style'] as String? ?? EvaluationRatingStyle.stars.name,
        ),
        min: map['min'] as int? ?? defaultMin,
        max: map['max'] as int? ?? defaultMax,
        levels: List<String>.from(map['levels'] as List? ?? const []),
      );

  /// Builds a scale from [toJson]'s output.
  factory EvaluationRatingScale.fromJson(String source) =>
      EvaluationRatingScale.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Default lowest value of stars and ranges.
  static const int defaultMin = 1;

  /// Default highest value of stars and ranges.
  static const int defaultMax = 5;

  /// How the rating is given.
  final EvaluationRatingStyle style;

  /// Lowest value of stars and ranges.
  final int min;

  /// Highest value of stars and ranges.
  final int max;

  /// Level labels, lowest first; only for [EvaluationRatingStyle.levels].
  final List<String> levels;

  /// Whether the scale is labelled levels.
  bool get isLevels => style == EvaluationRatingStyle.levels;

  /// Lowest value: 1 for levels.
  int get lowest => isLevels ? 1 : min;

  /// Highest value: the number of levels for levels.
  int get highest => isLevels ? levels.length : max;

  /// Every value the scale takes, lowest first.
  List<int> get values => [for (var v = lowest; v <= highest; v++) v];

  /// The label of [value]: its level label, else the number.
  String labelFor(int value) => isLevels && value >= 1 && value <= levels.length
      ? levels[value - 1]
      : '$value';

  /// A copy with the given fields replaced.
  EvaluationRatingScale copyWith({
    EvaluationRatingStyle? style,
    int? min,
    int? max,
    List<String>? levels,
  }) => EvaluationRatingScale(
    style: style ?? this.style,
    min: min ?? this.min,
    max: max ?? this.max,
    levels: levels ?? this.levels,
  );

  /// The scale as a map.
  Map<String, dynamic> toMap() => {
    'style': style.name,
    'min': min,
    'max': max,
    'levels': levels,
  };

  /// The scale as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'EvaluationRatingScale(style: $style, min: $min, max: $max, '
      'levels: $levels)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationRatingScale &&
          other.style == style &&
          other.min == min &&
          other.max == max &&
          listEquals(other.levels, levels);

  @override
  int get hashCode => Object.hash(style, min, max, Object.hashAll(levels));
}
