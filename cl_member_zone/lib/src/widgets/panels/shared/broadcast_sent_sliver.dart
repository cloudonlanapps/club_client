import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'broadcast_layout.dart' show BroadcastLayout;
import 'broadcast_row.dart';

/// The broadcasts a Broadcast screen has sent, as a sliver: the part of the
/// screen that scrolls below the fixed composer ([BroadcastLayout],
/// club_client#269).
///
/// Revoked broadcasts are left out. While [sent] loads, fails or holds
/// nothing, the sliver fills the space below the composer with a centred
/// spinner or message.
class BroadcastSentSliver extends StatelessWidget {
  const BroadcastSentSliver({
    required this.sent,
    required this.onRevoke,
    super.key,
  });

  /// The broadcasts sent from the screen's scope, newest first.
  final AsyncValue<List<Broadcast>> sent;

  /// Revokes the broadcast with this id.
  final ValueChanged<int> onRevoke;

  /// The side of the loading spinner.
  static const double spinnerSize = 18;

  /// The text size of the empty and error messages.
  static const double messageFontSize = 12;

  @override
  Widget build(BuildContext context) {
    return sent.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'Could not load broadcasts: $e',
            style: const TextStyle(fontSize: messageFontSize),
          ),
        ),
      ),
      data: (all) {
        final active = all
            .where((b) => b.status != BroadcastStatus.revoked)
            .toList();
        if (active.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No broadcasts yet',
                style: TextStyle(fontSize: messageFontSize),
              ),
            ),
          );
        }
        return SliverList.separated(
          itemCount: active.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final b = active[index];
            return BroadcastRow(broadcast: b, onRevoke: () => onRevoke(b.id));
          },
        );
      },
    );
  }
}
