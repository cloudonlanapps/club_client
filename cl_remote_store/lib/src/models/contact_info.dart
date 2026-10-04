import 'dart:convert';

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';

/// How to reach the club: the one contact model the apps and the website
/// share (club_core#53).
///
/// Built from the host's bundled `assets/data/contact_info.json`
/// ([ContactInfo.fromBundled]) and overlaid, field by field, with the
/// server's public club identity (`contactInfoFromServer`). Text a club may
/// translate is a [LocalizedText]; the link helpers and [fullAddress] take
/// the viewer's language code and fall back to the default text.
@immutable
class ContactInfo {
  const ContactInfo({
    required this.clubName,
    required this.phoneNumber,
    required this.email,
    this.whatsappNumber,
    this.whatsappMessage,
    this.emailSubject,
    this.tagline,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.instagramUrl,
  });

  /// Reads the host's bundled block, in the `contact_info.json` shape.
  ///
  /// Throws a [FormatException] when [clubName], [phoneNumber] or [email]
  /// is missing: this is the fallback, so there is nothing further to fall
  /// back on. An empty optional field reads as absent.
  factory ContactInfo.fromBundled(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    String required(String key) =>
        text(key) ??
        (throw FormatException('$bundledAsset: "$key" is missing'));

    LocalizedText? localized(String key) {
      final value = LocalizedText.fromWire(json[key]);
      return value == null || isBlank(value) ? null : value;
    }

    return ContactInfo(
      clubName: required(clubNameKey),
      phoneNumber: required(phoneNumberKey),
      email: required(emailKey),
      whatsappNumber: text(whatsappNumberKey),
      whatsappMessage: localized(whatsappMessageKey),
      emailSubject: localized(emailSubjectKey),
      tagline: localized(taglineKey),
      addressLine1: localized(addressLine1Key),
      addressLine2: localized(addressLine2Key),
      city: localized(cityKey),
      state: localized(stateKey),
      postalCode: text(postalCodeKey),
      instagramUrl: text(instagramUrlKey),
    );
  }

