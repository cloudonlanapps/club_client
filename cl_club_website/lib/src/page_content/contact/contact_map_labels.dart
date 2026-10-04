import 'dart:convert';

import 'package:meta/meta.dart';

/// Contact map section labels.
@immutable
class ContactMapLabels {
  const ContactMapLabels({
    required this.openInMapsButton,
  });

  factory ContactMapLabels.fromMap(Map<String, dynamic> map) {
    return ContactMapLabels(
      openInMapsButton: map['openInMapsButton'] as String? ?? 'Open in Maps',
    );
  }

  factory ContactMapLabels.fromJson(String source) =>
      ContactMapLabels.fromMap(json.decode(source) as Map<String, dynamic>);

  final String openInMapsButton;

  ContactMapLabels copyWith({
    String? openInMapsButton,
  }) {
    return ContactMapLabels(
      openInMapsButton: openInMapsButton ?? this.openInMapsButton,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'openInMapsButton': openInMapsButton,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'ContactMapLabels(openInMapsButton: $openInMapsButton)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactMapLabels &&
        other.openInMapsButton == openInMapsButton;
  }

  @override
  int get hashCode => openInMapsButton.hashCode;
}
