/// Whether two form values are the same: lists and maps compared item by
/// item, anything else with `==`.
///
/// The marketing forms hold lists of rows, which `mapEquals` would compare
/// by identity, so their `isDirty` compares with this.
bool marketingValuesEqual(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!marketingValuesEqual(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !marketingValuesEqual(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}
