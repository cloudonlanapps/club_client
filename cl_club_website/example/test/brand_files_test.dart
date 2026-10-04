// The brand files are what make this site one club's. These check that each
// one is present and in the shape cl_club_website reads. They run here against
// the neutral files, and the project generator runs them against every brand's
// files before building, so a broken brand stops the build.
import 'dart:convert';
import 'dart:io';

import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readJson(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('ARB', () {
    final arb = readJson(kSiteStringsAsset);
    final arbKeys = arb.keys.where((k) => !k.startsWith('@')).toSet();

    test('has every key SiteStrings reads', () {
      expect(SiteStrings.keys.toSet().difference(arbKeys), isEmpty);
    });

    test('has no key SiteStrings does not read', () {
      expect(arbKeys.difference(SiteStrings.keys.toSet()), isEmpty);
    });

    test('every value is a string', () {
      for (final key in arbKeys) {
        expect(arb[key], isA<String>(), reason: key);
      }
    });

    test('fills placeholders', () {
      final strings = SiteStrings.fromArb(arb);
      expect(
        strings.campCtaAvailableDescription('1 May'),
        allOf(contains('1 May'), isNot(contains('{deadline}'))),
      );
      expect(
        strings.oneOffCtaAvailableDescription('1 May'),
        allOf(contains('1 May'), isNot(contains('{deadline}'))),
      );
    });
  });

  test('club.json reads as a SiteConfig', () {
    final config = SiteConfig.fromJson(readJson(kSiteConfigAsset));
    expect(config.fullName, isNotEmpty);
    expect(config.shortName, isNotEmpty);
    expect(Uri.parse(config.apiBaseUrl).hasScheme, isTrue);
    expect(config.map.hasEmbed, isTrue);
  });

  test('contact_info.json reads as the bundled ContactInfo', () {
    // fromBundled throws unless clubName, phoneNumber and email are present.
    final contact = ContactInfo.fromBundled(readJson(kContactInfoAsset));
    expect(contact.clubName, isNotEmpty);
    expect(contact.phoneNumber, isNotEmpty);
    expect(contact.email, contains('@'));
  });

  test('the club logo is present', () {
    expect(File(kClubLogoAsset).existsSync(), isTrue);
  });
}
