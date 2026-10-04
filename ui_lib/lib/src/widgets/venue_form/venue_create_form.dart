import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'venue_form_validators.dart';

/// Pure-UI venue creation form (no SDK / no Riverpod).
///
/// Speaks flat form values: the caller supplies [initialValues] and receives a
/// `Map<String, dynamic>` on submit, which its adapter translates to the SDK
/// create call. Field IDs are exposed as constants so the adapter can read the
/// returned map without string literals.
///
/// Create-only by design — venues are edited section-by-section on the venue
/// profile, never through a full edit form.
class VenueCreateForm extends StatefulWidget {
  const VenueCreateForm({
    required this.onSubmit,
    this.initialValues,
    this.isSubmitting = false,
    super.key,
  });

  /// Called with the flat form values when validation passes.
  final Future<void> Function(Map<String, dynamic> values) onSubmit;

  /// Optional starting values; defaults to empty fields with toggles off.
  final Map<String, dynamic>? initialValues;

  final bool isSubmitting;

  // Field IDs — referenced by the caller's adapter.
  static const String nameId = 'name';
  static const String addressId = 'address';
  static const String descriptionId = 'description';
  static const String mapUriId = 'mapUri';
  static const String isDefaultId = 'isDefault';
  static const String isFeaturedId = 'isFeatured';

  /// Default form values for a fresh venue.
  static Map<String, dynamic> get emptyValues => {
    nameId: '',
    addressId: '',
    descriptionId: '',
    mapUriId: '',
    isDefaultId: false,
    isFeaturedId: false,
  };

  @override
  State<VenueCreateForm> createState() => VenueCreateFormState();
}

class VenueCreateFormState extends State<VenueCreateForm> {
  final formKey = GlobalKey<ShadFormState>();

  Map<String, dynamic> get _initial =>
      widget.initialValues ?? VenueCreateForm.emptyValues;

  bool get isDirty {
    formKey.currentState?.save();
    final current = formKey.currentState?.value ?? {};
    final initial = formKey.currentState?.initialValue ?? {};
    return !mapEquals(_normalize(initial), _normalize(current));
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String && value.trim().isEmpty) return MapEntry(key, null);
      return MapEntry(key, value);
    });
  }

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    await widget.onSubmit(form.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      initialValue: _initial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInputFormField(
            id: VenueCreateForm.nameId,
            label: const Text('Venue name'),
            keyboardType: TextInputType.name,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !widget.isSubmitting,
            validator: VenueFormValidators.name,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: VenueCreateForm.addressId,
            label: const Text('Address'),
            keyboardType: TextInputType.streetAddress,
            enabled: !widget.isSubmitting,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: VenueCreateForm.descriptionId,
            label: const Text('Description'),
            keyboardType: TextInputType.multiline,
            minLines: 2,
            maxLines: 4,
            enabled: !widget.isSubmitting,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: VenueCreateForm.mapUriId,
            label: const Text('Map link'),
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !widget.isSubmitting,
          ),
          const SizedBox(height: 16),
          // Toggles wrap so the two switch/label pairs flow to a second line
          // on narrow widths instead of overflowing horizontally.
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ShadSwitchFormField(
                id: VenueCreateForm.isDefaultId,
                initialValue: _initial[VenueCreateForm.isDefaultId] as bool,
                enabled: !widget.isSubmitting,
                inputLabel: Text('Default venue', style: theme.textTheme.small),
              ),
              ShadSwitchFormField(
                id: VenueCreateForm.isFeaturedId,
                initialValue: _initial[VenueCreateForm.isFeaturedId] as bool,
                enabled: !widget.isSubmitting,
                inputLabel: Text('Featured', style: theme.textTheme.small),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
