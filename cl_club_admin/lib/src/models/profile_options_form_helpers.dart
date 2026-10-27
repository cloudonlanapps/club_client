import 'package:cl_club_forms/cl_club_forms.dart'
    show ProfileLabelLanguage, ProfileOptionsFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ProfileOptionsNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ProfileOptions, ProfilePosition, SdkErrorCode, ServerException;

import '../constants/profile_options_messages.dart';

/// What `ProfileOptionsForm` shows for a refused save: messages on the
/// fields by id, and one for the form as a whole.
typedef ProfileOptionsFormRefusal = ({
  Map<String, String> fieldErrors,
  String? formError,
});

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

  /// What the form shows for a save refused with [error], or `null` when
  /// the refusal is not about the document (the host then toasts a fixed
  /// message). The document goes as `{"value": …}` of any shape, so the
  /// server's schema never names a list in it (club_client#364): a
  /// document it cannot use is refused with 422 `INVALID_PREFERENCE_VALUE`,
  /// which names no field, and shows inline in the form.
  static ProfileOptionsFormRefusal? refusal(Object error) {
    if (error is ServerException &&
        error.code == SdkErrorCode.invalidPreferenceValue) {
      return (
        fieldErrors: const {},
        formError: ProfileOptionsMessages.invalidOptions,
      );
    }
    return null;
  }
}
