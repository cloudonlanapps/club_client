import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clIdentityDocsMasterProvider,
        clUsersMasterProvider,
        currentUserProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/auth_override.dart';
import 'providers/identity_docs_master_override.dart';
import 'providers/users_master_override.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(DummyAuthNotifier.new),
        currentUserProvider.overrideWith(
          (ref) => ref.watch(authStateProvider).valueOrNull,
        ),
        clUsersMasterProvider.overrideWith(DummyUsersMasterNotifier.new),
        clIdentityDocsMasterProvider.overrideWith(
          DummyIdentityDocsMasterNotifier.new,
        ),
      ],
      child: const MemberOnboardingExampleApp(),
    ),
  );
}
