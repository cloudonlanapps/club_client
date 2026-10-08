import 'package:cl_club_forms/cl_club_forms.dart'
    show FormAddress, SignupGender, UserFormAssembly, UserFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Address, Gender, SdkErrorCode, ServerException, UserPrivate;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

import '../utils/member_write_messages.dart';

/// Default password applied when an admin creates a user with the
/// "Use default password" toggle on. Admins are expected to know this
/// value out-of-band; it is not surfaced in the UI.
const String defaultUserPassword = 'ChangeMe123';

/// SDK ↔ form adapters for `UserForm` (which lives SDK-free in
/// `cl_club_forms`).
///
/// This is the one place that bridges the form's flat `Map<String, dynamic>`
/// and form-local types ([SignupGender], [FormAddress]) to the SDK
/// `UserPrivate` / `Gender` / `Address` types.
extension SignupGenderToSdk on SignupGender {
  Gender toSdk() => switch (this) {
    SignupGender.male => Gender.male,
    SignupGender.female => Gender.female,
    SignupGender.other => Gender.other,
    SignupGender.preferNotToSay => Gender.preferNotToSay,
  };
}

extension GenderToForm on Gender {
  SignupGender toForm() => switch (this) {
    Gender.male => SignupGender.male,
    Gender.female => SignupGender.female,
    Gender.other => SignupGender.other,
    Gender.preferNotToSay => SignupGender.preferNotToSay,
  };
}

/// Builds the `UserForm.initialValues` map from a [UserPrivate] (or defaults
/// when null). Text fields normalize `null` → `''` so the form's `isDirty`
/// comparison works cleanly.
Map<String, dynamic> buildUserFormInitialValues(UserPrivate? user) {
  final ec = UserFormAssembly.parseEmergencyContact(user?.emergencyContact);
  return {
    UserFormFields.usernameId: user?.username ?? '',
    UserFormFields.emailId: user?.email ?? '',
    UserFormFields.passwordId: '',
    UserFormFields.confirmPasswordId: '',
    UserFormFields.firstNameId: user?.firstName ?? '',
    UserFormFields.middleNameId: user?.middleName ?? '',
    UserFormFields.lastNameId: user?.lastName ?? '',
    UserFormFields.nicknameId: user?.nickname ?? '',
    UserFormFields.phoneId: user?.phone ?? '',
    UserFormFields.emergencyContactNameId: ec.name ?? '',
    UserFormFields.emergencyContactRelationId: ec.relation,
    UserFormFields.emergencyContactPhoneId: ec.phone ?? '',
    UserFormFields.medicalInfoId: user?.medicalInfo ?? '',
    UserFormFields.addrLine1Id: user?.address?.addrLine1 ?? '',
    UserFormFields.addrLine2Id: user?.address?.addrLine2 ?? '',
    UserFormFields.cityId: user?.address?.city ?? '',
    UserFormFields.stateId: user?.address?.state,
    UserFormFields.pincodeId: user?.address?.pincode ?? '',
    UserFormFields.genderId: user?.gender?.toForm(),
    UserFormFields.dateOfBirthUtcId: UserFormAssembly.floorToUtcMidnight(
      user?.dateOfBirthUtc,
    ),
    UserFormFields.useNamePubliclyId: user?.useNamePublicly ?? false,
    UserFormFields.isPublicProfileId: user?.isPublicProfile ?? false,
  };
}

/// Builds an SDK [Address] from the form's flat address fields, or `null`
/// when every field is empty.
Address? assembleSdkAddress(Map<String, dynamic> values) {
  final form = UserFormAssembly.assembleAddress(
    addrLine1: UserFormAssembly.maybe(UserFormFields.addrLine1Id, values),
    addrLine2: UserFormAssembly.maybe(UserFormFields.addrLine2Id, values),
    city: UserFormAssembly.maybe(UserFormFields.cityId, values),
    state: values[UserFormFields.stateId] as String?,
    pincode: UserFormAssembly.maybe(UserFormFields.pincodeId, values),
  );
  if (form == null) return null;
  return Address(
    addrLine1: form.addrLine1,
    addrLine2: form.addrLine2,
    city: form.city,
    state: form.state,
    pincode: form.pincode,
  );
}

