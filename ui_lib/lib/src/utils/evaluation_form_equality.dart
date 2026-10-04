import 'package:flutter/foundation.dart';

/// Equality of flat form value maps whose values may be lists, for the
/// evaluation forms' `isDirty`.
abstract final class EvaluationFormEquality {
  /// Whether [a] and [b] hold equal values under the same keys; lists
  /// compare element by element.
  static bool mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !valuesEqual(a[key], b[key])) return false;
    }
    return true;
  }

  /// Whether [a] and [b] are equal; lists compare element by element.
  static bool valuesEqual(Object? a, Object? b) =>
      a is List && b is List ? listEquals(a, b) : a == b;
}
