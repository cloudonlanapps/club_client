import 'package:flutter/foundation.dart' show immutable;

/// Form-local age: a length of years, months and days, the unit of the age
/// band on events and groups.
///
/// Mirrors the SDK `Age` without importing `club_sdk_2`, keeping `ui_lib`
/// SDK-free. The caller's adapter maps between the two at the boundary.
@immutable
class FormAge implements Comparable<FormAge> {
  const FormAge({required this.years, this.months = 0, this.days = 0});

  final int years;
  final int months;
  final int days;

  /// Whether the age is a whole number of years.
  bool get isWholeYears => months == 0 && days == 0;

  /// Orders two ages part by part: years, then months, then days.
  @override
  int compareTo(FormAge other) {
    if (years != other.years) return years.compareTo(other.years);
    if (months != other.months) return months.compareTo(other.months);
    return days.compareTo(other.days);
  }

  @override
  String toString() => 'FormAge(years: $years, months: $months, days: $days)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormAge &&
        other.years == years &&
        other.months == months &&
        other.days == days;
  }

  @override
  int get hashCode => Object.hash(years, months, days);
}
