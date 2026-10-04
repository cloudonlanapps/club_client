import 'package:cl_remote_store/cl_remote_store.dart'
    show identityVerificationProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/signup_success_view.dart';

/// Thin screen wrapper around [SignupSuccessView].
class SignupSuccessScreen extends ConsumerWidget {
  const SignupSuccessScreen({required this.onHome, super.key});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SignupSuccessView(
      onHome: onHome,
      identityVerification: ref.watch(identityVerificationProvider),
    );
  }
}
