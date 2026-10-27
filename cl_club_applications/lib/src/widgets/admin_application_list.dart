import 'package:cl_remote_store/cl_remote_store.dart'
    show clApplicationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionItem, EntityCard, EntityImage, textInitial;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../utils/application_title.dart';

/// An admin's list of every application template, newest first, each with
/// its state as plain text, opening on tap, with **Duplicate**: a new draft
/// copied from it, which then opens.
class AdminApplicationList extends ConsumerStatefulWidget {
  const AdminApplicationList({required this.onOpen, super.key});

  /// Opens the template with this id.
  final ValueChanged<int> onOpen;

  @override
  ConsumerState<AdminApplicationList> createState() =>
      AdminApplicationListState();
}

/// State of [AdminApplicationList]: the duplicate in flight.
class AdminApplicationListState extends ConsumerState<AdminApplicationList> {
  /// The template being duplicated, if any.
  int? duplicating;

  /// Copies template [id] and opens the copy.
  Future<void> duplicate(int id) async {
    if (duplicating != null) return;
    setState(() => duplicating = id);
    try {
      final copy = await ref
          .read(clApplicationsMasterProvider.notifier)
          .duplicateApplication(id);
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text(ApplicationViewStrings.duplicated)),
      );
      widget.onOpen(copy.id);
    } on Object catch (_) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text(ApplicationViewStrings.writeFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => duplicating = null);
    }
  }

  /// [template]'s caption: its state and, once saved, its layout.
  static String caption(ApplicationTemplate template) => [
    ApplicationViewStrings.statusLabels[template.status.wireName] ??
        template.status.wireName,
    ?template.layout?.name,
  ].join(ApplicationViewStrings.separator);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final templates = ref.watch(clApplicationsMasterProvider);
    if (templates.isLoading && !templates.hasValue) {
      return const Center(child: ShadProgress());
    }
    if (!templates.hasValue) {
      return Text(
        ApplicationViewStrings.loadFailed,
        style: theme.textTheme.muted,
      );
    }
    final list = templates.requireValue.values.toList()
      ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    if (list.isEmpty) {
      return Text(
        ApplicationViewStrings.noTemplates,
        style: theme.textTheme.muted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ApplicationViewSizes.rowGap,
      children: [
        for (final template in list)
          EntityCard(
            key: ValueKey('application.row.${template.id}'),
            image: EntityImage.initials(
              textInitial(applicationTitle(template)),
            ),
            title: applicationTitle(template),
            caption: caption(template),
            onTap: () => widget.onOpen(template.id),
            trailingActions: [
              ActionItem(
                label: ApplicationViewStrings.duplicate,
                icon: LucideIcons.copy,
                loading: duplicating == template.id,
                onPressed: duplicating == null
                    ? () => duplicate(template.id)
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}
