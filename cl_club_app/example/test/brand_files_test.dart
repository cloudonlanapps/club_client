// The brand files are what make this app one club's. These check that each one
// is present and in the shape cl_club_app reads. They run here against the
// neutral files, and the project generator runs them against every brand's
// files before building, so a broken brand stops the build.
import 'dart:convert';
import 'dart:io';

import 'package:cl_club_app/cl_club_app.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readJson(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('Issue 186: club.json reads as a ClubConfig', () {
    final config = ClubConfig.fromJson(File(kClubConfigAsset).readAsStringSync());
    expect(config.fullName, isNotEmpty);
    expect(config.shortName, isNotEmpty);
    expect(Uri.parse(config.apiBaseUrl).hasScheme, isTrue);
  });

  test('Issue 186: contact_info.json reads as the bundled ContactInfo', () {
    // fromBundled throws unless clubName, phoneNumber and email are present.
    final contact = ContactInfo.fromBundled(readJson(kClubContactAsset));
    expect(contact.clubName, isNotEmpty);
    expect(contact.phoneNumber, isNotEmpty);
    expect(contact.email, contains('@'));
  });

  test('Issue 186: the club logo is present', () {
    expect(File(kClubLogoAsset).existsSync(), isTrue);
  });
}
