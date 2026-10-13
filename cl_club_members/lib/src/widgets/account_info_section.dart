import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ReadOnlyField;

/// Account info section showing member since and last login.
class AccountInfoSection extends StatelessWidget {
  const AccountInfoSection({required this.user, super.key});

  final UserPrivate user;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Info', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          ReadOnlyField(
            label: 'Member since',
            value: DateFormat(
              'd MMM yyyy, HH:mm',
            ).format(user.createdAtUtc.toLocal()),
          ),
          const SizedBox(height: 8),
          ReadOnlyField(
            label: 'Last login',
            value: user.lastLoginAtUtc != null
                ? DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(user.lastLoginAtUtc!.toLocal())
                : 'Never',
          ),
        ],
      ),
    );
  }
}
