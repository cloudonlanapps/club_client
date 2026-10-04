import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/read_only_field.dart';
import 'package:ui_lib/src/widgets/signup/signup_form.dart' show SignupGender;
import 'package:ui_lib/src/widgets/signup/username_availability_field.dart';
import 'package:ui_lib/src/widgets/user_form/indian_states.dart';
import 'package:ui_lib/src/widgets/user_form/user_form_assembly.dart';
import 'package:ui_lib/src/widgets/user_form/user_form_validators.dart';

/// Reusable user profile form — fields only, no action buttons.
///
/// SDK-free: the form speaks flat field ids and the form-local [SignupGender];
/// the caller adapts to / from SDK types (see `cl_club_members`
/// `user_form_helpers.dart`). Pre-fill via [initialValues] (field id → value).
///
/// When [readOnlyUsername] is null the form is in **create mode**: an editable
/// username field (with availability check) and password fields are shown,
/// update-only fields are hidden. When [readOnlyUsername] is provided the form
/// is in **edit mode**: the username is shown read-only and password is hidden.
///
/// The parent owns the Save / Cancel buttons and calls
/// [UserFormState.handleSubmit] or reads [UserFormState.isDirty].
class UserForm extends StatefulWidget {
  const UserForm({
    required this.onSubmit,
    this.title,
    this.readOnlyUsername,
    this.initialValues,
    this.onCheckUsernameAvailable,
    this.onShowDefaultPassword,
    this.isSubmitting = false,
    this.canEditDateOfBirth = false,
    this.canEditGender = false,
    this.canEditUseNamePublicly = false,
    this.canAssignAdmin = false,
    this.canAssignCoach = false,
    this.onCanSubmitChanged,
    super.key,
  });

  /// Optional title shown above the form fields.
  final String? title;

  /// `null` → create mode (editable username). Non-null → edit mode, shown
  /// read-only at the top of the form.
  final String? readOnlyUsername;

  /// Pre-fill values keyed by field id. `null` means an empty form.
  final Map<String, dynamic>? initialValues;

  final Future<void> Function(Map<String, dynamic> formValues) onSubmit;

  /// Resolves to `true` when the username is available. Required in create
  /// mode; never invoked in edit mode.
  final Future<bool> Function(String username)? onCheckUsernameAvailable;

  /// Invoked when the admin taps "Show" beside the default-password toggle.
  /// When null, the "Show" affordance is hidden.
  final VoidCallback? onShowDefaultPassword;

  final bool isSubmitting;
  final bool canEditDateOfBirth;
  final bool canEditGender;
  final bool canEditUseNamePublicly;

  /// Whether to show the "Admin" role toggle in create mode. Caller is
  /// responsible for confirming that the current user has permission to
  /// grant the admin role (super admin only).
  final bool canAssignAdmin;

  /// Whether to show the "Coach" role toggle in create mode. Caller is
  /// responsible for confirming that the current user has permission to
  /// grant the coach role (admin or super admin).
  final bool canAssignCoach;

  /// Fires whenever [UserFormState.canSubmit] flips. Lets the parent gate
  /// its submit button without subclassing or polling the state.
  final ValueChanged<bool>? onCanSubmitChanged;

  @override
  State<UserForm> createState() => UserFormState();
}

