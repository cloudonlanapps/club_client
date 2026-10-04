import 'package:cl_club_app/src/review_routes.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart' show evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'member_a',
    displayName: 'member_a',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
  );
}

Future<void> _open(WidgetTester tester, String location) async {
  final router = GoRouter(initialLocation: location, routes: reviewRoutes());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_Auth.new),
        // Off: every screen refuses, so no master is read.
        evaluationsProvider.overrideWithValue(false),
      ],
      child: ShadApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 174: the review routes resolve literal segments first', () {
    final cases = <String, Type>{
      myReviewsPath: MyReviewsScreen,
      myReviewPath(7): MyReviewScreen,
      reviewsPath: ReviewsScreen,
      templateLibraryPath: TemplateLibraryScreen,
      templateCreatePath: TemplateCreateScreen,
      templatePath(3): TemplateDetailScreen,
      reviewEditPath(4): ReviewEditScreen,
    };
    for (final MapEntry(key: location, value: screen) in cases.entries) {
      testWidgets('Issue 174: $location mounts $screen', (tester) async {
        await _open(tester, location);
        expect(find.byType(screen), findsOneWidget);
      });
    }
  });

  group('Issue 173: Duplicate opens the designer with the copy', () {
    testWidgets('Issue 173: the copy path names the template to copy', (
      tester,
    ) async {
      await _open(tester, templateCopyPath(3));
      final screen = tester.widget<TemplateCreateScreen>(
        find.byType(TemplateCreateScreen),
      );
      expect(screen.copyOfTemplateId, 3);
    });

    testWidgets('Issue 173: a plain designer copies nothing', (tester) async {
      await _open(tester, templateCreatePath);
      final screen = tester.widget<TemplateCreateScreen>(
        find.byType(TemplateCreateScreen),
      );
      expect(screen.copyOfTemplateId, isNull);
    });
  });
}
