import 'dart:convert';

import 'package:meta/meta.dart';

/// Contact info section labels.
@immutable
class ContactInfoLabels {
  const ContactInfoLabels({
    required this.title,
    required this.addressLabel,
    required this.phoneLabel,
    required this.emailLabel,
    required this.followUsLabel,
    required this.qrCodeHint,
  });

  factory ContactInfoLabels.fromMap(Map<String, dynamic> map) {
    return ContactInfoLabels(
      title: map['title'] as String? ?? 'Contact Information',
      addressLabel: map['addressLabel'] as String? ?? 'Address',
      phoneLabel: map['phoneLabel'] as String? ?? 'Phone',
      emailLabel: map['emailLabel'] as String? ?? 'Email',
      followUsLabel: map['followUsLabel'] as String? ?? 'Follow Us',
      qrCodeHint:
          map['qrCodeHint'] as String? ?? 'Scan to follow us on Instagram',
    );
  }

  factory ContactInfoLabels.fromJson(String source) =>
      ContactInfoLabels.fromMap(json.decode(source) as Map<String, dynamic>);

  final String title;
  final String addressLabel;
  final String phoneLabel;
  final String emailLabel;
  final String followUsLabel;
  final String qrCodeHint;

  ContactInfoLabels copyWith({
    String? title,
    String? addressLabel,
    String? phoneLabel,
    String? emailLabel,
    String? followUsLabel,
    String? qrCodeHint,
  }) {
    return ContactInfoLabels(
      title: title ?? this.title,
      addressLabel: addressLabel ?? this.addressLabel,
      phoneLabel: phoneLabel ?? this.phoneLabel,
      emailLabel: emailLabel ?? this.emailLabel,
      followUsLabel: followUsLabel ?? this.followUsLabel,
      qrCodeHint: qrCodeHint ?? this.qrCodeHint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'addressLabel': addressLabel,
      'phoneLabel': phoneLabel,
      'emailLabel': emailLabel,
      'followUsLabel': followUsLabel,
      'qrCodeHint': qrCodeHint,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ContactInfoLabels(title: $title, addressLabel: $addressLabel, '
      'phoneLabel: $phoneLabel, emailLabel: $emailLabel, '
      'followUsLabel: $followUsLabel, qrCodeHint: $qrCodeHint)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfoLabels &&
        other.title == title &&
        other.addressLabel == addressLabel &&
        other.phoneLabel == phoneLabel &&
        other.emailLabel == emailLabel &&
        other.followUsLabel == followUsLabel &&
        other.qrCodeHint == qrCodeHint;
  }

  @override
  int get hashCode =>
      title.hashCode ^
      addressLabel.hashCode ^
      phoneLabel.hashCode ^
      emailLabel.hashCode ^
      followUsLabel.hashCode ^
      qrCodeHint.hashCode;
}
