import 'package:cl_club_forms/cl_club_forms.dart' show MarketingFormDraft;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../models/marketing_read_entry.dart';
import '../../utils/marketing_save_error.dart';
import 'marketing_read_rows.dart';

/// Builds a marketing section's form with the card's [key], [enabled] and
/// an [onChanged] that reports each edit.
typedef MarketingFormBuilder =
    Widget Function({
      required GlobalKey key,
      required bool enabled,
      required VoidCallback onChanged,
    });

/// One section of an event's Marketing page (club_client#1): the shared
/// [EditableSectionCard] with a marketing form, which reports what is being
/// typed to [onDraft] for the live preview and saves through [onSave].
///
/// [onDraft] is given the form's values on every edit and null once the
/// editor closes, saved or cancelled. A refused save toasts what went
/// wrong and keeps the editor open.
class EventMarketingSectionCard extends StatefulWidget {
  const EventMarketingSectionCard({
    required this.title,
    required this.icon,
    required this.entries,
    required this.formBuilder,
    required this.onSave,
    required this.onDraft,
    required this.savedMessage,
    this.read,
    this.emptyHint = 'Nothing here yet. Tap to add.',
    super.key,
  });

  /// Widest the inline editor grows.
  static const double editMaxWidth = 720;

  /// The card's heading.
  final String title;

  /// The heading's icon.
  final IconData icon;

  /// The read view's lines; the card reads as empty when none has a value.
  final List<MarketingReadEntry> entries;

  /// The read view, when it is more than [entries] (a list of rows).
  final Widget? read;

  /// Builds the section's form.
  final MarketingFormBuilder formBuilder;

  /// Stores the form's values.
  final Future<void> Function(Map<String, dynamic> values) onSave;

  /// Given what is being typed, or null when the editor closes.
  final ValueChanged<Map<String, dynamic>?> onDraft;

  /// The toast after a save, naming the section.
  final String savedMessage;

  /// What an empty card says to an editor.
  final String emptyHint;

  @override
  State<EventMarketingSectionCard> createState() =>
      EventMarketingSectionCardState();
}

/// State of [EventMarketingSectionCard]: the key of its form.
class EventMarketingSectionCardState extends State<EventMarketingSectionCard> {
  final GlobalKey formKey = GlobalKey();

  /// The form's state, while the editor is open.
  MarketingFormDraft? get form => formKey.currentState as MarketingFormDraft?;

  Future<bool> save(Map<String, dynamic> values) async {
    try {
      await widget.onSave(values);
      if (!mounted) return true;
      ShadToaster.of(
        context,
      ).show(ShadToast(description: Text(widget.savedMessage)));
      return true;
    } on Object catch (e, st) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            marketingSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not save ${widget.title}. Please try again.',
            ),
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditableSectionCard<Map<String, dynamic>>(
      title: widget.title,
      leadingIcon: widget.icon,
      canEdit: true,
      isEmpty:
          widget.read == null && MarketingReadRows.isEmptyOf(widget.entries),
      emptyHint: widget.emptyHint,
      editMaxWidth: EventMarketingSectionCard.editMaxWidth,
      read: widget.read ?? MarketingReadRows(entries: widget.entries),
      editBuilder: ({required enabled}) => widget.formBuilder(
        key: formKey,
        enabled: enabled,
        onChanged: () => widget.onDraft(form?.draft),
      ),
      onValidate: () => form?.validate(),
      isDirty: () => form?.isDirty ?? false,
      onSave: save,
      onEditingChanged: (editing) {
        if (!editing) widget.onDraft(null);
      },
    );
  }
}
