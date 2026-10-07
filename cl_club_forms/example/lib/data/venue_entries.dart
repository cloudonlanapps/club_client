import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';

/// The forms of a venue.
abstract final class VenueEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'venue-create',
      title: 'Venue create form',
      group: FormDemoGroup.venues,
      formType: VenueCreateForm,
      builder: (key) => VenueCreateForm(key: key),
    ),
    FormDemoEntry(
      id: 'location-edit',
      title: 'Location edit form',
      group: FormDemoGroup.venues,
      formType: LocationEditForm,
      builder: (key) => LocationEditForm(
        key: key,
        initialAddress: '12 Example Street, Sampletown',
        initialMapUri: 'https://maps.example.test/main-hall',
      ),
    ),
    FormDemoEntry(
      id: 'rename',
      title: 'Rename form (venue name)',
      group: FormDemoGroup.venues,
      formType: RenameForm,
      builder: (key) => RenameForm(
        key: key,
        initialValue: DemoSamples.venues.first.name,
        label: 'Venue name',
        validator: VenueFormValidators.name,
      ),
    ),
  ];
}
