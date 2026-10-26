import 'package:flutter/foundation.dart';

/// A position a member may pick as their preferred one, as
/// `UserSportsDetailsForm` offers it: form-local, so the form needs no SDK
/// type. The host maps the club's positions to these, each with its label
/// in the language the app shows.
@immutable
class ProfilePositionOption {
  const ProfilePositionOption({required this.value, required this.label});

  /// What is stored for the member; what the form returns.
  final String value;

  /// The position's name as shown.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePositionOption &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);

  @override
  String toString() => 'ProfilePositionOption(value: $value, label: $label)';
}
