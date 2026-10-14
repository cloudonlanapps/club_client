import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'action_item.dart';

/// Runs [item] picked from an overflow menu. A menu entry cannot anchor a
/// popover, so an item that opens one shows the same content in a dialog
/// titled with its label (#143).
void runOverflowAction(BuildContext context, ActionItem item) {
  if (!item.isActionable) return;
  final popover = item.popover;
  if (popover == null) {
    item.onPressed?.call();
    return;
  }
  unawaited(
    showShadDialog<void>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(item.label),
        child: Builder(builder: popover),
      ),
    ),
  );
}
