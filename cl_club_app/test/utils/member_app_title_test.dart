import 'package:cl_club_app/cl_club_app.dart';
import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter_test/flutter_test.dart';

ClubBranding _branding(String shortName) => ClubBranding(
  fullName: 'Example Club',
  shortName: shortName,
  heroSurface: ClubHeroSurface.secondary,
);

void main() {
  test('Issue 367: the tab is titled "<shortName> Member App"', () {
    expect(memberAppTitle(_branding('EXC')), 'EXC Member App');
  });

  test('Issue 367: a club with no short name is titled "Member App"', () {
    expect(memberAppTitle(_branding('')), 'Member App');
  });
}
