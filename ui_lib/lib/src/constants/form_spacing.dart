/// The gaps of a form, named by what they separate. The same values as
/// `cl_club_forms`' `FormSpacing`; the two packages share no code.
abstract final class FormSpacing {
  /// Between a field's label and the field.
  static const double labelGap = 8;

  /// Between one row of a form and the next.
  static const double rowGap = 16;

  /// Between two groups of rows, and above a group's heading.
  static const double sectionGap = 24;
}
