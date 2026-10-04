import 'package:club_sdk_2/club_sdk_2.dart' show Facility;
import 'package:flutter/material.dart';

/// Icons by the `iconName` a facility carries.
const Map<String, IconData> kFacilityIcons = {
  'ice_skating': Icons.ice_skating,
  'sports_hockey': Icons.sports_hockey,
  'event_seat': Icons.event_seat,
  'local_parking': Icons.local_parking,
  'restaurant': Icons.restaurant,
  'wifi': Icons.wifi,
  'ac_unit': Icons.ac_unit,
  'fitness_center': Icons.fitness_center,
  'sports': Icons.sports,
  'medical_services': Icons.medical_services,
  'locker': Icons.lock,
  'shower': Icons.shower,
  'accessibility': Icons.accessibility,
};

/// The icon a [Facility] names.
extension FacilityIcon on Facility {
  /// The icon for `iconName`, or a check mark when it names none.
  IconData get iconValue =>
      kFacilityIcons[iconName] ?? Icons.check_circle_outline;
}
