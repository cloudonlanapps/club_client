import '../constants/evaluation_strings.dart';

/// How a rating is given.
enum EvaluationRatingStyle {
  /// Stars, valued min..max.
  stars,

  /// A discrete slider over min..max.
  range,

  /// Labelled levels, valued 1..n by their order.
  levels;

  /// The style's name as the designer reads it.
  String get label => switch (this) {
    EvaluationRatingStyle.stars => EvaluationStrings.styleStars,
    EvaluationRatingStyle.range => EvaluationStrings.styleRange,
    EvaluationRatingStyle.levels => EvaluationStrings.styleLevels,
  };
}
