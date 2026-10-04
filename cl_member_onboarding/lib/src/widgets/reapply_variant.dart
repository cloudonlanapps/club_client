import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

import '../models/onboarding_write_messages.dart';

class ReapplyVariant extends ConsumerStatefulWidget {
  const ReapplyVariant({
    required this.currentUser,
    required this.onContinue,
    super.key,
  });

  final UserPrivate currentUser;
  final VoidCallback onContinue;

  @override
  ConsumerState<ReapplyVariant> createState() => ReapplyVariantState();
}

class ReapplyVariantState extends ConsumerState<ReapplyVariant> {
  UserPrivate? captured;

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 480,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SignupForm(
              username: widget.currentUser.username,
              initialValues: reapplyInitialValues(widget.currentUser),
              banner: widget.currentUser.adminReviewNote,
              onCheckUsernameAvailable: (_) async => true,
              onSubmit:
                  ({
                    required email,
                    required phone,
                    required dateOfBirthUtc,
                    required gender,
                    username,
                    password,
                    firstName,
                    middleName,
                    lastName,
                  }) async {
                    try {
                      final updated = await ref
                          .read(clUsersMasterProvider.notifier)
                          .reapplyForSelf(
                            email: email,
                            phone: phone,
                            dateOfBirthUtc: dateOfBirthUtc,
                            gender: toSdkGender(gender),
                            firstName: firstName,
                            middleName: middleName,
                            lastName: lastName,
                          );
                      captured = updated;
                      return const SignupSubmitResult();
                    } on Object catch (e) {
                      return SignupSubmitResult(
                        formError: writeFailureMessage(
                          e,
                          fallback: reapplyFailedMessage,
                        ),
                      );
                    }
                  },
              onSubmitSuccess: () {
                final updated = captured;
                if (updated != null) {
                  ref.read(authStateProvider.notifier).setUser(updated);
                }
                widget.onContinue();
              },
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> reapplyInitialValues(UserPrivate u) {
  return {
    if (u.firstName != null) 'firstName': u.firstName,
    if (u.middleName != null) 'middleName': u.middleName,
    if (u.lastName != null) 'lastName': u.lastName,
    if (u.dateOfBirthUtc != null) 'dateOfBirthUtc': u.dateOfBirthUtc,
    if (u.gender != null) 'gender': toSignupGender(u.gender!),
    if (u.phone != null) 'phone': u.phone,
    'email': u.email,
  };
}

SignupGender toSignupGender(Gender g) {
  return switch (g) {
    Gender.male => SignupGender.male,
    Gender.female => SignupGender.female,
    Gender.other => SignupGender.other,
    Gender.preferNotToSay => SignupGender.preferNotToSay,
  };
}

Gender toSdkGender(SignupGender g) {
  return switch (g) {
    SignupGender.male => Gender.male,
    SignupGender.female => Gender.female,
    SignupGender.other => Gender.other,
    SignupGender.preferNotToSay => Gender.preferNotToSay,
  };
}
