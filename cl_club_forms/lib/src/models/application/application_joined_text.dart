import 'package:flutter/foundation.dart';

import 'application_text_value.dart';

/// Several texts printed on one line, as a header item may be: each part is
/// custom, a fact or a clause.
@immutable
class ApplicationJoinedText extends ApplicationTextValue {
  const ApplicationJoinedText(this.parts);

  /// The parts, in the order printed.
  final List<ApplicationTextValue> parts;

  @override
  List<Object> toJson() => [for (final part in parts) part.toJson()];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationJoinedText && listEquals(other.parts, parts);

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() => 'ApplicationJoinedText($parts)';
}
