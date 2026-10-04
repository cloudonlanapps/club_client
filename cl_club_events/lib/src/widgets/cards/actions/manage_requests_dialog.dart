import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show EventType, ServerException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionIcon, ConfirmDialog, CredentialedNetworkImage;

import '../../../utils/event_write_error_message.dart';

/// Dialog for managing enrollment requests.
class ManageRequestsDialog extends ConsumerStatefulWidget {
  const ManageRequestsDialog({
    required this.eventId,
    required this.requestingUsers,
    required this.onComplete,
    super.key,
  });

  final int eventId;
  final List<String> requestingUsers;
  final VoidCallback onComplete;

  @override
  ConsumerState<ManageRequestsDialog> createState() =>
      ManageRequestsDialogState();
}

class ManageRequestsDialogState extends ConsumerState<ManageRequestsDialog> {
  late List<String> pendingUsers;

  /// username → 'approve' | 'reject' for the row whose mutation is in flight.
  final Map<String, String> _running = {};

  @override
  void initState() {
    super.initState();
    pendingUsers = List.from(widget.requestingUsers);
  }

  bool _isBusy(String userName) => _running.containsKey(userName);

  Future<void> _approve(String userName) async {
    setState(() => _running[userName] = 'approve');
    try {
      await ref
          .read(clEnrollmentsMasterProvider(widget.eventId).notifier)
          .approveRequest(userName);
      if (mounted) onActionSuccess(userName, 'approved');
    } on ServerException catch (e) {
      if (mounted) onActionError(enrollmentApproveErrorMessage(e));
    } on Object catch (e) {
      if (mounted) onActionError(eventWriteErrorMessage(e));
    } finally {
      if (mounted) setState(() => _running.remove(userName));
    }
  }

  Future<void> _reject(String userName) async {
    final ok = await showRejectConfirmation(context, userName);
    if (!ok || !mounted) return;
    setState(() => _running[userName] = 'reject');
    try {
      await ref
          .read(clEnrollmentsMasterProvider(widget.eventId).notifier)
          .rejectRequest(userName, reason: 'Request rejected by organizer');
      if (mounted) onActionSuccess(userName, 'rejected');
    } on ServerException catch (e) {
      if (mounted) onActionError(e.message);
    } on Object catch (e) {
      if (mounted) onActionError(eventWriteErrorMessage(e));
    } finally {
      if (mounted) setState(() => _running.remove(userName));
    }
  }

  String capitalizeStr(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void onActionSuccess(String userName, String actionText) {
    setState(() {
      pendingUsers.remove(userName);
    });

    if (!mounted) return;

    ShadToaster.of(context).show(
      ShadToast(
        description: Text("${capitalizeStr(userName)}'s request $actionText."),
      ),
    );

    if (pendingUsers.isEmpty) {
      Navigator.of(context).pop();
      widget.onComplete();
    }
  }

  void onActionError(String message) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(message)),
    );
  }

  /// Whether approving [userName] is greyed out for lack of credit on a
  /// programme with credit on (club_core#105, R35).
  bool unfunded(String userName, {required bool gated}) =>
      gated &&
      ref.watch(
            clCreditUsableForEventProvider((
              username: userName,
              eventId: widget.eventId,
              trial: false,
            )),
          ) ==
          0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final gated =
        ref.watch(
              clEventsMasterProvider.select(
                (s) => s.valueOrNull?[widget.eventId]?.type,
              ),
            ) ==
            EventType.programme &&
        ref.watch(creditSystemProvider) == true;

    return ShadDialog(
      title: const Text('Manage Requests'),
      description: Text(
        pendingUsers.isEmpty
            ? 'No pending requests.'
            : '${pendingUsers.length} member(s) requesting to join',
      ),
      child: pendingUsers.isEmpty
          ? const SizedBox.shrink()
          : SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: pendingUsers.map((userName) {
                  final avatarUrl = ref
                      .watch(avatarImageProvider(userName))
                      .value;
                  final headers =
                      ref.watch(imageAuthHeadersProvider).value ?? const {};
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        AvatarBubble(
                          imageUrl: avatarUrl,
                          httpHeaders: headers,
                          fallbackLetter: userName[0].toUpperCase(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                capitalizeStr(userName),
                                style: theme.textTheme.small,
                              ),
                              Text(
                                'Requesting to join',
                                style: theme.textTheme.muted,
                              ),
                            ],
                          ),
                        ),
                        if (_running[userName] == 'reject')
                          ActionIcon(
                            key: ValueKey('reject-request-$userName'),
                            icon: Icons.close,
                            loading: true,
                          )
                        else
                          ActionIcon(
                            key: ValueKey('reject-request-$userName'),
                            icon: Icons.close,
                            color: theme.colorScheme.destructive,
                            enabled: !_isBusy(userName),
                            onPressed: () => _reject(userName),
                          ),
                        const SizedBox(width: 4),
                        if (unfunded(userName, gated: gated)) ...[
                          CreditChip(username: userName, credits: 0),
                          const SizedBox(width: 4),
                        ],
                        if (_running[userName] == 'approve')
                          ActionIcon(
                            key: ValueKey('approve-request-$userName'),
                            icon: Icons.check,
                            loading: true,
                          )
                        else
                          ActionIcon(
                            key: ValueKey('approve-request-$userName'),
                            icon: Icons.check,
                            color: theme.colorScheme.primary,
                            enabled:
                                !_isBusy(userName) &&
                                !unfunded(userName, gated: gated),
                            onPressed: () => _approve(userName),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Future<bool> showRejectConfirmation(
    BuildContext context,
    String userName,
  ) {
    return ConfirmDialog.show(
      context,
      title: 'Reject Request',
      message:
          "Are you sure you want to reject ${capitalizeStr(userName)}'s "
          'request to join?',
      confirmLabel: 'Reject',
      destructive: true,
    );
  }
}

class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    required this.imageUrl,
    required this.httpHeaders,
    required this.fallbackLetter,
    super.key,
  });

  final String? imageUrl;
  final Map<String, String> httpHeaders;
  final String fallbackLetter;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    const size = 40.0;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(fallbackLetter, style: theme.textTheme.small),
    );
    if (imageUrl == null) return fallback;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CredentialedNetworkImage(
          imageUrl: imageUrl!,
          httpHeaders: httpHeaders,
          fit: BoxFit.cover,
          errorBuilder: (_) => fallback,
        ),
      ),
    );
  }
}
