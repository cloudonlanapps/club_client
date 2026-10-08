import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'saving_dialog_close_icon.dart';
import 'saving_dialog_scope.dart';

class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    super.key,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.requiresPassword = false,
    this.onVerifyPassword,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool destructive;
  final bool requiresPassword;
  final Future<bool> Function(String password)? onVerifyPassword;

  /// Shows a confirmation dialog and returns `true` if the user confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    var confirmed = false;
    await showShadDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        onConfirm: () => confirmed = true,
      ),
    );
    return confirmed;
  }

  @override
  State<ConfirmDialog> createState() => ConfirmDialogState();
}

class ConfirmDialogState extends State<ConfirmDialog> {
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (widget.requiresPassword) {
      if (passwordController.text.isEmpty) {
        setState(() => errorMessage = 'Password is required');
        return;
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final isValid = await widget.onVerifyPassword!(passwordController.text);
        if (isValid) {
          if (mounted) Navigator.of(context).pop();
          widget.onConfirm();
        } else {
          if (mounted) {
            setState(() {
              isLoading = false;
              errorMessage = 'Invalid password';
            });
          }
        }
      } on Object catch (_) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'An error occurred';
          });
        }
      }
    } else {
      Navigator.of(context).pop();
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SavingDialogScope(
      saving: isLoading,
      child: ShadDialog(
        closeIcon: SavingDialogCloseIcon(saving: isLoading),
        title: Text(widget.title),
        description: Text(widget.message),
        actions: [
          ShadButton.secondary(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(widget.cancelLabel),
          ),
          if (widget.destructive)
            ShadButton.destructive(
              onPressed: isLoading ? null : _handleConfirm,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.confirmLabel),
            )
          else
            ShadButton(
              onPressed: isLoading ? null : _handleConfirm,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.confirmLabel),
            ),
        ],
        child: widget.requiresPassword
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShadInput(
                      controller: passwordController,
                      placeholder: const Text('Enter password to confirm'),
                      obscureText: true,
                      autofocus: true,
                      keyboardType: TextInputType.visiblePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: ShadTheme.of(
                              context,
                            ).colorScheme.destructive,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
