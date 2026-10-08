import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupForm, SignupFormState;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider, defaultCountryCodeProvider, writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

import '../models/onboarding_write_messages.dart';
import '../models/reapply_form_helpers.dart';
import '../models/reapply_sizes.dart';
import '../models/reapply_strings.dart';
import 'review_note_banner.dart';

/// The reapply view of onboarding: a member an admin sent back changes
/// their registration and submits it again.
///
/// Hosts the SDK-free [SignupForm] in its reapply mode with the heading,
/// the admin's note and the Submit changes action. It validates the form,
/// resubmits through `clUsersMasterProvider`, holds the in-flight flag, and
/// on success stores the updated user before calling [onContinue].
class ReapplyVariant extends ConsumerStatefulWidget {
  const ReapplyVariant({
    required this.currentUser,
    required this.onContinue,
    super.key,
  });

  /// The member reapplying.
  final UserPrivate currentUser;

  /// Called once the changes are submitted.
  final VoidCallback onContinue;

  @override
  ConsumerState<ReapplyVariant> createState() => ReapplyVariantState();
}

/// State of [ReapplyVariant]: holds the form's key and the in-flight flag.
class ReapplyVariantState extends ConsumerState<ReapplyVariant> {
  /// Key of the reapply form.
  final formKey = GlobalKey<SignupFormState>();

  /// Whether a resubmission is in flight.
  bool isSubmitting = false;

  /// The Submit changes action: validates the form and resubmits.
  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;

    setState(() => isSubmitting = true);
    UserPrivate? updated;
    try {
      updated = await ReapplyFormSubmit.reapply(
        notifier: ref.read(clUsersMasterProvider.notifier),
        defaultCountryCode: ref.read(defaultCountryCodeProvider),
        values: values,
      );
    } on Object catch (error) {
      showError(writeFailureMessage(error, fallback: reapplyFailedMessage));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (updated == null || !mounted) return;
    ref.read(authStateProvider.notifier).setUser(updated);
    widget.onContinue();
  }

  /// Shows [message] as a failure toast.
  void showError(String message) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final user = widget.currentUser;
    final note = user.adminReviewNote;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobileWidth(context)
              ? double.infinity
              : ReapplySizes.maxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ReapplySizes.horizontalPadding,
            vertical: ReapplySizes.verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ReapplyStrings.title, style: theme.textTheme.h3),
              const SizedBox(height: ReapplySizes.headingGap),
              Text(ReapplyStrings.intro, style: theme.textTheme.p),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: ReapplySizes.noteGap),
                ReviewNoteBanner(note: note),
              ],
              const SizedBox(height: ReapplySizes.sectionGap),
              SignupForm(
                key: formKey,
                username: user.username,
                initialValues: buildReapplyFormInitialValues(user),
                defaultCountryCode: ref.watch(defaultCountryCodeProvider),
                enabled: !isSubmitting,
              ),
              const SizedBox(height: ReapplySizes.sectionGap),
              ShadButton(
                onPressed: isSubmitting ? null : submit,
                child: Text(
                  isSubmitting
                      ? ReapplyStrings.submitting
                      : ReapplyStrings.submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
