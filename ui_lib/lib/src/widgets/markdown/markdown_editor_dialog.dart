import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'markdown_guide_dialog.dart';
import 'themed_markdown.dart';

/// Centered modal dialog for editing markdown with a live preview toggle.
///
/// Renders as a constrained popover (max 720 px wide) with comfortable
/// margins on wide layouts, and collapses to a near-full-bleed sheet on
/// narrow mobile widths so the editor never feels like a full-screen route.
class MarkdownEditorDialog extends StatefulWidget {
  const MarkdownEditorDialog({
    required this.label,
    required this.initialValue,
    required this.onSave,
    super.key,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onSave;

  static const double maxDialogWidth = 720;
  static const double wideInsetPadding = 48;
  static const double narrowInsetPadding = 16;
  static const double narrowBreakpoint = 600;

  /// Height the editor's content never shrinks below: the header, the
  /// footer and about four lines of text. When less room is left above the
  /// keyboard (a phone held sideways), the dialog scrolls instead of
  /// squeezing the text box.
  static const double minContentHeight = 288;

  static Future<void> show(
    BuildContext context, {
    required String label,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MarkdownEditorDialog(
        label: label,
        initialValue: initialValue,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MarkdownEditorDialog> createState() => MarkdownEditorDialogState();
}

class MarkdownEditorDialogState extends State<MarkdownEditorDialog> {
  late TextEditingController controller;
  bool showPreview = false;

  Future<void> showMarkdownHelp() => showMarkdownGuide(context);

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue)
      ..addListener(onTextChanged);
    wasDirty = isDirty;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get isDirty => controller.text != widget.initialValue;

  /// [isDirty] as of the last build, which decides whether the [PopScope]
  /// lets a back gesture or Escape close the editor without asking.
  late bool wasDirty;

  void onTextChanged() {
    if (isDirty != wasDirty) setState(() => wasDirty = isDirty);
  }

  Future<void> handleCancel() async {
    if (!isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PointerInterceptor(
        child: AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void handleSave() {
    widget.onSave(controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // Only the size: the keyboard changes the view insets, which the Dialog
    // already pads by, so the editor does not rebuild as the keyboard moves.
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < MarkdownEditorDialog.narrowBreakpoint;
    final inset = size.shortestSide < MarkdownEditorDialog.narrowBreakpoint
        ? MarkdownEditorDialog.narrowInsetPadding
        : MarkdownEditorDialog.wideInsetPadding;
    final targetWidth = (size.width - inset * 2).clamp(
      0.0,
      MarkdownEditorDialog.maxDialogWidth,
    );

    // Escape, Android back and browser back ask the same question as Cancel
    // when there are changes (#241). The route itself ignores Escape because
    // the barrier is not dismissible, so Escape is routed to maybePop here.
    return PopScope(
      canPop: !wasDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(handleCancel());
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
        },
        // Holds focus inside the dialog so Escape reaches the action above
        // before any field has been focused.
        child: Focus(
          autofocus: true,
          child: PointerInterceptor(
            child: Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: inset,
                vertical: inset,
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                key: const Key('markdownEditorDialogFrame'),
                width: targetWidth,
                // The Dialog sizes this to the room left above the keyboard;
                // the text box takes what the header and footer leave and
                // scrolls inside. Below minContentHeight the whole dialog
                // scrolls instead.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                          constraints.maxHeight,
                          MarkdownEditorDialog.minContentHeight,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.label,
                                    style: theme.textTheme.large,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: showMarkdownHelp,
                                  icon: const Icon(
                                    Icons.help_outline,
                                    size: 20,
                                  ),
                                  tooltip: 'Markdown help',
                                ),
                                IconButton(
                                  onPressed: () => setState(
                                    () => showPreview = !showPreview,
                                  ),
                                  icon: Icon(
                                    showPreview
                                        ? LucideIcons.pencil
                                        : LucideIcons.eye,
                                    size: 20,
                                  ),
                                  tooltip: showPreview ? 'Edit' : 'Preview',
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: theme.colorScheme.border),
                          Flexible(
                            child: showPreview
                                ? SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: controller.text.isEmpty
                                        ? Text(
                                            'Nothing to preview',
                                            style: theme.textTheme.muted,
                                          )
                                        : ListenableBuilder(
                                            listenable: controller,
                                            builder: (context, _) =>
                                                ThemedMarkdown(
                                                  data: controller.text,
                                                  textAlign: TextAlign.justify,
                                                ),
                                          ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      16,
                                      20,
                                      8,
                                    ),
                                    child: TextField(
                                      controller: controller,
                                      maxLines: isNarrow ? 8 : 12,
                                      minLines: isNarrow ? 6 : 8,
                                      textAlignVertical: TextAlignVertical.top,
                                      decoration: InputDecoration(
                                        hintText: 'Write markdown here…',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.border,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          12,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: theme.colorScheme.border,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ShadButton.outline(
                                  onPressed: handleCancel,
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 12),
                                ShadButton(
                                  onPressed: handleSave,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
