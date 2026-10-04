import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pure-UI location form — a free-text address plus a map link.
///
/// Host-agnostic: no Scaffold, dialog, or buttons. A caller embeds it
/// (typically inside a `ShadDialog`) and drives it through a
/// `GlobalKey<LocationEditFormState>`: call [LocationEditFormState.validate]
/// from the Save action to validate and read the trimmed values.
class LocationEditForm extends StatefulWidget {
  const LocationEditForm({
    required this.initialAddress,
    required this.initialMapUri,
    super.key,
    this.onSubmitted,
  });

  final String initialAddress;
  final String initialMapUri;

  /// Invoked when the user submits the last field (enter key).
  final VoidCallback? onSubmitted;

  static const String addressId = 'address';
  static const String mapUriId = 'mapUri';

  @override
  State<LocationEditForm> createState() => LocationEditFormState();
}

class LocationEditFormState extends State<LocationEditForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// Validates the fields. Returns the trimmed values when valid, else `null`.
  LocationEditResult? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final address =
        (form.value[LocationEditForm.addressId] as String?)?.trim() ?? '';
    final mapUri =
        (form.value[LocationEditForm.mapUriId] as String?)?.trim() ?? '';
    return LocationEditResult(address: address, mapUri: mapUri);
  }

  /// Whether any field differs from the initial values the form was seeded
  /// with. Mirrors `UserForm`/`GroupCreateForm`'s framework-driven check.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !mapEquals(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        LocationEditForm.addressId: widget.initialAddress,
        LocationEditForm.mapUriId: widget.initialMapUri,
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInputFormField(
            id: LocationEditForm.addressId,
            label: const Text('Address'),
            placeholder: const Text('Street, city, state'),
            keyboardType: TextInputType.streetAddress,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: LocationEditForm.mapUriId,
            label: const Text('Map link'),
            placeholder: const Text('https://maps.google.com/...'),
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => widget.onSubmitted?.call(),
          ),
        ],
      ),
    );
  }
}

@immutable
class LocationEditResult {
  const LocationEditResult({required this.address, required this.mapUri});

  final String address;
  final String mapUri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationEditResult &&
          other.address == address &&
          other.mapUri == mapUri;

  @override
  int get hashCode => Object.hash(address, mapUri);
}
