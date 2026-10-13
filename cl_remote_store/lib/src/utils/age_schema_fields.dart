import 'package:cl_club_forms/cl_club_forms.dart' show AgeEligibilityFormFields;

/// The server's name for the minimum age of an event or a group.
const String serverMinAge = 'minAge';

/// The server's name for the maximum age of an event or a group.
const String serverMaxAge = 'maxAge';

/// The server's name for the strict-age flag of an event or a group.
const String serverStrictAge = 'strictAge';

/// The server's name for the years of an age.
const String serverAgeYears = 'years';

/// The server's name for the months of an age.
const String serverAgeMonths = 'months';

/// The server's name for the days of an age.
const String serverAgeDays = 'days';

/// The fields of an age band, as the server names them in a schema
/// rejection (club_client#114), each with the id of the form field that
/// holds it. The event and the group form adapters share it, as they share
/// the age fields. A refusal of a bound as a whole shows on its years.
const Map<String, String> ageSchemaFieldIds = {
  serverMinAge: AgeEligibilityFormFields.minAgeYearsId,
  '$serverMinAge.$serverAgeYears': AgeEligibilityFormFields.minAgeYearsId,
  '$serverMinAge.$serverAgeMonths': AgeEligibilityFormFields.minAgeMonthsId,
  '$serverMinAge.$serverAgeDays': AgeEligibilityFormFields.minAgeDaysId,
  serverMaxAge: AgeEligibilityFormFields.maxAgeYearsId,
  '$serverMaxAge.$serverAgeYears': AgeEligibilityFormFields.maxAgeYearsId,
  '$serverMaxAge.$serverAgeMonths': AgeEligibilityFormFields.maxAgeMonthsId,
  '$serverMaxAge.$serverAgeDays': AgeEligibilityFormFields.maxAgeDaysId,
  serverStrictAge: AgeEligibilityFormFields.strictAgeId,
};
