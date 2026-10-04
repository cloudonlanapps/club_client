import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SemanticColors;

/// Displays four stat cards (Total, Active, Pending, Blocked) in a responsive
/// wrap layout. Watches [clUserStatsProvider] for the aggregated counts.
class UserStatsBar extends ConsumerWidget {
  const UserStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(clUserStatsProvider);
    final data = stats.valueOrNull ?? const ClUserStatsData();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 600
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Total Users',
                value: '${data.total}',
                icon: LucideIcons.users,
                color: SemanticColors.info,
                bgColor: SemanticColors.infoLight,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Active',
                value: '${data.activeCount}',
                icon: LucideIcons.circleCheck,
                color: SemanticColors.success,
                bgColor: SemanticColors.successLight,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Pending',
                value: '${data.pendingCount}',
                icon: LucideIcons.clock,
                color: SemanticColors.warning,
                bgColor: SemanticColors.warningLight,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                label: 'Blocked',
                value: '${data.blockedCount}',
                icon: LucideIcons.ban,
                color: SemanticColors.purple,
                bgColor: SemanticColors.purpleLight,
              ),
            ),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.h3.copyWith(fontSize: 22),
          ),
          Text(
            label,
            style: theme.textTheme.muted.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
