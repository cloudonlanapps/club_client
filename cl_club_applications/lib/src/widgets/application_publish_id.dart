import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';

/// A published template's publish ID (club_client#339), the one printed in
/// grey up the side margin of every form downloaded from it, so an admin
/// can match a returned paper form to the version it came from. Small
/// muted text, selectable, with a button that copies it.
class ApplicationPublishId extends StatelessWidget {
  const ApplicationPublishId({required this.publishId, super.key});

  /// The publish ID, a UUID.
  final String publishId;

  /// Copies the ID and says so.
  Future<void> copy(BuildContext context) async {
    final toaster = ShadToaster.of(context);
    await Clipboard.setData(ClipboardData(text: publishId));
    toaster.show(
      const ShadToast(
        description: Text(ApplicationViewStrings.publishIdCopied),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      key: const ValueKey('application.state.publishId'),
      mainAxisSize: MainAxisSize.min,
      spacing: ApplicationViewSizes.reasonGap,
      children: [
        Flexible(
          child: SelectableText(
            ApplicationViewStrings.publishId(publishId),
            style: theme.textTheme.muted,
          ),
        ),
        Semantics(
          label: ApplicationViewStrings.copyPublishId,
          button: true,
          child: ShadIconButton.ghost(
            key: const ValueKey('application.state.copyPublishId'),
            width: 28,
            height: 28,
            icon: const Icon(LucideIcons.copy, size: 14),
            onPressed: () => copy(context),
          ),
        ),
      ],
    );
  }
}
