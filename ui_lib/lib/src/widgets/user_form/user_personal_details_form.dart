import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/read_only_field.dart';
import 'package:ui_lib/src/widgets/signup/signup_form.dart' show SignupGender;
import 'package:ui_lib/src/widgets/user_form/user_form_validators.dart';

/// Pure-UI editor for a user's personal details — names, nickname, public-name
/// flag, gender, and date of birth (the "Personal details" profile section).
///
/// Date of birth and gender are protected fields: editable only when
/// [canEditDateOfBirth] / [canEditGender] is true (super-admin). When not
/// editable they render read-only and are omitted from the returned map, so
/// the partial update never trips the server's protected-field guard.
///
/// Host-agnostic: drive it through a `GlobalKey<UserPersonalDetailsFormState>`,
/// calling [UserPersonalDetailsFormState.validate] from the Save action.
class UserPersonalDetailsForm extends StatefulWidget {
  const UserPersonalDetailsForm({
    required this.initialValues,
    this.canEditDateOfBirth = false,
    this.canEditGender = false,
    this.canEditUseNamePublicly = false,
    this.canEditPublicProfile = false,
    super.key,
  });

  /// Reads `firstName`, `middleName`, `lastName`, `nickname`,
  /// `useNamePublicly`, `isPublicProfile`, `gender` (SignupGender?),
  /// `dateOfBirthUtc` (DateTime?).
  final Map<String, dynamic> initialValues;
  final bool canEditDateOfBirth;
  final bool canEditGender;
  final bool canEditUseNamePublicly;

  /// When true, render the **coach-owned** public-profile controls: an
  /// `isPublicProfile` checkbox plus the `useNamePublicly` checkbox, where the
  /// latter is disabled and forced false unless the profile is public. The
  /// host sets this only when the viewer is the user themselves and a coach.
  final bool canEditPublicProfile;

  @override
  State<UserPersonalDetailsForm> createState() =>
      UserPersonalDetailsFormState();
}

