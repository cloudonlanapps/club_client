import 'package:cl_club_members/src/models/group_form_helpers.dart'
    show GroupFormSubmit, buildGroupFormInitialValues;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupMembersProvider, clGroupsMasterProvider, formAgeFromSdk;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        AgeEligibilitySummary,
        EditableSectionCard,
        GroupEligibilityForm,
        GroupEligibilityFormState;

/// Human-readable eligibility section for a group, edited in place.
///
/// Read mode renders prose explaining the membership rules (kind, gender),
/// then the age sentence with the server's dates and reference day beneath
/// ([AgeEligibilitySummary]). When [canEdit] is true, the section flips into
/// an inline [GroupEligibilityForm]; criteria are locked while the group has
/// members so an edit can't strand existing members. With [canEdit] false it
/// is a plain read-only card (e.g. a member viewing their own group).
class GroupEligibilitySection extends ConsumerStatefulWidget {
  const GroupEligibilitySection({
    required this.group,
    this.canEdit = false,
    super.key,
  });

  final Group group;

  /// Whether the viewer may edit the eligibility (admin of an active group).
  final bool canEdit;

  @override
  ConsumerState<GroupEligibilitySection> createState() =>
      _GroupEligibilitySectionState();
}

class _GroupEligibilitySectionState
    extends ConsumerState<GroupEligibilitySection> {
  final _formKey = GlobalKey<GroupEligibilityFormState>();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final group = widget.group;
    final lines = _buildSentences(group);
    // Only look at the member list when editing is possible — a read-only
    // member view shouldn't trigger that fetch.
    final hasMembers =
        widget.canEdit &&
        (ref.watch(clGroupMembersProvider(group.id)).valueOrNull?.isNotEmpty ??
            false);

    final initialValues = buildGroupFormInitialValues(group);

    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Eligibility',
      canEdit: widget.canEdit,
      editMaxWidth: 420,
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(lines[i], style: theme.textTheme.p),
          ],
          if (group.minAge != null || group.maxAge != null) ...[
            const SizedBox(height: 8),
            AgeEligibilitySummary(
              minAge: formAgeFromSdk(group.minAge),
              maxAge: formAgeFromSdk(group.maxAge),
              dobOnOrAfter: group.dobOnOrAfterUtc,
              dobOnOrBefore: group.dobOnOrBeforeUtc,
              referenceDay: group.eligibilityReferenceDayUtc,
            ),
          ],
        ],
      ),
      editBuilder: () => GroupEligibilityForm(
        key: _formKey,
        initialValues: initialValues,
        criteriaLocked: hasMembers,
        // The card's Reset shows only while the form holds a value.
        onChanged: () => setState(() {}),
      ),
      onValidate: () => _formKey.currentState?.validate(),
      isDirty: () => _formKey.currentState?.isDirty ?? false,
      onSave: _save,
      onReset: () => _formKey.currentState?.reset(),
      // Never while the mode is locked. Before the form is mounted (the
      // frame the editor opens on), what it is about to be seeded with
      // answers.
      canReset: () =>
          !hasMembers &&
          (_formKey.currentState?.hasValue ??
              GroupEligibilityForm.holdsValue(initialValues)),
    );
  }

  Future<bool> _save(Map<String, dynamic> values) async {
    try {
      await GroupFormSubmit.updateEligibility(
        values: values,
        groupId: widget.group.id,
        notifier: ref.read(clGroupsMasterProvider.notifier),
      );
      if (!mounted) return true;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Eligibility updated.')),
      );
      return true;
    } on ServerException catch (e) {
      if (!mounted) return false;
      final message = switch (e.code) {
        SdkErrorCode.membersExist =>
          'This group still has members. Remove them before switching to '
              'auto.',
        SdkErrorCode.membersIneligible => _ineligibleMessage(e),
        _ => 'Could not save. Please try again.',
      };
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(message)),
      );
      return false;
    } on Object catch (_) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not save. Please try again.'),
        ),
      );
      return false;
    }
  }

  String _ineligibleMessage(ServerException e) {
    final names =
        (e.details?['membernames'] as List?)
            ?.map((n) => n.toString())
            .toList() ??
        const <String>[];
    final namesText = names.isEmpty ? 'some members' : names.join(', ');
    return "These members don't meet the new criteria: $namesText. "
        'Remove or update them, then retry.';
  }

  static List<String> _buildSentences(Group group) {
    final lines = <String>[_kindSentence(group.kind)];
    final genderLine = _genderSentence(group.gender);
    if (genderLine != null) lines.add(genderLine);
    return lines;
  }

  static String _kindSentence(GroupKind kind) {
    switch (kind) {
      case GroupKind.auto:
        return 'This group is automatically generated with eligibility '
            'criteria.';
      case GroupKind.semiAuto:
        return 'This group uses eligibility criteria. Only eligible members '
            'can be added or request to join.';
      case GroupKind.manual:
        return 'This group is open to all.';
    }
  }

  static String? _genderSentence(Gender? gender) {
    if (gender == null) return null;
    switch (gender) {
      case Gender.male:
        return 'This group is only for Boys.';
      case Gender.female:
        return 'This group is only for Girls.';
      case Gender.other:
        return 'This group is only for members who identify as Other.';
      case Gender.preferNotToSay:
        return null;
    }
  }
}
