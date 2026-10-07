import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import 'labeled_form_row.dart';

/// The labelled venue picker of a schedule editor: a `ShadForm` select over
/// [venues] whose value is the chosen venue's id.
class EventVenueSelectField extends StatelessWidget {
  const EventVenueSelectField({
    required this.id,
    required this.venues,
    this.initialValue,
    this.validator,
    this.enabled = true,
    super.key,
  });

  /// Shown in the picker while no venue is chosen.
  static const String placeholder = 'Select a venue';

  /// The field's id in the enclosing `ShadForm`.
  final String id;

  /// The venues to choose from.
  final List<EventVenueOption> venues;

  /// The venue chosen when the form opens.
  final int? initialValue;

  /// Validates the chosen venue id.
  final String? Function(int?)? validator;

  /// Whether the picker accepts input.
  final bool enabled;

  /// The name shown for venue [venueId]: its own, or its id when it is not
  /// among [venues] (e.g. a venue removed since).
  String nameOf(int venueId) => venues
      .firstWhere(
        (venue) => venue.id == venueId,
        orElse: () => EventVenueOption(id: venueId, name: '#$venueId'),
      )
      .name;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: 'Venue',
      required: true,
      field: ShadSelectFormField<int>(
        id: id,
        initialValue: initialValue,
        enabled: enabled,
        placeholder: const Text(placeholder),
        validator: validator,
        options: [
          for (final venue in venues)
            ShadOption(value: venue.id, child: Text(venue.name)),
        ],
        selectedOptionBuilder: (context, value) => Text(nameOf(value)),
      ),
    );
  }
}
