import 'package:cl_club_forms/cl_club_forms.dart'
    show ProfileLabelLanguage, ProfileOptionsFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ProfileOptionsNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ProfileOptions, ProfilePosition, ServerException;

/// The languages a position is labelled in on the Club details page: the
/// languages an application form may print in (club_client#320).
const List<ProfileLabelLanguage> profileLabelLanguages = [
  ProfileLabelLanguage(code: 'en', name: 'English'),
  ProfileLabelLanguage(code: 'mr', name: 'Marathi'),
  ProfileLabelLanguage(code: 'hi', name: 'Hindi'),
];

/// The initial values of `ProfileOptionsForm` from the club's [options].
Map<String, dynamic> buildProfileOptionsFormInitialValues(
  ProfileOptions options,
) => {
  ProfileOptionsFormFields.positionsId: [
    for (final position in options.positions)
      {
        ProfileOptionsFormFields.valueKey: position.value,
        ProfileOptionsFormFields.labelKey: position.label,
      },
  ],
  ProfileOptionsFormFields.languagesId: options.languages,
};

/// SDK adapter of `ProfileOptionsForm` (club_client#320): the form's values
/// become the club's whole `profile_options` document.
abstract final class ProfileOptionsFormSubmit {
  /// The server's name of the positions, as a schema rejection gives it.
  static const String serverPositions = 'positions';

  /// The server's name of the languages.
  static const String serverLanguages = 'languages';

  /// The form's field for each part of the document the server can name.
  static const Map<String, String> schemaFieldIds = {
    serverPositions: ProfileOptionsFormFields.positionsId,
    serverLanguages: ProfileOptionsFormFields.languagesId,
  };

  /// The options [values] hold, as `ProfileOptionsFormState.validate`
  /// returns them.
  static ProfileOptions optionsOf(Map<String, dynamic> values) {
    final positions = values[ProfileOptionsFormFields.positionsId];
    final languages = values[ProfileOptionsFormFields.languagesId];
    return ProfileOptions(
      positions: [
        if (positions is List)
          for (final position in positions.whereType<Map<Object?, Object?>>())
            ProfilePosition(
              value: position[ProfileOptionsFormFields.valueKey]! as String,
              label: Map<String, String>.from(
                position[ProfileOptionsFormFields.labelKey]! as Map,
              ),
            ),
      ],
      languages: [
        if (languages is List) ...languages.whereType<String>(),
      ],
    );
  }

  /// Replace the club's profile options with what [values] hold.
  static Future<ProfileOptions> updateProfileOptions({
    required Map<String, dynamic> values,
    required ProfileOptionsNotifier notifier,
  }) => notifier.save(optionsOf(values));

  /// What the form shows for a refused save: a schema rejection on the
  /// list it names. Empty when [error] names neither.
  static Map<String, String> fieldErrorsFor(ServerException error) =>
      schemaFieldErrors(error, schemaFieldIds);
}
