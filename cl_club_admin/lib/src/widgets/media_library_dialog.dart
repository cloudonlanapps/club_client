import 'package:cl_remote_store/cl_remote_store.dart'
    show clMediaLibraryProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'media_library_row.dart';

/// Opens the media library for [title] and resolves to the item picked, or
/// `null` when dismissed.
Future<MediaRef?> showMediaLibraryDialog(
  BuildContext context, {
  required String title,
}) {
  return showShadDialog<MediaRef>(
    context: context,
    builder: (_) => MediaLibraryDialog(title: title),
  );
}

/// The images and videos already on the server, for linking to a website
/// slot. Only public items can be linked; the rest say why not.
class MediaLibraryDialog extends ConsumerWidget {
  const MediaLibraryDialog({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final library = ref.watch(clMediaLibraryProvider);
    return ShadDialog(
      title: Text(title),
      description: const Text(
        'Only public media can fill a website slot.',
      ),
      actions: [
        ShadButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
      child: SizedBox(
        width: 480,
        height: 420,
        child: library.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              "Couldn't load the media library.",
              style: theme.textTheme.muted,
            ),
          ),
          data: (items) => items.isEmpty
              ? Center(
                  child: Text('No media yet.', style: theme.textTheme.muted),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, i) => MediaLibraryRow(
                    media: items[i],
                    // Closes the dialog this widget's opener pushed.
                    onLink: (picked) => Navigator.of(context).pop(picked),
                  ),
                ),
        ),
      ),
    );
  }
}
