import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/reapply_sizes.dart';

/// The note an admin left when sending a registration back, shown above the
/// reapply form.
class ReviewNoteBanner extends StatelessWidget {
  const ReviewNoteBanner({required this.note, super.key});

  /// The admin's note.
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(ReapplySizes.noteRadius),
        color: colors.muted,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ReapplySizes.notePadding),
        child: Text(note, style: theme.textTheme.small),
      ),
    );
  }
}
