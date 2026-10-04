import 'dart:convert';

import 'package:meta/meta.dart';

import 'contact_subject_options.dart';

/// Contact form section labels.
@immutable
class ContactFormLabels {
  const ContactFormLabels({
    required this.title,
    required this.description,
    required this.nameLabel,
    required this.namePlaceholder,
    required this.emailLabel,
    required this.emailPlaceholder,
    required this.phoneLabel,
    required this.phonePlaceholder,
    required this.subjectLabel,
    required this.subjectPlaceholder,
    required this.subjectOptions,
    required this.messageLabel,
    required this.messagePlaceholder,
    required this.submitButton,
  });

  factory ContactFormLabels.fromMap(Map<String, dynamic> map) {
    return ContactFormLabels(
      title: map['title'] as String? ?? 'Send us a Message',
      description:
          map['description'] as String? ??
          "Fill out the form below and we'll get back to you within 24 hours.",
      nameLabel: map['nameLabel'] as String? ?? 'Name *',
      namePlaceholder: map['namePlaceholder'] as String? ?? 'Your full name',
      emailLabel: map['emailLabel'] as String? ?? 'Email *',
      emailPlaceholder: map['emailPlaceholder'] as String? ?? 'your@email.com',
      phoneLabel: map['phoneLabel'] as String? ?? 'Phone',
      phonePlaceholder: map['phonePlaceholder'] as String? ?? '(555) 123-4567',
      subjectLabel: map['subjectLabel'] as String? ?? 'Subject *',
      subjectPlaceholder:
          map['subjectPlaceholder'] as String? ?? 'Select a topic',
      subjectOptions: ContactSubjectOptions.fromMap(
        map['subjectOptions'] as Map<String, dynamic>? ?? {},
      ),
      messageLabel: map['messageLabel'] as String? ?? 'Message *',
      messagePlaceholder:
          map['messagePlaceholder'] as String? ?? 'How can we help you?',
      submitButton: map['submitButton'] as String? ?? 'Send Message',
    );
  }

  factory ContactFormLabels.fromJson(String source) =>
      ContactFormLabels.fromMap(json.decode(source) as Map<String, dynamic>);

  final String title;
  final String description;
  final String nameLabel;
  final String namePlaceholder;
  final String emailLabel;
  final String emailPlaceholder;
  final String phoneLabel;
  final String phonePlaceholder;
  final String subjectLabel;
  final String subjectPlaceholder;
  final ContactSubjectOptions subjectOptions;
  final String messageLabel;
  final String messagePlaceholder;
  final String submitButton;

  ContactFormLabels copyWith({
    String? title,
    String? description,
    String? nameLabel,
    String? namePlaceholder,
    String? emailLabel,
    String? emailPlaceholder,
    String? phoneLabel,
    String? phonePlaceholder,
    String? subjectLabel,
    String? subjectPlaceholder,
    ContactSubjectOptions? subjectOptions,
    String? messageLabel,
    String? messagePlaceholder,
    String? submitButton,
  }) {
    return ContactFormLabels(
      title: title ?? this.title,
      description: description ?? this.description,
      nameLabel: nameLabel ?? this.nameLabel,
      namePlaceholder: namePlaceholder ?? this.namePlaceholder,
      emailLabel: emailLabel ?? this.emailLabel,
      emailPlaceholder: emailPlaceholder ?? this.emailPlaceholder,
      phoneLabel: phoneLabel ?? this.phoneLabel,
      phonePlaceholder: phonePlaceholder ?? this.phonePlaceholder,
      subjectLabel: subjectLabel ?? this.subjectLabel,
      subjectPlaceholder: subjectPlaceholder ?? this.subjectPlaceholder,
      subjectOptions: subjectOptions ?? this.subjectOptions,
      messageLabel: messageLabel ?? this.messageLabel,
      messagePlaceholder: messagePlaceholder ?? this.messagePlaceholder,
      submitButton: submitButton ?? this.submitButton,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'nameLabel': nameLabel,
      'namePlaceholder': namePlaceholder,
      'emailLabel': emailLabel,
      'emailPlaceholder': emailPlaceholder,
      'phoneLabel': phoneLabel,
      'phonePlaceholder': phonePlaceholder,
      'subjectLabel': subjectLabel,
      'subjectPlaceholder': subjectPlaceholder,
      'subjectOptions': subjectOptions.toMap(),
      'messageLabel': messageLabel,
      'messagePlaceholder': messagePlaceholder,
      'submitButton': submitButton,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ContactFormLabels(title: $title, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactFormLabels &&
        other.title == title &&
        other.description == description &&
        other.nameLabel == nameLabel &&
        other.namePlaceholder == namePlaceholder &&
        other.emailLabel == emailLabel &&
        other.emailPlaceholder == emailPlaceholder &&
        other.phoneLabel == phoneLabel &&
        other.phonePlaceholder == phonePlaceholder &&
        other.subjectLabel == subjectLabel &&
        other.subjectPlaceholder == subjectPlaceholder &&
        other.subjectOptions == subjectOptions &&
        other.messageLabel == messageLabel &&
        other.messagePlaceholder == messagePlaceholder &&
        other.submitButton == submitButton;
  }

  @override
  int get hashCode =>
      title.hashCode ^
      description.hashCode ^
      nameLabel.hashCode ^
      namePlaceholder.hashCode ^
      emailLabel.hashCode ^
      emailPlaceholder.hashCode ^
      phoneLabel.hashCode ^
      phonePlaceholder.hashCode ^
      subjectLabel.hashCode ^
      subjectPlaceholder.hashCode ^
      subjectOptions.hashCode ^
      messageLabel.hashCode ^
      messagePlaceholder.hashCode ^
      submitButton.hashCode;
}
