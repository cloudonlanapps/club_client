/// Where a clause of the library may be used in an application template,
/// as the library's JSON names it.
enum ApplicationClauseKind {
  /// An item of the header strip.
  header('header'),

  /// The declaration above the signatures.
  declaration('declaration'),

  /// A term, with its heading.
  rule('rule'),

  /// An additional selection, ticked by hand.
  selection('selection'),

  /// A closing note under the terms.
  note('note');

  const ApplicationClauseKind(this.jsonName);

  /// The kind's name in the library's JSON.
  final String jsonName;

  /// The kind named [json]; null when no kind has that name.
  static ApplicationClauseKind? fromJson(Object? json) {
    for (final kind in values) {
      if (kind.jsonName == json) return kind;
    }
    return null;
  }
}
