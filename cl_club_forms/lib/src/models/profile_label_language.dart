import 'package:flutter/foundation.dart';

/// A language `ProfileOptionsForm` gives each position a label in: its
/// code, the key of the label, and its name as shown above the label's
/// input. Form-local; the host says which languages there are.
@immutable
class ProfileLabelLanguage {
  const ProfileLabelLanguage({required this.code, required this.name});

  /// The language's code (`en`, `mr`); the key of a position's label.
  final String code;

  /// The language's name as shown.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileLabelLanguage && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'ProfileLabelLanguage(code: $code, name: $name)';
}
