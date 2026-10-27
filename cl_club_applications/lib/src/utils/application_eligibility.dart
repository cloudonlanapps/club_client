import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationAgeCategory, ApplicationTemplate, Gender, UserPrivate;

/// Whether [member] may have their form of [template] (club_client#380).
///
/// Mirrors the server's rule (club_server `application_rules`, R11): a
/// template without age categories is for every member; otherwise the
/// member must fit one of them ([fitsAgeCategory]).
bool isEligibleFor(ApplicationTemplate template, UserPrivate member) {
  final categories = template.content.ageCategories;
  if (categories.isEmpty) return true;
  return categories.any(
    (c) => fitsAgeCategory(c, member.dateOfBirthUtc, member.gender),
  );
}

/// Whether a member born on [dateOfBirthUtc], of [gender], falls in
/// [category]: born on or after its first day and on or before its last
/// (each optional), and of one of its genders (none listed = any). A member
/// with no date of birth fits none.
///
/// All three dates are date-only values at UTC midnight, so they compare
/// directly.
bool fitsAgeCategory(
  ApplicationAgeCategory category,
  DateTime? dateOfBirthUtc,
  Gender? gender,
) {
  if (dateOfBirthUtc == null) return false;
  final after = category.bornOnOrAfterUtc;
  if (after != null && dateOfBirthUtc.isBefore(after)) return false;
  final before = category.bornOnOrBeforeUtc;
  if (before != null && dateOfBirthUtc.isAfter(before)) return false;
  final genders = category.genders;
  return genders == null || genders.isEmpty || genders.contains(gender);
}

/// Whether [member] has no date of birth while some of [templates] have age
/// categories, so those are hidden from them until they add one.
bool hiddenForMissingDateOfBirth(
  Iterable<ApplicationTemplate> templates,
  UserPrivate member,
) =>
    member.dateOfBirthUtc == null &&
    templates.any((t) => t.content.ageCategories.isNotEmpty);
