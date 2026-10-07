/// Sizes of the views that host an account form: sign in, sign up, forgot
/// password and change password.
abstract final class AuthViewSizes {
  /// Widest an account form's column grows.
  static const double maxWidth = 420;

  /// Around the column, and inside the change-password card.
  static const double padding = 24;

  /// Between a view's heading and the line under it.
  static const double headingGap = 4;

  /// Between a view's heading block and its form, and between the form and
  /// its actions.
  static const double sectionGap = 20;

  /// Between the change-password heading and its form.
  static const double cardHeadingGap = 16;

  /// Between a form and the action under it where they sit close.
  static const double actionGap = 16;

  /// Between two actions stacked or side by side.
  static const double buttonGap = 12;

  /// Between an action and the link under it.
  static const double linkGap = 8;
}
