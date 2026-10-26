import 'package:flutter/foundation.dart';

import 'application_text_value.dart';

/// One of the template's facts, printed on its own.
@immutable
class ApplicationFactText extends ApplicationTextValue {
  const ApplicationFactText(this.fact);

  /// The fact reference [json] holds.
  factory ApplicationFactText.fromJson(Map<Object?, Object?> json) {
    final fact = json[ApplicationTextValue.factKey];
    return ApplicationFactText(fact is String ? fact : '');
  }

  /// The fact's name; `''` while none is chosen.
  final String fact;

  @override
  Map<String, String> toJson() => {ApplicationTextValue.factKey: fact};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationFactText && other.fact == fact;

  @override
  int get hashCode => fact.hashCode;

  @override
  String toString() => 'ApplicationFactText($fact)';
}