class UserFormState extends State<UserForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// Whether the admin chose to skip typing a password and use the project
  /// default. Only meaningful in create mode. Drives password-field
  /// visibility live as the toggle is flipped.
  bool useDefaultPassword = true;

  /// Latest username text reported by [UsernameAvailabilityField].
  /// Create-mode only.
  String currentUsername = '';

  /// The username that the embedded availability widget has confirmed
  /// is available; cleared when the user edits the field. `null` until
  /// the admin runs **Check availability**. Submit is blocked until
  /// this equals [currentUsername].
  String? confirmedAvailableUsername;

  bool _lastCanSubmit = false;

  @override
  void initState() {
    super.initState();
    _lastCanSubmit = canSubmit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCanSubmitChanged?.call(_lastCanSubmit);
    });
  }

  @override
  void didUpdateWidget(covariant UserForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notifyCanSubmitIfChanged();
  }

  void _notifyCanSubmitIfChanged() {
    final next = canSubmit;
    if (next == _lastCanSubmit) return;
    _lastCanSubmit = next;
    final cb = widget.onCanSubmitChanged;
    if (cb == null) return;
    // Defer: didUpdateWidget runs during the parent's build phase, so a
    // synchronous callback that triggers parent setState would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(next);
    });
  }

  void onAvailabilityChanged(String username, String? confirmed) {
    if (!mounted) return;
    setState(() {
      currentUsername = username;
      confirmedAvailableUsername = confirmed;
    });
    // Clear any stale "Run the availability check…" error left over from a
    // prior submit attempt. The embedded widget's own UI now reflects the
    // current state; the form-level field error is no longer accurate.
    formKey.currentState?.setFieldError('username', null);
    _notifyCanSubmitIfChanged();
  }

  /// Whether submission is currently allowed. The parent view consults
  /// this before invoking [handleSubmit] in create mode.
  bool get canSubmit {
    if (!isCreate) return true;
    if (widget.isSubmitting) return false;
    return currentUsername.isNotEmpty &&
        confirmedAvailableUsername == currentUsername;
  }

  bool get isCreate => widget.readOnlyUsername == null;

  /// Whether any field has been modified from the initial value.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    form.save();
    return !mapEquals(form.initialValue, form.value);
  }

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;

    final v = form.value;

    // Cross-field validation: username must be confirmed available
    // (create only). The availability widget hides its action button
    // below 3 chars, so this also catches "didn't run check yet".
    if (isCreate &&
        (currentUsername.isEmpty ||
            confirmedAvailableUsername != currentUsername)) {
      form.setFieldError(
        'username',
        'Run the availability check before creating the account.',
      );
      return;
    }

    // Cross-field validation: passwords must match (create only, and only
    // when the admin is typing a password rather than using the default).
    if (isCreate && !useDefaultPassword) {
      final password = v['password'] as String? ?? '';
      final confirm = v['confirmPassword'] as String? ?? '';
      if (password != confirm) {
        form.setFieldError('confirmPassword', 'Passwords do not match');
        return;
      }
    }

    // Cross-field validation: at least one of firstName or lastName.
    final nameError = UserFormValidators.atLeastOneName(
      (v['firstName'] as String?)?.trim(),
      (v['lastName'] as String?)?.trim(),
    );
    if (nameError != null) {
      form.setFieldError('firstName', nameError);
      return;
    }

    await widget.onSubmit(v);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !isCreate || widget.onCheckUsernameAvailable != null,
      'create-mode UserForm requires onCheckUsernameAvailable',
    );
    final theme = ShadTheme.of(context);
    final initialValues = widget.initialValues ?? const <String, dynamic>{};

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;

        return ShadForm(
          key: formKey,
          initialValue: initialValues,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ───────────────────────────────────────────
              if (widget.title != null) ...[
                Text(widget.title!, style: theme.textTheme.h4),
                const SizedBox(height: 16),
              ],

              // ── 1. Username ─────────────────────────────────────
              if (isCreate)
                UsernameAvailabilityField(
                  label: _requiredLabel('Username'),
                  placeholder: const Text('unique-username'),
                  autofocus: true,
                  enabled: !widget.isSubmitting,
                  validator: UserFormValidators.username,
                  onAvailabilityChanged: onAvailabilityChanged,
                  checkAvailability: widget.onCheckUsernameAvailable!,
                )
              else
                ReadOnlyField(
                  label: 'Username',
                  value: widget.readOnlyUsername!,
                ),
              const SizedBox(height: 12),

              // ── 2. Password (create only) ───────────────────────
              if (isCreate) ...[
                Row(
                  children: [
                    Expanded(
                      child: ShadCheckboxFormField(
                        id: 'useDefaultPassword',
                        initialValue: useDefaultPassword,
                        inputLabel: const Text('Use default password'),
                        enabled: !widget.isSubmitting,
                        onChanged: (v) =>
                            setState(() => useDefaultPassword = v),
                      ),
                    ),
                    if (useDefaultPassword &&
                        widget.onShowDefaultPassword != null)
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: widget.isSubmitting
                            ? null
                            : widget.onShowDefaultPassword,
                        child: const Text('Show'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!useDefaultPassword) ...[
                  ShadInputFormField(
                    id: 'password',
                    label: _requiredLabel('Password'),
                    placeholder: const Text('At least 8 characters'),
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    obscureText: true,
                    enabled: !widget.isSubmitting,
                    validator: UserFormValidators.password,
                  ),
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    id: 'confirmPassword',
                    label: _requiredLabel('Confirm password'),
                    placeholder: const Text('Re-type password'),
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    obscureText: true,
                    enabled: !widget.isSubmitting,
                    validator: (v) {
                      if (v.isEmpty) return 'Please confirm the password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // ── 3. First name, Middle name, Last name ───────────
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ShadInputFormField(
                        id: 'firstName',
                        label: _requiredLabel('First name'),
                        autofocus: !isCreate,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        enabled: !widget.isSubmitting,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShadInputFormField(
                        id: 'middleName',
                        label: const Text('Middle name'),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        enabled: !widget.isSubmitting,
                      ),
                    ),
                  ],
                )
              else ...[
                ShadInputFormField(
                  id: 'firstName',
                  label: _requiredLabel('First name'),
                  autofocus: !isCreate,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  id: 'middleName',
                  label: const Text('Middle name'),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
              ],
              const SizedBox(height: 12),
              ShadInputFormField(
                id: 'lastName',
                label: _requiredLabel('Last name'),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                enabled: !widget.isSubmitting,
              ),
              const SizedBox(height: 12),

              // ── 4. Use name publicly (update only) ──────────────
              if (!isCreate) ...[
                if (widget.canEditUseNamePublicly)
                  ShadCheckboxFormField(
                    id: 'useNamePublicly',
                    initialValue:
                        initialValues['useNamePublicly'] as bool? ?? false,
                    label: const Text('Show name publicly'),
                    enabled: !widget.isSubmitting,
                  )
                else
                  ReadOnlyField(
                    label: 'Show name publicly',
                    value: (initialValues['useNamePublicly'] as bool? ?? false)
                        ? 'Yes'
                        : 'No',
                  ),
                const SizedBox(height: 12),
              ],

              // ── 5. Nickname (update only) ───────────────────────
              if (!isCreate) ...[
                ShadInputFormField(
                  id: 'nickname',
                  label: const Text('Nickname'),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: 12),
              ],

              // ── 6–7. Gender + Date of birth ─────────────────────
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildGenderField(initialValues),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateOfBirthField(initialValues),
                    ),
                  ],
                )
              else ...[
                _buildGenderField(initialValues),
                const SizedBox(height: 12),
                _buildDateOfBirthField(initialValues),
              ],
              const SizedBox(height: 12),

              // ── 8. Address (update only) ────────────────────────
              if (!isCreate) ...[
                Text(
                  'Address',
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ShadInputFormField(
                  id: 'addrLine1',
                  label: const Text('Address line 1'),
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  id: 'addrLine2',
                  label: const Text('Address line 2'),
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  id: 'city',
                  label: const Text('City'),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ShadSelectFormField<String>(
                          id: 'state',
                          label: const Text('State'),
                          initialValue: initialValues['state'] as String?,
                          placeholder: const Text('Select state'),
                          enabled: !widget.isSubmitting,
                          options: indianStates
                              .map(
                                (s) => ShadOption(
                                  value: s,
                                  child: Text(s),
                                ),
                              )
                              .toList(),
                          selectedOptionBuilder: (context, value) =>
                              Text(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadInputFormField(
                          id: 'pincode',
                          label: const Text('Pincode'),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          enabled: !widget.isSubmitting,
                          validator: UserFormValidators.pincode,
                        ),
                      ),
                    ],
                  )
                else ...[
                  ShadSelectFormField<String>(
                    id: 'state',
                    label: const Text('State'),
                    initialValue: initialValues['state'] as String?,
                    placeholder: const Text('Select state'),
                    enabled: !widget.isSubmitting,
                    options: indianStates
                        .map(
                          (s) => ShadOption(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    selectedOptionBuilder: (context, value) => Text(value),
                  ),
                  const SizedBox(height: 12),
                  ShadInputFormField(
                    id: 'pincode',
                    label: const Text('Pincode'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    enabled: !widget.isSubmitting,
                    validator: UserFormValidators.pincode,
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // ── 9. Phone ────────────────────────────────────────
              ShadInputFormField(
                id: 'phone',
                label: _requiredLabel('Phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !widget.isSubmitting,
                validator: UserFormValidators.phone,
              ),
              const SizedBox(height: 12),

              // ── 10. Email ───────────────────────────────────────
              ShadInputFormField(
                id: 'email',
                label: _requiredLabel('Email'),
                placeholder: const Text('name@example.com'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: isCreate
                    ? TextInputAction.done
                    : TextInputAction.next,
                enabled: !widget.isSubmitting,
                validator: UserFormValidators.email,
              ),

              // ── Update-only sections below ──────────────────────
              if (!isCreate) ...[
                const SizedBox(height: 16),

                // ── 11. Emergency contact ─────────────────────────
                Text(
                  'Emergency contact',
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ShadInputFormField(
                  id: 'emergencyContactName',
                  label: const Text('Contact name'),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !widget.isSubmitting,
                ),
                const SizedBox(height: 8),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ShadSelectFormField<String>(
                          id: 'emergencyContactRelation',
                          label: const Text('Relation'),
                          initialValue:
                              initialValues['emergencyContactRelation']
                                  as String?,
                          placeholder: const Text('Relation'),
                          enabled: !widget.isSubmitting,
                          options: UserFormAssembly.emergencyRelations
                              .map(
                                (r) => ShadOption(value: r, child: Text(r)),
                              )
                              .toList(),
                          selectedOptionBuilder: (context, value) =>
                              Text(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShadInputFormField(
                          id: 'emergencyContactPhone',
                          label: const Text('Contact phone'),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !widget.isSubmitting,
                          validator: UserFormValidators.phoneOptional,
                        ),
                      ),
                    ],
                  )
                else ...[
                  ShadSelectFormField<String>(
                    id: 'emergencyContactRelation',
                    label: const Text('Relation'),
                    initialValue:
                        initialValues['emergencyContactRelation'] as String?,
                    placeholder: const Text('Relation'),
                    enabled: !widget.isSubmitting,
                    options: UserFormAssembly.emergencyRelations
                        .map(
                          (r) => ShadOption(value: r, child: Text(r)),
                        )
                        .toList(),
                    selectedOptionBuilder: (context, value) => Text(value),
                  ),
                  const SizedBox(height: 8),
                  ShadInputFormField(
                    id: 'emergencyContactPhone',
                    label: const Text('Contact phone'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    enabled: !widget.isSubmitting,
                    validator: UserFormValidators.phoneOptional,
                  ),
                ],
                const SizedBox(height: 12),

                // ── 12. Medical notes ─────────────────────────────
                ShadInputFormField(
                  id: 'medicalInfo',
                  label: const Text('Medical notes'),
                  maxLines: 2,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  enabled: !widget.isSubmitting,
                ),
              ],

              // ── 13. Role assignment (create only) ─────────────
              if (isCreate &&
                  (widget.canAssignAdmin || widget.canAssignCoach)) ...[
                const SizedBox(height: 20),
                Text(
                  'Roles',
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.canAssignAdmin) ...[
                  ShadCheckboxFormField(
                    id: 'assignAdmin',
                    initialValue: false,
                    inputLabel: const Text('Make this user an Admin'),
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.canAssignCoach)
                  ShadCheckboxFormField(
                    id: 'assignCoach',
                    initialValue: false,
                    inputLabel: const Text('This user is a coach'),
                    enabled: !widget.isSubmitting,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderField(Map<String, dynamic> initialValues) {
    if (widget.canEditGender || isCreate) {
      return ShadSelectFormField<SignupGender>(
        id: 'gender',
        label: _requiredLabel('Gender'),
        initialValue: initialValues['gender'] as SignupGender?,
        placeholder: const Text('Select gender'),
        enabled: !widget.isSubmitting,
        validator: UserFormValidators.gender,
        options: SignupGender.values
            .map((g) => ShadOption(value: g, child: Text(g.label)))
            .toList(),
        selectedOptionBuilder: (context, value) => Text(value.label),
      );
    }
    return ReadOnlyField(
      label: 'Gender',
      value: (initialValues['gender'] as SignupGender?)?.label ?? 'Not set',
    );
  }

  Widget _buildDateOfBirthField(Map<String, dynamic> initialValues) {
    if (widget.canEditDateOfBirth || isCreate) {
      return CLDatePickerFormField(
        id: 'dateOfBirthUtc',
        label: _requiredLabel('Date of birth'),
        placeholder: const Text('Select date of birth'),
        initialValue: initialValues['dateOfBirthUtc'] as DateTime?,
        enabled: !widget.isSubmitting,
        formatDate: (d) => DateFormat('d MMM yyyy').format(d),
        validator: UserFormValidators.dateOfBirth,
      );
    }
    return ReadOnlyField(
      label: 'Date of birth',
      value: initialValues['dateOfBirthUtc'] != null
          ? DateFormat(
              'd MMM yyyy',
            ).format(initialValues['dateOfBirthUtc'] as DateTime)
          : 'Not set',
    );
  }

  /// Builds a label widget with a red asterisk for required fields.
  Widget _requiredLabel(String text) {
    return Text.rich(
      TextSpan(
        text: text,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
