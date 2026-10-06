/// The admin credit actions (club_client#41): Add credit for a member, and
/// per package Extend, Reverse and Transfer.
enum CreditActionKind {
  /// ➕ Add credit: a new account.
  grant('Add credit'),

  /// 📅 Extend a package's validity.
  extend('Extend'),

  /// ↶ Reverse unspent credit on a package, capped at its balance (R59).
  reverse('Reverse'),

  /// ⇄ Close a package and move what survives a penalty into a new general
  /// account: how a programme's credit is settled.
  transfer('Transfer');

  const CreditActionKind(this.title);

  /// The heading its form is shown under.
  final String title;
}
