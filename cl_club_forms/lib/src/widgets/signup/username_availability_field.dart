import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../user_form/user_form_fields.dart';

/// Minimum username length before the **Check availability** button
/// becomes visible. Reduces noise from single-letter probes.
const int minLengthForCheck = 3;

/// Reusable username field with a "Check availability" affordance.
///
/// Internally renders a `ShadInputFormField` plus a row with the
/// **Check availability** button and a result/error message. It carries no
/// label: the embedding form puts it in a `LabeledFormRow`.
///
/// The widget is provider-agnostic: callers supply a [checkAvailability]
/// callback that resolves to `true` when the username can be registered
/// and `false` when it is already taken.
///
/// The parent gates submission via [onAvailabilityChanged]: the callback
/// fires whenever the username text changes (with `confirmedUsername`
/// reset to `null`) and again when an availability check resolves
/// (with `confirmedUsername` set to the now-confirmed username, or
/// `null` if the result was "taken" / errored). The parent's submit
/// button should disable until `confirmedUsername == current text`.
class UsernameAvailabilityField extends StatefulWidget {
  const UsernameAvailabilityField({
    required this.enabled,
    required this.validator,
    required this.onAvailabilityChanged,
    required this.checkAvailability,
    this.id = UserFormFields.usernameId,
    this.placeholder,
    this.autofocus = false,
    super.key,
  });

  final bool enabled;
  final String? Function(String) validator;
  final void Function(String username, String? confirmedUsername)
  onAvailabilityChanged;

  /// Resolves to `true` when the username is available, `false` when
  /// taken. May throw to surface network/validation failures, which the
  /// widget renders as a generic "could not check" message.
  final Future<bool> Function(String username) checkAvailability;

  final String id;
  final Widget? placeholder;
  final bool autofocus;

  @override
  State<UsernameAvailabilityField> createState() =>
      UsernameAvailabilityFieldState();
}

class UsernameAvailabilityFieldState extends State<UsernameAvailabilityField> {
  final controller = TextEditingController();
  String? confirmedAvailableUsername;
  bool? lastAvailable;
  bool isChecking = false;
  String? lastError;

  @override
  void initState() {
    super.initState();
    controller.addListener(onChanged);
  }

  @override
  void dispose() {
    controller
      ..removeListener(onChanged)
      ..dispose();
    super.dispose();
  }

  void onChanged() {
    if (!mounted) return;
    final current = controller.text.trim();
    setState(() {
      if (current != confirmedAvailableUsername) {
        confirmedAvailableUsername = null;
        lastAvailable = null;
        lastError = null;
      }
    });
    widget.onAvailabilityChanged(current, confirmedAvailableUsername);
  }

  Future<void> handleCheck() async {
    final username = controller.text.trim();
    if (username.length < minLengthForCheck) return;
    final formatError = widget.validator(username);
    if (formatError != null) return;

    setState(() {
      isChecking = true;
      lastError = null;
    });
    try {
      final available = await widget.checkAvailability(username);
      if (!mounted) return;
      setState(() {
        lastAvailable = available;
        confirmedAvailableUsername = available ? username : null;
      });
      widget.onAvailabilityChanged(username, confirmedAvailableUsername);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        lastError = 'Could not check availability. Try again.';
        lastAvailable = null;
        confirmedAvailableUsername = null;
      });
      widget.onAvailabilityChanged(username, null);
    } finally {
      if (mounted) setState(() => isChecking = false);
    }
  }

  Widget? buildStatusIcon(ShadThemeData theme) {
    if (isChecking) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final available = lastAvailable;
    if (available == null) return null;
    final icon = available ? Icons.check_circle_outline : Icons.cancel_outlined;
    final color = available
        ? theme.colorScheme.primary
        : theme.colorScheme.destructive;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(icon, size: 18, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final username = controller.text.trim();
    final showCheckRow = username.length >= minLengthForCheck;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadInputFormField(
          id: widget.id,
          controller: controller,
          placeholder: widget.placeholder,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          enabled: widget.enabled && !isChecking,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-z0-9_]')),
          ],
          trailing: buildStatusIcon(theme),
          validator: widget.validator,
        ),
        const SizedBox(height: 4),
        Text(
          'Lowercase letters, digits, and _ only',
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        if (showCheckRow) ...[
          const SizedBox(height: 4),
          UsernameAvailabilityRow(
            checking: isChecking,
            enabledOuter: widget.enabled,
            username: username,
            confirmedUsername: confirmedAvailableUsername,
            available: lastAvailable,
            error: lastError,
            onCheck: handleCheck,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

/// Compact "Check availability" affordance and result message
/// rendered directly below the username input.
class UsernameAvailabilityRow extends StatelessWidget {
  const UsernameAvailabilityRow({
    required this.checking,
    required this.enabledOuter,
    required this.username,
    required this.confirmedUsername,
    required this.available,
    required this.error,
    required this.onCheck,
    required this.theme,
    super.key,
  });

  final bool checking;
  final bool enabledOuter;
  final String username;
  final String? confirmedUsername;
  final bool? available;
  final String? error;
  final VoidCallback onCheck;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    final buttonEnabled =
        !checking &&
        enabledOuter &&
        username.isNotEmpty &&
        confirmedUsername != username;

    String? message;
    Color? messageColor;
    if (error != null) {
      message = error;
      messageColor = theme.colorScheme.destructive;
    } else if (checking) {
      message = 'Checking…';
      messageColor = theme.colorScheme.mutedForeground;
    } else if (available == true) {
      message = 'Available';
      messageColor = theme.colorScheme.primary;
    } else if (available == false) {
      message = 'Already taken';
      messageColor = theme.colorScheme.destructive;
    }

    return Row(
      children: [
        ShadButton.link(
          size: ShadButtonSize.sm,
          onPressed: buttonEnabled ? onCheck : null,
          child: const Text('Check availability'),
        ),
        const SizedBox(width: 8),
        if (message != null)
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.small.copyWith(color: messageColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