class UserPersonalDetailsFormState extends State<UserPersonalDetailsForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? _formError;

  late bool _isPublicProfile =
      widget.initialValues['isPublicProfile'] as bool? ?? false;

  String _initial(String id) => widget.initialValues[id] as String? ?? '';

  /// Validates (including the "at least one name" cross-field rule). Returns
  /// the edited field values when valid, else `null`. Gender / DOB are
  /// included only when editable.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final v = form.value;

    final nameError = UserFormValidators.atLeastOneName(
      v['firstName'] as String?,
      v['lastName'] as String?,
    );
    if (nameError != null) {
      setState(() => _formError = nameError);
      return null;
    }

    final result = <String, dynamic>{
      'firstName': v['firstName'],
      'middleName': v['middleName'],
      'lastName': v['lastName'],
      'nickname': v['nickname'],
      if (widget.canEditGender) 'gender': v['gender'],
      if (widget.canEditDateOfBirth) 'dateOfBirthUtc': v['dateOfBirthUtc'],
    };
    if (widget.canEditPublicProfile) {
      result['isPublicProfile'] = _isPublicProfile;
      // Coupling: a public name only applies to a public profile.
      result['useNamePublicly'] =
          _isPublicProfile && (v['useNamePublicly'] as bool? ?? false);
    } else if (widget.canEditUseNamePublicly) {
      result['useNamePublicly'] = v['useNamePublicly'];
    }
    return result;
  }

  /// Whether any editable field differs from its initial value. Gender / DOB /
  /// public-name are considered only when the editor was allowed to change
  /// them, matching [validate].
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    final v = form.value;
    const nameIds = ['firstName', 'middleName', 'lastName', 'nickname'];
    for (final id in nameIds) {
      if ((v[id] as String? ?? '') != _initial(id)) return true;
    }
    if (widget.canEditPublicProfile) {
      if (_isPublicProfile !=
          (widget.initialValues['isPublicProfile'] as bool? ?? false)) {
        return true;
      }
      final effectiveUseName =
          _isPublicProfile && (v['useNamePublicly'] as bool? ?? false);
      if (effectiveUseName !=
          (widget.initialValues['useNamePublicly'] as bool? ?? false)) {
        return true;
      }
    } else if (widget.canEditUseNamePublicly &&
        (v['useNamePublicly'] as bool? ?? false) !=
            (widget.initialValues['useNamePublicly'] as bool? ?? false)) {
      return true;
    }
    if (widget.canEditGender && v['gender'] != widget.initialValues['gender']) {
      return true;
    }
    if (widget.canEditDateOfBirth &&
        v['dateOfBirthUtc'] != widget.initialValues['dateOfBirthUtc']) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadInputFormField(
            id: 'firstName',
            label: const Text('First name'),
            initialValue: _initial('firstName'),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'middleName',
            label: const Text('Middle name'),
            initialValue: _initial('middleName'),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'lastName',
            label: const Text('Last name'),
            initialValue: _initial('lastName'),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'nickname',
            label: const Text('Nickname'),
            initialValue: _initial('nickname'),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _publicProfileFields(),
          const SizedBox(height: 12),
          _genderField(),
          const SizedBox(height: 12),
          _dateOfBirthField(),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(
              _formError!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The public-name / public-profile controls.
  ///
  /// - Coach editing their own profile (`canEditPublicProfile`): an
  ///   `isPublicProfile` checkbox plus a `useNamePublicly` checkbox that is
  ///   disabled and forced false while the profile is not public.
  /// - Super-admin (`canEditUseNamePublicly`, non-self): the standalone
  ///   `useNamePublicly` checkbox (unchanged).
  /// - Otherwise: a read-only "Show name publicly" row.
  Widget _publicProfileFields() {
    if (widget.canEditPublicProfile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadCheckboxFormField(
            id: 'isPublicProfile',
            initialValue: _isPublicProfile,
            onChanged: (v) => setState(() => _isPublicProfile = v),
            label: const Text('Show my profile publicly'),
          ),
          const SizedBox(height: 12),
          ShadCheckboxFormField(
            // Re-key on the toggle so the field resets to false (and disabled)
            // when the profile is made non-public.
            key: ValueKey('useNamePublicly-$_isPublicProfile'),
            id: 'useNamePublicly',
            enabled: _isPublicProfile,
            initialValue:
                _isPublicProfile &&
                (widget.initialValues['useNamePublicly'] as bool? ?? false),
            label: const Text('Show my name on my public profile'),
          ),
        ],
      );
    }
    if (widget.canEditUseNamePublicly) {
      return ShadCheckboxFormField(
        id: 'useNamePublicly',
        initialValue: widget.initialValues['useNamePublicly'] as bool? ?? false,
        label: const Text('Show name publicly'),
      );
    }
    return ReadOnlyField(
      label: 'Show name publicly',
      value: (widget.initialValues['useNamePublicly'] as bool? ?? false)
          ? 'Yes'
          : 'No',
    );
  }

  Widget _genderField() {
    if (!widget.canEditGender) {
      return ReadOnlyField(
        label: 'Gender',
        value:
            (widget.initialValues['gender'] as SignupGender?)?.label ??
            'Not set',
      );
    }
    return ShadSelectFormField<SignupGender>(
      id: 'gender',
      label: const Text('Gender'),
      initialValue: widget.initialValues['gender'] as SignupGender?,
      placeholder: const Text('Select gender'),
      validator: UserFormValidators.gender,
      options: SignupGender.values
          .map((g) => ShadOption(value: g, child: Text(g.label)))
          .toList(),
      selectedOptionBuilder: (context, value) => Text(value.label),
    );
  }

  Widget _dateOfBirthField() {
    final initial = widget.initialValues['dateOfBirthUtc'] as DateTime?;
    if (!widget.canEditDateOfBirth) {
      return ReadOnlyField(
        label: 'Date of birth',
        value: initial != null
            ? DateFormat('d MMM yyyy').format(initial)
            : 'Not set',
      );
    }
    return CLDatePickerFormField(
      id: 'dateOfBirthUtc',
      label: const Text('Date of birth'),
      placeholder: const Text('Select date of birth'),
      initialValue: initial,
      formatDate: (d) => DateFormat('d MMM yyyy').format(d),
      validator: UserFormValidators.dateOfBirth,
    );
  }
}