/// SDK adapter helpers — bridge the form's `Map<String, dynamic>` to typed
/// SDK calls via the master notifier.
class UserFormSubmit {
  /// Extracts map values and calls `notifier.createUser` with named params.
  ///
  /// After creation, if the form requested role assignments (`assignAdmin`
  /// or `assignCoach`), each role is applied via `notifier.assignRole`. The
  /// returned list contains the names of any roles that could not be
  /// assigned — empty when everything succeeded. The user record is always
  /// created regardless of role-assignment outcome; failed roles can be
  /// retried from the profile screen.
  ///
  /// The phone and the emergency contact's phone are stored in international
  /// format, completed with [defaultCountryCode] when typed without a
  /// country code (#31).
  static Future<List<String>> create({
    required Map<String, dynamic> values,
    required ClUsersMasterNotifier notifier,
    required String defaultCountryCode,
  }) async {
    await notifier.createUser(
      username: (values[UserFormFields.usernameId] as String).trim(),
      email: (values[UserFormFields.emailId] as String).trim(),
      passwordHash:
          (values[UserFormFields.useDefaultPasswordId] as bool? ?? true)
          ? defaultUserPassword
          : values[UserFormFields.passwordId] as String,
      phone: PhoneNumber.toInternational(
        values[UserFormFields.phoneId] as String,
        defaultCountryCode: defaultCountryCode,
      ),
      dateOfBirthUtc: UserFormAssembly.floorToUtcMidnight(
        values[UserFormFields.dateOfBirthUtcId] as DateTime?,
      )!,
      gender: (values[UserFormFields.genderId] as SignupGender).toSdk(),
      firstName: UserFormAssembly.maybe(UserFormFields.firstNameId, values),
      middleName: UserFormAssembly.maybe(UserFormFields.middleNameId, values),
      lastName: UserFormAssembly.maybe(UserFormFields.lastNameId, values),
      emergencyContact: UserFormAssembly.mergeEmergencyContact(
        name: UserFormAssembly.maybe(
          UserFormFields.emergencyContactNameId,
          values,
        ),
        relation: values[UserFormFields.emergencyContactRelationId] as String?,
        phone: PhoneNumber.toInternationalOrNull(
          values[UserFormFields.emergencyContactPhoneId] as String?,
          defaultCountryCode: defaultCountryCode,
        ),
      ),
      medicalNotes: UserFormAssembly.maybe(
        UserFormFields.medicalInfoId,
        values,
      ),
      address: assembleSdkAddress(values),
    );

    final username = (values[UserFormFields.usernameId] as String).trim();
    final failed = <String>[];
    if (values[UserFormFields.assignAdminId] as bool? ?? false) {
      try {
        await notifier.assignRole(username, 'admin');
      } on Object catch (_) {
        failed.add('admin');
      }
    }
    if (values[UserFormFields.assignCoachId] as bool? ?? false) {
      try {
        await notifier.assignRole(username, 'coach');
      } on Object catch (_) {
        failed.add('coach');
      }
    }
    return failed;
  }

  /// What the create form shows for a refused creation: a message on the
  /// field the server's answer names, keyed by field id. Empty when [error]
  /// names no field.
  static Map<String, String> fieldErrorsFor(ServerException error) {
    if (error.code == SdkErrorCode.duplicateUsername) {
      return const {
        UserFormFields.usernameId: MemberWriteMessages.usernameTaken,
      };
    }
    if (error.code == SdkErrorCode.duplicateEmail) {
      return const {
        UserFormFields.emailId: MemberWriteMessages.emailRegistered,
      };
    }
    return const {};
  }

  /// Partial update of the personal-details section (names, nickname, and —
  /// when the editor was allowed to change them — public-name flag, gender,
  /// and date of birth). Only the keys present in [values] are sent, so other
  /// sections are untouched.
  static Future<void> updatePersonalDetails({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
  }) {
    return notifier.updateUser(
      username,
      firstName: () =>
          UserFormAssembly.maybe(UserFormFields.firstNameId, values),
      middleName: () =>
          UserFormAssembly.maybe(UserFormFields.middleNameId, values),
      lastName: () => UserFormAssembly.maybe(UserFormFields.lastNameId, values),
      nickname: () => UserFormAssembly.maybe(UserFormFields.nicknameId, values),
      useNamePublicly: values[UserFormFields.useNamePubliclyId] as bool?,
      isPublicProfile: values[UserFormFields.isPublicProfileId] as bool?,
      gender: values.containsKey(UserFormFields.genderId)
          ? () => (values[UserFormFields.genderId] as SignupGender?)?.toSdk()
          : null,
      dateOfBirthUtc: values.containsKey(UserFormFields.dateOfBirthUtcId)
          ? () => UserFormAssembly.floorToUtcMidnight(
              values[UserFormFields.dateOfBirthUtcId] as DateTime?,
            )
          : null,
    );
  }

  /// Partial update of the address section.
  static Future<void> updateAddress({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
  }) {
    return notifier.updateUser(
      username,
      address: () => assembleSdkAddress(values),
    );
  }

  /// Partial update of the contact section (email, phone, emergency contact,
  /// medical notes).
  ///
  /// The phone and the emergency contact's phone are stored in international
  /// format, completed with [defaultCountryCode] when typed without a
  /// country code (#31).
  static Future<void> updateContact({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
    required String defaultCountryCode,
  }) {
    return notifier.updateUser(
      username,
      email: (values[UserFormFields.emailId] as String?)?.trim(),
      phone: () => PhoneNumber.toInternationalOrNull(
        values[UserFormFields.phoneId] as String?,
        defaultCountryCode: defaultCountryCode,
      ),
      emergencyContact: () => UserFormAssembly.mergeEmergencyContact(
        name: UserFormAssembly.maybe(
          UserFormFields.emergencyContactNameId,
          values,
        ),
        relation: values[UserFormFields.emergencyContactRelationId] as String?,
        phone: PhoneNumber.toInternationalOrNull(
          values[UserFormFields.emergencyContactPhoneId] as String?,
          defaultCountryCode: defaultCountryCode,
        ),
      ),
      medicalNotes: () =>
          UserFormAssembly.maybe(UserFormFields.medicalInfoId, values),
    );
  }
}
