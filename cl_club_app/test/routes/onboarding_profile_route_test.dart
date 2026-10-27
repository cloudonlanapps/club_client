import 'package:cl_club_app/src/router.dart' show routerProvider;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_onboarding/cl_member_onboarding.dart'
    show onboardingProfilePath;
import 'package:cl_remote_store/cl_remote_store.dart'
    show identityVerificationProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _SignedOut extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter router() {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedOut.new),
        identityVerificationProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    return container.read(routerProvider);
  }

  test("Issue 340: onboarding's profile page is a route of the router", () {
    expect(
      router().configuration
          .findMatch(Uri.parse(onboardingProfilePath))
          .isEmpty,
      isFalse,
    );
  });

  test('Issue 340: the extended-profile step is no longer a route', () {
    expect(
      router().configuration
          .findMatch(Uri.parse('/onboarding/extended-profile'))
          .isEmpty,
      isTrue,
    );
  });
}
