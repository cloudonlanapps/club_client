import 'dart:convert';

import 'package:meta/meta.dart';

/// Contact form subject dropdown options.
@immutable
class ContactSubjectOptions {
  const ContactSubjectOptions({
    required this.registration,
    required this.programs,
    required this.facility,
    required this.sponsorship,
    required this.other,
  });

  factory ContactSubjectOptions.fromMap(Map<String, dynamic> map) {
    return ContactSubjectOptions(
      registration: map['registration'] as String? ?? 'Registration Inquiry',
      programs: map['programs'] as String? ?? 'Programme Information',
      facility: map['facility'] as String? ?? 'Facility Rental',
      sponsorship: map['sponsorship'] as String? ?? 'Sponsorship',
      other: map['other'] as String? ?? 'Other',
    );
  }

  factory ContactSubjectOptions.fromJson(String source) =>
      ContactSubjectOptions.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  final String registration;
  final String programs;
  final String facility;
  final String sponsorship;
  final String other;

  ContactSubjectOptions copyWith({
    String? registration,
    String? programs,
    String? facility,
    String? sponsorship,
    String? other,
  }) {
    return ContactSubjectOptions(
      registration: registration ?? this.registration,
      programs: programs ?? this.programs,
      facility: facility ?? this.facility,
      sponsorship: sponsorship ?? this.sponsorship,
      other: other ?? this.other,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registration': registration,
      'programs': programs,
      'facility': facility,
      'sponsorship': sponsorship,
      'other': other,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ContactSubjectOptions(registration: $registration, '
      'programs: $programs, facility: $facility, '
      'sponsorship: $sponsorship, other: $other)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactSubjectOptions &&
        other.registration == registration &&
        other.programs == programs &&
        other.facility == facility &&
        other.sponsorship == sponsorship &&
        other.other == this.other;
  }

  @override
  int get hashCode =>
      registration.hashCode ^
      programs.hashCode ^
      facility.hashCode ^
      sponsorship.hashCode ^
      other.hashCode;
}
