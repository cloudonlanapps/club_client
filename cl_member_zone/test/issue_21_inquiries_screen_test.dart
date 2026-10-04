import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({bool admin = false}) => UserPrivate(
  username: 'u1',
  displayName: 'Test User',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isMember: !admin),
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._u);
  final UserPrivate? _u;
  @override
  Future<UserPrivate?> build() async => _u;
}

class _StubInquiries extends ClInquiriesMasterNotifier {
  @override
  Future<InquiryInbox> build() async => InquiryInbox.empty(
    filter: InquiryFilter.open,
    limit: inquiryPageSize,
  );
}

Widget _wrap(UserPrivate user) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuth(user)),
    clInquiriesMasterProvider.overrideWith(_StubInquiries.new),
  ],
  child: ShadApp(
    home: Scaffold(body: InquiriesScreen(onHome: () {})),
  ),
);

void main() {
  group('Issue 21: InquiriesScreen gating', () {
    testWidgets('Issue 21: a member is denied', (tester) async {
      await tester.pumpWidget(_wrap(_user()));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('Inquiries'), findsNothing);
    });

    testWidgets('Issue 21: an admin sees the inbox', (tester) async {
      await tester.pumpWidget(_wrap(_user(admin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsNothing);
      expect(find.text('Inquiries'), findsOneWidget);
      expect(find.text('No inquiries.'), findsOneWidget);
    });
  });
}
