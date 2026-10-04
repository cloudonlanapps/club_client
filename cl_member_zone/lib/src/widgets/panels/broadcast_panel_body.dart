import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:cl_club_communication/cl_club_communication.dart'
    show showWriteFailure;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import 'shared/broadcast_row.dart';

/// Shown when revoking a broadcast fails.
const String revokeFailedMessage =
    'Could not revoke the broadcast. Please try again.';

/// Shown when sending a broadcast fails.
const String sendFailedMessage =
    'Could not send the broadcast. Please try again.';

/// Broadcast panel body (admin only — visibility is enforced by the panel
/// registry via `PanelRole.adminOnly`).
///
/// Two presentations driven by [onClose]:
/// - Panel (onClose == null): fixed height, three most-recent broadcasts,
///   "See more" button.
/// - Screen (onClose != null): fills available height, shows every active
///   broadcast in a scroll view, and renders a Close button next to Send.
class BroadcastPanelBody extends ConsumerStatefulWidget {
  const BroadcastPanelBody({this.onClose, super.key});

  /// When supplied, the body switches to its full-screen presentation and
  /// renders a Close button alongside Send that invokes this callback.
  final VoidCallback? onClose;

  static const int _panelLimit = 3;
  static const double _panelBodyHeight = 296;
  static const int _panelInputLines = 3;
  static const int _screenInputLines = 6;

  @override
  ConsumerState<BroadcastPanelBody> createState() => BroadcastPanelBodyState();
}

class BroadcastPanelBodyState extends ConsumerState<BroadcastPanelBody> {
  /// Default subject applied when the admin sends an email broadcast without
  /// customizing the subject (see issue #737). Named after the club supplying
  /// [appBrandingProvider], so the text follows whichever club is running.
  String get _defaultEmailSubject =>
      'Broadcast Message from ${ref.read(appBrandingProvider).shortName}';

  Future<void> _revoke(int id) async {
    try {
      await ref.read(clBroadcastsMasterProvider.notifier).revoke(id);
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Broadcast revoked.')),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not revoke: ${e.message}'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      showWriteFailure(context, e, revokeFailedMessage);
    }
  }

  Future<bool> _send(BroadcastComposeResult result) async {
    try {
      await ref
          .read(clBroadcastsMasterProvider.notifier)
          .sendText(
            result.text,
            email: result.sendEmail,
            emailSubject: result.emailSubject ?? _defaultEmailSubject,
          );
      if (!mounted) return true;
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(
            result.sendEmail
                ? 'Broadcast sent (with email).'
                : 'Broadcast sent.',
          ),
        ),
      );
      return true;
    } on ServerException catch (e) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not send: ${e.message}'),
        ),
      );
      return false;
    } on Object catch (e) {
      if (!mounted) return false;
      showWriteFailure(context, e, sendFailedMessage);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clBroadcastsMasterProvider);
    final isScreen = widget.onClose != null;
    final inputLines = isScreen
        ? BroadcastPanelBody._screenInputLines
        : BroadcastPanelBody._panelInputLines;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BroadcastComposer(
          placeholder: 'Type a message to send to everyone…',
          maxLines: inputLines,
          onSend: _send,
          onClose: isScreen ? widget.onClose : null,
        ),
        SizedBox(height: isScreen ? 20 : 12),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'Could not load broadcasts: $e',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            data: (map) {
              final active =
                  map.values
                      .where((b) => b.status != BroadcastStatus.revoked)
                      .toList()
                    ..sort((a, b) => b.sentAtUtc.compareTo(a.sentAtUtc));
              if (active.isEmpty) {
                return const Center(
                  child: Text(
                    'No broadcasts yet',
                    style: TextStyle(fontSize: 12),
                  ),
                );
              }
              final visible = isScreen
                  ? active
                  : active.take(BroadcastPanelBody._panelLimit).toList();
              return ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final b = visible[index];
                  return BroadcastRow(
                    broadcast: b,
                    onRevoke: () => _revoke(b.id),
                  );
                },
              );
            },
          ),
        ),
        if (!isScreen)
          Align(
            alignment: Alignment.centerRight,
            child: ShadTooltip(
              builder: (_) => const Text('Full broadcast screen coming soon'),
              child: const ShadButton.ghost(
                child: Text('See more'),
              ),
            ),
          ),
      ],
    );

    if (isScreen) return content;
    return SizedBox(
      height: BroadcastPanelBody._panelBodyHeight,
      child: content,
    );
  }
}
