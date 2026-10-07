import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'location_edit_form_fields.dart';

/// Pure-UI location form — a free-text address plus a map link.
///
/// The form owns no dialog or buttons: the host embeds it (an
/// `EditableSectionCard`, say) and drives it through a
/// `GlobalKey<LocationEditFormState>` — `validate()` from its Save action,
/// `isDirty` to make an unchanged Save a no-op ([FormContract]).
class LocationEditForm extends StatefulWidget {
  const LocationEditForm({
    required this.initialAddress,
    required this.initialMapUri,
    this.onSubmitted,
    this.enabled = true,
    super.key,
  });

  /// The address the form starts with; empty when none is on file.
  final String initialAddress;

  /// The map link the form starts with; empty when none is on file.
  final String initialMapUri;

  /// Invoked when the user submits the last field (enter key).
  final VoidCallback? onSubmitted;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<LocationEditForm> createState() => LocationEditFormState();
}

/// State of [LocationEditForm]. Its values are
/// `{addressId: String, mapUriId: String}`, both trimmed and empty when the
/// field is blank.
class LocationEditFormState extends State<LocationEditForm>
    with FormContract<LocationEditForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    for (final id in const [
      LocationEditFormFields.addressId,
      LocationEditFormFields.mapUriId,
    ])
      id: (values[id] as String?)?.trim() ?? '',
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        LocationEditFormFields.addressId: widget.initialAddress,
        LocationEditFormFields.mapUriId: widget.initialMapUri,
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Address',
            field: ShadInputFormField(
              id: LocationEditFormFields.addressId,
              enabled: widget.enabled,
              placeholder: const Text('Street, city, state'),
              keyboardType: TextInputType.streetAddress,
            ),
          ),
          LabeledFormRow(
            label: 'Map link',
            field: ShadInputFormField(
              id: LocationEditFormFields.mapUriId,
              enabled: widget.enabled,
              placeholder: const Text('https://maps.google.com/...'),
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
