import 'package:cl_club_website/cl_club_website.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final strings = SiteStrings(const {
    'navPrograms': 'Training\nSessions',
    'navEvents': 'Learning\nCamps',
    'navRinks': 'The\nRinks',
  });

  test('Issue 52: top-level segments take their nav label', () {
    expect(routeLabel(strings, 'programs'), 'Training\nSessions');
    expect(routeLabel(strings, 'events'), 'Learning\nCamps');
    expect(routeLabel(strings, 'rinks'), 'The\nRinks');
  });

  test('Issue 52: other segments have no label of their own', () {
    expect(routeLabel(strings, 'rink'), isNull);
    expect(routeLabel(strings, 'weekend-early'), isNull);
  });
}
