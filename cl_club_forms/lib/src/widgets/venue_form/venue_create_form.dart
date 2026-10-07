import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'venue_form_fields.dart';
import 'venue_form_validators.dart';

/// Pure-UI venue creation form (no SDK / no Riverpod).
///
/// Speaks flat form values keyed by [VenueFormFields]: the caller supplies
/// [initialValues] and its adapter translates what `validate()` returns to
/// the SDK create call.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<VenueCreateFormState>` — `validate()` from its Create action,
/// `isDirty` for the discard prompt, `showErrors()` with what the server
/// refuses ([FormContract]).
///
/// Create-only by design — venues are edited section-by-section on the venue
/// profile, never through a full edit form.
class VenueCreateForm extends StatefulWidget {
  const VenueCreateForm({
    this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// Optional starting values; defaults to empty fields with toggles off.
  final Map<String, dynamic>? initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Default form values for a fresh venue.
  static Map<String, dynamic> get emptyValues => {
    VenueFormFields.nameId: '',
    VenueFormFields.addressId: '',
    VenueFormFields.descriptionId: '',
    VenueFormFields.mapUriId: '',
    VenueFormFields.isDefaultId: false,
    VenueFormFields.isFeaturedId: false,
  };

  @override
  State<VenueCreateForm> createState() => VenueCreateFormState();
}

/// State of [VenueCreateForm]. Its values are the six [VenueFormFields]
/// entries as the fields hold them.
class VenueCreateFormState extends State<VenueCreateForm>
    with FormContract<VenueCreateForm> {
  /// What the form starts with.
  Map<String, dynamic> get initialValues =>
      widget.initialValues ?? VenueCreateForm.emptyValues;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initial = initialValues;
    return ShadForm(
      key: formKey,
      initialValue: initial,
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Venue name',
            required: true,
            field: ShadInputFormField(
              id: VenueFormFields.nameId,
              keyboardType: TextInputType.name,
              autocorrect: false,
              enableSuggestions: false,
              enabled: widget.enabled,
              validator: VenueFormValidators.name,
            ),
          ),
          LabeledFormRow(
            label: 'Address',
            field: ShadInputFormField(
              id: VenueFormFields.addressId,
              keyboardType: TextInputType.streetAddress,
              enabled: widget.enabled,
            ),
          ),
          LabeledFormRow(
            label: 'Description',
            field: ShadInputFormField(
              id: VenueFormFields.descriptionId,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              enabled: widget.enabled,
            ),
          ),
          LabeledFormRow(
            label: 'Map link',
            field: ShadInputFormField(
              id: VenueFormFields.mapUriId,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              enabled: widget.enabled,
            ),
          ),
          // Toggles wrap so the two switch/label pairs flow to a second line
          // on narrow widths instead of overflowing horizontally.
          Wrap(
            spacing: FormSpacing.sectionGap,
            runSpacing: FormSpacing.rowGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShadSwitchFormField(
                id: VenueFormFields.isDefaultId,
                initialValue:
                    initial[VenueFormFields.isDefaultId] as bool? ?? false,
                enabled: widget.enabled,
                inputLabel: Text('Default venue', style: theme.textTheme.small),
              ),
              ShadSwitchFormField(
                id: VenueFormFields.isFeaturedId,
                initialValue:
                    initial[VenueFormFields.isFeaturedId] as bool? ?? false,
                enabled: widget.enabled,
                inputLabel: Text('Featured', style: theme.textTheme.small),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
