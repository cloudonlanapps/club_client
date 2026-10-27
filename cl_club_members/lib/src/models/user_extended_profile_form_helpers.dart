import 'package:cl_club_forms/cl_club_forms.dart'
    show ProfilePositionOption, UserFormAssembly, UserFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        Guardian,
        InvalidProfileOptionException,
        ProfileOptions,
        SdkErrorCode,
        ServerException,
        UserPrivate;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

import '../constants/extended_profile_strings.dart';
import 'user_schema_fields.dart';

/// The language a position's label is shown in, in the app.
const String profilePositionDisplayLanguage = 'en';

/// The initial values of the extended profile's section forms
/// (`UserSportsDetailsForm`, `UserBackgroundForm`, `UserGuardianForm`) from
/// [user], each text `''` when blank so the forms' dirty check compares like
/// with like (club_client#320), and the preferred positions and languages
/// the member's whole lists (club_client#335).
Map<String, dynamic> buildUserExtendedProfileFormInitialValues(
  UserPrivate user,
) => {
  UserFormFields.clubDistrictId: user.clubDistrict ?? '',
  UserFormFields.preferredPositionsId: [...user.preferredPositions],
  UserFormFields.pastExperienceId: user.pastExperience ?? '',
  UserFormFields.nationalityId: user.nationality ?? '',
  UserFormFields.preferredLanguagesId: [...user.preferredLanguages],
  UserFormFields.guardianNameId: user.guardian?.name ?? '',
  UserFormFields.guardianRelationId: user.guardian?.relation ?? '',
  UserFormFields.guardianPhoneId: user.guardian?.phone ?? '',
};

/// The club's positions as the sports details form offers them, each with
/// its label in [profilePositionDisplayLanguage] (its value when it has
/// none).
List<ProfilePositionOption> profilePositionOptions(ProfileOptions options) => [
  for (final position in options.positions)
    ProfilePositionOption(
      value: position.value,
      label: position.labelFor(profilePositionDisplayLanguage),
    ),
];

/// The club's languages as a member chooses among them: by name, which
/// is what `preferredLanguages` holds (club_client#396).
List<String> profileLanguageNames(ProfileOptions options) => [
  for (final language in options.languages) language.name,
];

/// How [value], a member's preferred position, reads: the club's label for
/// it, or the value itself when the club no longer lists it.
String profilePositionLabel(ProfileOptions options, String value) =>
    options.position(value)?.labelFor(profilePositionDisplayLanguage) ?? value;

/// SDK adapter of the extended profile's section editors (club_client#320):
/// each `update<Section>` sends only the fields its section edits, through
/// the users master; a blank text is sent as null, which clears it.
abstract final class UserExtendedProfileFormSubmit {
  /// Partial update of the sports details: club or district, preferred
  /// positions (the ticked ones, empty for none) and past experience.
  static Future<UserPrivate> updateSportsDetails({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
  }) {
    return notifier.updateUser(
      username,
      clubDistrict: () =>
          UserFormAssembly.maybe(UserFormFields.clubDistrictId, values),
      preferredPositions: UserFormAssembly.strings(
        UserFormFields.preferredPositionsId,
        values,
      ),
      pastExperience: () =>
          UserFormAssembly.maybe(UserFormFields.pastExperienceId, values),
    );
  }

  /// Partial update of the background: nationality and preferred languages
  /// (the ticked ones, empty for none).
  static Future<UserPrivate> updateBackground({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
  }) {
    return notifier.updateUser(
      username,
      nationality: () =>
          UserFormAssembly.maybe(UserFormFields.nationalityId, values),
      preferredLanguages: UserFormAssembly.strings(
        UserFormFields.preferredLanguagesId,
        values,
      ),
    );
  }

  /// Partial update of the guardian: name, relation and phone, the phone
  /// stored in international format, completed with [defaultCountryCode]
  /// when typed without a country code. A guardian left blank is cleared.
  static Future<UserPrivate> updateGuardian({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
    required String defaultCountryCode,
  }) {
    final guardian = Guardian(
      name: UserFormAssembly.maybe(UserFormFields.guardianNameId, values),
      relation: UserFormAssembly.maybe(
        UserFormFields.guardianRelationId,
        values,
      ),
      phone: PhoneNumber.toInternationalOrNull(
        UserFormAssembly.maybe(UserFormFields.guardianPhoneId, values),
        defaultCountryCode: defaultCountryCode,
      ),
    );
    return notifier.updateUser(
      username,
      guardian: () => guardian.isEmpty ? null : guardian,
    );
  }

  /// Partial update of the membership date (an admin's), a date-only value
  /// sent at UTC midnight.
  static Future<UserPrivate> updateMembershipDate({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
  }) {
    return notifier.updateUser(
      username,
      membershipDateUtc: () => UserFormAssembly.floorToUtcMidnight(
        values[UserFormFields.membershipDateUtcId] as DateTime?,
      ),
    );
  }

  /// The form field of each field the server refuses as not one of the
  /// club's profile options.
  static const Map<String, String> profileOptionFieldIds = {
    UserSchemaFields.preferredPositions: UserFormFields.preferredPositionsId,
    UserSchemaFields.preferredLanguages: UserFormFields.preferredLanguagesId,
  };

  /// What a section editor shows for a refused save, keyed by field id: a
  /// position or language the club does not offer on its checkboxes, a
  /// membership date the server does not take on it, and a schema
  /// rejection on the field it names. Empty when [error] names no field.
  static Map<String, String> fieldErrorsFor(ServerException error) {
    if (error is InvalidProfileOptionException) {
      final fieldId = profileOptionFieldIds[error.field];
      return {?fieldId: ExtendedProfileStrings.optionRefused};
    }
    if (error.code == SdkErrorCode.invalidDobNotUtcMidnight) {
      return const {
        UserFormFields.membershipDateUtcId:
            ExtendedProfileStrings.membershipDateRefused,
      };
    }
    if (error.code == SdkErrorCode.protectedFields) {
      return const {
        UserFormFields.membershipDateUtcId:
            ExtendedProfileStrings.membershipDateProtected,
      };
    }
    return schemaFieldErrors(error, UserSchemaFields.fieldIds);
  }
}