  /// Reads [toMap]'s output. Lenient where [ContactInfo.fromBundled] is
  /// strict: a missing required field reads as `''`.
  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      clubName: map[clubNameKey] as String? ?? '',
      phoneNumber: map[phoneNumberKey] as String? ?? '',
      email: map[emailKey] as String? ?? '',
      whatsappNumber: map[whatsappNumberKey] as String?,
      whatsappMessage: LocalizedText.fromWire(map[whatsappMessageKey]),
      emailSubject: LocalizedText.fromWire(map[emailSubjectKey]),
      tagline: LocalizedText.fromWire(map[taglineKey]),
      addressLine1: LocalizedText.fromWire(map[addressLine1Key]),
      addressLine2: LocalizedText.fromWire(map[addressLine2Key]),
      city: LocalizedText.fromWire(map[cityKey]),
      state: LocalizedText.fromWire(map[stateKey]),
      postalCode: map[postalCodeKey] as String?,
      instagramUrl: map[instagramUrlKey] as String?,
    );
  }

  factory ContactInfo.fromJson(String source) =>
      ContactInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Where a host keeps its bundled contact block.
  static const String bundledAsset = 'assets/data/contact_info.json';

  /// Bundled key of [clubName].
  static const String clubNameKey = 'clubName';

  /// Bundled key of [phoneNumber].
  static const String phoneNumberKey = 'phoneNumber';

  /// Bundled key of [email].
  static const String emailKey = 'email';

  /// Bundled key of [whatsappNumber].
  static const String whatsappNumberKey = 'whatsappNumber';

  /// Bundled key of [whatsappMessage].
  static const String whatsappMessageKey = 'whatsappMessage';

  /// Bundled key of [emailSubject].
  static const String emailSubjectKey = 'emailSubject';

  /// Bundled key of [tagline].
  static const String taglineKey = 'tagline';

  /// Bundled key of [addressLine1] (the server's `address`).
  static const String addressLine1Key = 'addressLine1';

  /// Bundled key of [addressLine2].
  static const String addressLine2Key = 'addressLine2';

  /// Bundled key of [city].
  static const String cityKey = 'city';

  /// Bundled key of [state].
  static const String stateKey = 'state';

  /// Bundled key of [postalCode].
  static const String postalCodeKey = 'postalCode';

  /// Bundled key of [instagramUrl].
  static const String instagramUrlKey = 'instagramUrl';

  /// WhatsApp's click-to-chat origin.
  static const String whatsappBase = 'https://wa.me/';

  /// The scheme of a phone link.
  static const String telScheme = 'tel:';

  /// The scheme of an email link.
  static const String mailtoScheme = 'mailto:';

  /// Whether [value] holds no text in any language.
  static bool isBlank(LocalizedText value) =>
      value.defaultValue.isEmpty &&
      value.byLanguage.values.every((text) => text.isEmpty);

  /// The club's full name.
  final String clubName;

  /// The club's public phone number.
  final String phoneNumber;

  /// The club's public email address.
  final String email;

  /// A separate WhatsApp number; [whatsappOrPhone] falls back to
  /// [phoneNumber] without one.
  final String? whatsappNumber;

  /// The message a WhatsApp link opens with.
  final LocalizedText? whatsappMessage;

  /// The subject an email link opens with.
  final LocalizedText? emailSubject;

  /// A one-line description of the club.
  final LocalizedText? tagline;

  /// First line of the postal address.
  final LocalizedText? addressLine1;

  /// Second line of the postal address.
  final LocalizedText? addressLine2;

  /// City of the postal address.
  final LocalizedText? city;

  /// State or region of the postal address.
  final LocalizedText? state;

  /// Postal code of the postal address.
  final String? postalCode;

  /// The club's Instagram profile URL.
  final String? instagramUrl;

  /// The number WhatsApp links go to.
  String get whatsappOrPhone => whatsappNumber ?? phoneNumber;

  /// Whether any part of the postal address is set.
  bool get hasAddress =>
      addressLine1 != null ||
      addressLine2 != null ||
      city != null ||
      state != null ||
      (postalCode?.isNotEmpty ?? false);

  /// The postal address in [languageCode], one line per line: the two
  /// address lines, then city, state and postal code on one.
  String fullAddress(String languageCode) {
    final lines = [
      ?addressLine1?.resolve(languageCode),
      ?addressLine2?.resolve(languageCode),
    ].where((line) => line.isNotEmpty).toList();
    final cityLine = [
      ?city?.resolve(languageCode),
      ?state?.resolve(languageCode),
      ?postalCode,
    ].where((part) => part.isNotEmpty).join(', ');
    if (cityLine.isNotEmpty) lines.add(cityLine);
    return lines.join('\n');
  }

  /// A WhatsApp chat link, opening with the message in [languageCode].
  String whatsappUrl(String languageCode) {
    final number = whatsappOrPhone.replaceAll(RegExp('[^0-9]'), '');
    final message = whatsappMessage?.resolve(languageCode) ?? '';
    if (message.isEmpty) return '$whatsappBase$number';
    return '$whatsappBase$number?text=${Uri.encodeComponent(message)}';
  }

  /// A phone link. A number has no language, so this takes none.
  String get phoneUrl => '$telScheme$phoneNumber';

  /// An email link, with the subject in [languageCode].
  String emailUrl(String languageCode) {
    final subject = emailSubject?.resolve(languageCode) ?? '';
    if (subject.isEmpty) return '$mailtoScheme$email';
    return '$mailtoScheme$email?subject=${Uri.encodeComponent(subject)}';
  }

  ContactInfo copyWith({
    String? clubName,
    String? phoneNumber,
    String? email,
    String? Function()? whatsappNumber,
    LocalizedText? Function()? whatsappMessage,
    LocalizedText? Function()? emailSubject,
    LocalizedText? Function()? tagline,
    LocalizedText? Function()? addressLine1,
    LocalizedText? Function()? addressLine2,
    LocalizedText? Function()? city,
    LocalizedText? Function()? state,
    String? Function()? postalCode,
    String? Function()? instagramUrl,
  }) {
    return ContactInfo(
      clubName: clubName ?? this.clubName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      whatsappNumber: whatsappNumber != null
          ? whatsappNumber()
          : this.whatsappNumber,
      whatsappMessage: whatsappMessage != null
          ? whatsappMessage()
          : this.whatsappMessage,
      emailSubject: emailSubject != null ? emailSubject() : this.emailSubject,
      tagline: tagline != null ? tagline() : this.tagline,
      addressLine1: addressLine1 != null ? addressLine1() : this.addressLine1,
      addressLine2: addressLine2 != null ? addressLine2() : this.addressLine2,
      city: city != null ? city() : this.city,
      state: state != null ? state() : this.state,
      postalCode: postalCode != null ? postalCode() : this.postalCode,
      instagramUrl: instagramUrl != null ? instagramUrl() : this.instagramUrl,
    );
  }

  /// The bundled shape; translated fields in the SDK's wire form.
  Map<String, dynamic> toMap() {
    return {
      clubNameKey: clubName,
      phoneNumberKey: phoneNumber,
      emailKey: email,
      whatsappNumberKey: ?whatsappNumber,
      whatsappMessageKey: ?whatsappMessage?.toWire(),
      emailSubjectKey: ?emailSubject?.toWire(),
      taglineKey: ?tagline?.toWire(),
      addressLine1Key: ?addressLine1?.toWire(),
      addressLine2Key: ?addressLine2?.toWire(),
      cityKey: ?city?.toWire(),
      stateKey: ?state?.toWire(),
      postalCodeKey: ?postalCode,
      instagramUrlKey: ?instagramUrl,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'ContactInfo(${toMap()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo &&
        other.clubName == clubName &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.whatsappNumber == whatsappNumber &&
        other.whatsappMessage == whatsappMessage &&
        other.emailSubject == emailSubject &&
        other.tagline == tagline &&
        other.addressLine1 == addressLine1 &&
        other.addressLine2 == addressLine2 &&
        other.city == city &&
        other.state == state &&
        other.postalCode == postalCode &&
        other.instagramUrl == instagramUrl;
  }

  @override
  int get hashCode => Object.hash(
    clubName,
    phoneNumber,
    email,
    whatsappNumber,
    whatsappMessage,
    emailSubject,
    tagline,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    instagramUrl,
  );
}
