import 'package:flutter/foundation.dart';

/// A language an application may be printed in: its code, the key of each
/// text, and its name as shown. Form-local; the host lists the languages
/// of the label catalogue.
@immutable
class ApplicationLanguageOption {
  const ApplicationLanguageOption({required this.code, required this.name});

  /// The language's code (`en`, `mr`).
  final String code;

  /// The language's name as shown.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationLanguageOption &&
          other.code == code &&
          other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'ApplicationLanguageOption(code: $code, name: $name)';
}
