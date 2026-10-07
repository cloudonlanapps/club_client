import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pure-UI "change password" form (no SDK / no Riverpod).
///
/// Collects current / new / confirm passwords, validates them client-side
/// (required, min length, match), and calls [onSubmit] with the current and
/// new passwords. The host owns the SDK call, the in-flight flag
/// ([isSubmitting]), and any server-error / success messaging.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
    super.key,
  });

  final Future<void> Function(String currentPassword, String newPassword)
  onSubmit;
  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<ChangePasswordForm> createState() => ChangePasswordFormState();
}

class ChangePasswordFormState extends State<ChangePasswordForm> {
  final formKey = GlobalKey<ShadFormState>();

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final v = form.value;
    await widget.onSubmit(v['current'] as String, v['next'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ShadCard(
            padding: const EdgeInsets.all(24),
            child: ShadForm(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Change password', style: theme.textTheme.h4),
                  const SizedBox(height: 16),
                  ShadInputFormField(
                    id: 'current',
                    label: const Text('Current password'),
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    enabled: !widget.isSubmitting,
                    validator: (v) =>
                        v.isEmpty ? 'Current password is required' : null,
                  ),
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    id: 'next',
                    label: const Text('New password'),
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    enabled: !widget.isSubmitting,
                    validator: (v) {
                      if (v.isEmpty) return 'New password is required';
                      if (v.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    id: 'confirm',
                    label: const Text('Confirm new password'),
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    enabled: !widget.isSubmitting,
                    validator: (v) {
                      if (v.isEmpty) return 'Please re-type the new password';
                      if (v != formKey.currentState?.value['next']) {
                        return 'New passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Wrap (not Row) so the two buttons flow to a second line on
                  // narrow surfaces instead of overflowing.
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ShadButton.outline(
                        onPressed: widget.isSubmitting ? null : widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                      ShadButton(
                        onPressed: widget.isSubmitting ? null : handleSubmit,
                        child: Text(
                          widget.isSubmitting ? 'Saving…' : 'Update password',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
