/// What a column of a marketing list holds, and so the input it shows.
enum MarketingListColumnKind {
  /// One line of text.
  text,

  /// Several lines of text; a list inside a row is one entry per line.
  multiline,

  /// A whole number, typed as digits.
  number,

  /// A day, picked from a calendar; it may be left empty.
  date,

  /// One of the column's options, or none.
  choice,
}
