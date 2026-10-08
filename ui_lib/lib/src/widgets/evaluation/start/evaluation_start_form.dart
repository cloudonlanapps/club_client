import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_start_options.dart';
import '../common/evaluation_form_body.dart';
import '../common/evaluation_form_contract.dart';
import '../common/evaluation_form_focus.dart';
import 'evaluation_period_fields.dart';
import 'evaluation_period_validators.dart';
import 'evaluation_start_fixed_value.dart';
import 'evaluation_start_form_fields.dart';
import 'evaluation_start_select.dart';

/// Pure-UI form starting an evaluation (no SDK, no Riverpod): the template,
/// the member, the event or *General*, and an optional review period.
///
/// Any of the first three may be fixed by the host — a member's profile
/// fixes the member, an enrolment row the member and the event, a
/// template's *Start* the template — and then shows read-only. Owns no
/// buttons or dialog: the host calls [EvaluationStartFormState.validate]
/// and shows a server refusal with [EvaluationStartFormState.showErrors].
class EvaluationStartForm extends StatefulWidget {
  /// A start form offering [templates], [members] and [events].
  const EvaluationStartForm({
    required this.templates,
    required this.members,
    required this.events,
    this.fixedTemplate,
    this.fixedMember,
    this.fixedEvent,
    this.eventsByMember,
    this.enabled = true,
    super.key,
  });

  /// The templates to choose from.
  final List<EvaluationStartChoice> templates;

  /// The members to choose from.
  final List<EvaluationStartMember> members;

  /// The events to choose from, besides *General*.
  final List<EvaluationStartChoice> events;

  /// The template, when the host fixes it.
  final EvaluationStartChoice? fixedTemplate;

  /// The member, when the host fixes it.
  final EvaluationStartMember? fixedMember;

  /// The event, when the host fixes it.
  final EvaluationStartChoice? fixedEvent;

  /// When given, the events each member may be reviewed for, keyed by
  /// username: the event field then offers only the chosen member's events
  /// (none until a member is chosen), and [events] is not used.
  final Map<String, List<EvaluationStartChoice>>? eventsByMember;

  /// Whether the fields can change (off while the host creates).
  final bool enabled;

  /// The event field's *General* entry.
  static const EvaluationStartEvent general = (
    id: null,
    label: EvaluationStrings.general,
  );

  @override
  State<EvaluationStartForm> createState() => EvaluationStartFormState();
}

/// State of [EvaluationStartForm]: the form and the chosen member.
class EvaluationStartFormState extends State<EvaluationStartForm>
    with
        EvaluationFormContract<EvaluationStartForm>,
        EvaluationFormFocus<EvaluationStartForm> {
  /// The chosen member's username, or `null` before a choice.
  String? memberUsername;

  @override
  void initState() {
    super.initState();
    memberUsername = widget.fixedMember?.username;
  }

  /// The events offered for the chosen member.
  List<EvaluationStartChoice> get eventOptions {
    final byMember = widget.eventsByMember;
    if (byMember == null) return widget.events;
    final username = memberUsername;
    return username == null ? const [] : byMember[username] ?? const [];
  }

  // Selects and date pickers have no input to focus.
  @override
  bool get focusFirstInvalid => false;

  /// Whether a template, a member, an event or a date has been chosen. The
  /// fields seed themselves — nothing chosen, *General*, no dates — so the
  /// form holds no initial values to compare with.
  @override
  bool get isDirty {
    final values = formKey.currentState?.value ?? const <String, dynamic>{};
    final event = values[EvaluationStartFormFields.eventId];
    return values[EvaluationStartFormFields.templateId] != null ||
        values[EvaluationStartFormFields.memberId] != null ||
        (event as EvaluationStartEvent?)?.id != null ||
        values[EvaluationStartFormFields.periodStartId] != null ||
        values[EvaluationStartFormFields.periodEndId] != null;
  }

  /// The period message: one date alone, out of order, or ending after
  /// today.
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      EvaluationPeriodValidators.period(
        values[EvaluationStartFormFields.periodStartId] as DateTime?,
        values[EvaluationStartFormFields.periodEndId] as DateTime?,
      );

  /// The values keyed by [EvaluationStartFormFields], fixed ones included:
  /// the template's id, the member's username and the event's id (`null`
  /// for *General*).
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final template =
        widget.fixedTemplate ??
        values[EvaluationStartFormFields.templateId] as EvaluationStartChoice;
    final member =
        widget.fixedMember ??
        values[EvaluationStartFormFields.memberId] as EvaluationStartMember;
    final event =
        widget.fixedEvent?.id ??
        (values[EvaluationStartFormFields.eventId] as EvaluationStartEvent?)
            ?.id;
    return {
      EvaluationStartFormFields.templateId: template.id,
      EvaluationStartFormFields.memberId: member.username,
      EvaluationStartFormFields.eventId: event,
      EvaluationStartFormFields.periodStartId:
          values[EvaluationStartFormFields.periodStartId],
      EvaluationStartFormFields.periodEndId:
          values[EvaluationStartFormFields.periodEndId],
    };
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return ShadForm(
      key: formKey,
      child: EvaluationFormBody(
        error: formError,
        children: [
          if (w.fixedTemplate case final t?)
            EvaluationStartFixedValue(
              label: EvaluationStrings.template,
              value: t.label,
            )
          else
            EvaluationStartSelect<EvaluationStartChoice>(
              id: EvaluationStartFormFields.templateId,
              label: EvaluationStrings.template,
              placeholder: EvaluationStrings.templatePlaceholder,
              requiredMessage: EvaluationStrings.templateRequired,
              enabled: w.enabled,
              options: [for (final t in w.templates) (t, t.label)],
              // A changed choice or date clears the form-level message.
              onChanged: (_) => setFormError(null),
            ),
          if (w.fixedMember case final m?)
            EvaluationStartFixedValue(
              label: EvaluationStrings.member,
              value: m.label,
            )
          else
            EvaluationStartSelect<EvaluationStartMember>(
              id: EvaluationStartFormFields.memberId,
              label: EvaluationStrings.member,
              placeholder: EvaluationStrings.memberPlaceholder,
              requiredMessage: EvaluationStrings.memberRequired,
              enabled: w.enabled,
              options: [for (final m in w.members) (m, m.label)],
              onChanged: (m) => setState(() {
                memberUsername = m?.username;
                formError = null;
              }),
            ),
          if (w.fixedEvent case final e?)
            EvaluationStartFixedValue(
              label: EvaluationStrings.event,
              value: e.label,
            )
          else
            EvaluationStartSelect<EvaluationStartEvent>(
              // A new member rebuilds the field, back to General.
              key: ValueKey<String?>(memberUsername),
              id: EvaluationStartFormFields.eventId,
              label: EvaluationStrings.event,
              initialValue: EvaluationStartForm.general,
              enabled: w.enabled,
              options: [
                const (
                  EvaluationStartForm.general,
                  EvaluationStrings.general,
                ),
                for (final e in eventOptions)
                  ((id: e.id, label: e.label), e.label),
              ],
              onChanged: (_) => setFormError(null),
            ),
          EvaluationPeriodFields(
            enabled: w.enabled,
            onChanged: () => setFormError(null),
          ),
        ],
      ),
    );
  }
}
