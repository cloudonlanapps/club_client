import 'package:cl_club_app/src/router.dart' show routerProvider;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_onboarding/cl_member_onboarding.dart'
    show onboardingExtendedProfilePath;
import 'package:cl_remote_store/cl_remote_store.dart'
    show extendedProfileProvider, identityVerificationProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SignedOut extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("Issue 320: onboarding's extended-profile step is a route of the "
      'router', () {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedOut.new),
        identityVerificationProvider.overrideWithValue(true),
        extendedProfileProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    expect(
      router.configuration
          .findMatch(Uri.parse(onboardingExtendedProfilePath))
          .isEmpty,
      isFalse,
    );
  });
}
