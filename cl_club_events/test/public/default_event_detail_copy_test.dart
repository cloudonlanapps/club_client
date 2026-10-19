import 'package:cl_club_events/cl_club_events.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/public_events.dart';

void main() {
  group('Issue 157: the default copy of an event page', () {
    test('Issue 157: the hero is the stamp, title and short description', () {
      final copy = defaultEventDetailCopy(
        testEventView(
          testPublicEvent(
            title: 'Summer camp',
            marketing: const EventMarketingBasic(
              shortDescription: 'Learn to skate',
              stamp: 'NEW',
            ),
          ),
        ),
      );

      expect(copy.pageData.hero.title, 'Summer camp');
      expect(copy.pageData.hero.badge, 'NEW');
      expect(copy.pageData.hero.description, 'Learn to skate');
      expect(copy.labels.fees.title, 'Fees');
    });

    test('Issue 157: a live event invites registration', () {
      final copy = defaultEventDetailCopy(testEventView(testPublicEvent()));

      expect(copy.pageData.cta?.primaryButtonText, 'Register Now');
    });

    test('Issue 157: a finished event says so', () {
      final copy = defaultEventDetailCopy(
        testEventView(testPublicEvent(isPast: true)),
      );

      expect(copy.pageData.cta?.title, 'This Event Has Ended');
    });
  });
}
