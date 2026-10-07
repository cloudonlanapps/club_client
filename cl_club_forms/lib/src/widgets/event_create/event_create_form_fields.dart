import 'package:flutter/foundation.dart';

/// Which kind of event the create form is gathering.
///
/// Form-local mirror of the SDK `EventType`; the host adapter maps between
/// the two at the boundary so the form stays SDK-free.
enum EventFormType { programme, camp, oneOff }

/// Display label for an [EventFormType] (used in headings and toasts).
extension EventFormTypeLabel on EventFormType {
  String get label => switch (this) {
    EventFormType.programme => 'Programme',
    EventFormType.camp => 'Camp',
    EventFormType.oneOff => 'One-off',
  };
}

/// Form-local mirror of the SDK `Visibility`.
enum EventFormVisibility {
  public,
  private;

  String get label => this == EventFormVisibility.public ? 'Public' : 'Private';
}

/// A venue the create form can pick from — the id + display name projection
/// of the SDK `Venue`. The host builds these from the venue master provider.
@immutable
class EventVenueOption {
  const EventVenueOption({required this.id, required this.name});

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is EventVenueOption && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Field-id constants for the `ShadForm` inside `EventCreateForm`.
///
/// `scheduleId` carries the form-local schedule value object
/// (`CampScheduleData` / `OneOffScheduleData` / `ProgrammeScheduleData`)
/// produced by the matching schedule field.
class EventCreateFormFields {
  EventCreateFormFields._();

  static const String titleId = 'title';
  static const String visibilityId = 'visibility';
  static const String venueId = 'venue';
  static const String scheduleId = 'schedule';
}
