import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Generic list body for a dashboard "today" panel.
///
/// Watches [source] for an `AsyncValue<List<Occurrence>>`, renders one row per
/// occurrence via [rowBuilder], and shows a centered spinner / muted error /
/// empty placeholder for the corresponding async states.
class DayOccurrencesList extends ConsumerWidget {
  const DayOccurrencesList({
    required this.source,
    required this.rowBuilder,
    required this.emptyText,
    required this.errorPrefix,
    super.key,
  });

  final ProviderListenable<AsyncValue<List<Occurrence>>> source;
  final Widget Function(Occurrence) rowBuilder;
  final String emptyText;
  final String errorPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final occurrencesAsync = ref.watch(source);

    return occurrencesAsync.when(
      loading: () => const CenteredSpinner(),
      error: (e, _) => Center(
        child: Text(
          '$errorPrefix: $e',
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
      ),
      data: (occurrences) {
        if (occurrences.isEmpty) {
          return Center(
            child: Text(emptyText, style: theme.textTheme.muted),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: occurrences.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => rowBuilder(occurrences[i]),
        );
      },
    );
  }
}

class CenteredSpinner extends StatelessWidget {
  const CenteredSpinner({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}
