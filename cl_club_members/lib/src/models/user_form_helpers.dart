import 'package:cl_club_forms/cl_club_forms.dart'
    show FormAddress, SignupGender, UserFormAssembly;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show Address, Gender, UserPrivate;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

/// Default password applied when an admin creates a user with the
/// "Use default password" toggle on. Admins are expected to know this
/// value out-of-band; it is not surfaced in the UI.
const String defaultUserPassword = 'ChangeMe123';

/// SDK ↔ form adapters for `UserForm` (which lives SDK-free in `ui_lib`).
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
    'username': user?.username ?? '',
    'email': user?.email ?? '',
    'password': '',
    'confirmPassword': '',
    'firstName': user?.firstName ?? '',
    'middleName': user?.middleName ?? '',
    'lastName': user?.lastName ?? '',
    'nickname': user?.nickname ?? '',
    'phone': user?.phone ?? '',
    'emergencyContactName': ec.name ?? '',
    'emergencyContactRelation': ec.relation,
    'emergencyContactPhone': ec.phone ?? '',
    'medicalInfo': user?.medicalInfo ?? '',
    'addrLine1': user?.address?.addrLine1 ?? '',
    'addrLine2': user?.address?.addrLine2 ?? '',
    'city': user?.address?.city ?? '',
    'state': user?.address?.state,
    'pincode': user?.address?.pincode ?? '',
    'gender': user?.gender?.toForm(),
    'dateOfBirthUtc': UserFormAssembly.floorToUtcMidnight(user?.dateOfBirthUtc),
    'useNamePublicly': user?.useNamePublicly ?? false,
    'isPublicProfile': user?.isPublicProfile ?? false,
  };
}

/// Builds an SDK [Address] from the form's flat address fields, or `null`
/// when every field is empty.
Address? assembleSdkAddress(Map<String, dynamic> values) {
  final form = UserFormAssembly.assembleAddress(
    addrLine1: UserFormAssembly.maybe('addrLine1', values),
    addrLine2: UserFormAssembly.maybe('addrLine2', values),
    city: UserFormAssembly.maybe('city', values),
    state: values['state'] as String?,
    pincode: UserFormAssembly.maybe('pincode', values),
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
      username: (values['username'] as String).trim(),
      email: (values['email'] as String).trim(),
      passwordHash: (values['useDefaultPassword'] as bool? ?? true)
          ? defaultUserPassword
          : values['password'] as String,
      phone: PhoneNumber.toInternational(
        values['phone'] as String,
        defaultCountryCode: defaultCountryCode,
      ),
      dateOfBirthUtc: UserFormAssembly.floorToUtcMidnight(
        values['dateOfBirthUtc'] as DateTime?,
      )!,
      gender: (values['gender'] as SignupGender).toSdk(),
      firstName: UserFormAssembly.maybe('firstName', values),
      middleName: UserFormAssembly.maybe('middleName', values),
      lastName: UserFormAssembly.maybe('lastName', values),
      emergencyContact: UserFormAssembly.mergeEmergencyContact(
        name: UserFormAssembly.maybe('emergencyContactName', values),
        relation: values['emergencyContactRelation'] as String?,
        phone: PhoneNumber.toInternationalOrNull(
          values['emergencyContactPhone'] as String?,
          defaultCountryCode: defaultCountryCode,
        ),
      ),
      medicalNotes: UserFormAssembly.maybe('medicalInfo', values),
      address: assembleSdkAddress(values),
    );

    final username = (values['username'] as String).trim();
    final failed = <String>[];
    if (values['assignAdmin'] as bool? ?? false) {
      try {
        await notifier.assignRole(username, 'admin');
      } on Object catch (_) {
        failed.add('admin');
      }
    }
    if (values['assignCoach'] as bool? ?? false) {
      try {
        await notifier.assignRole(username, 'coach');
      } on Object catch (_) {
        failed.add('coach');
      }
    }
    return failed;
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
      firstName: () => UserFormAssembly.maybe('firstName', values),
      middleName: () => UserFormAssembly.maybe('middleName', values),
      lastName: () => UserFormAssembly.maybe('lastName', values),
      nickname: () => UserFormAssembly.maybe('nickname', values),
      useNamePublicly: values['useNamePublicly'] as bool?,
      isPublicProfile: values['isPublicProfile'] as bool?,
      gender: values.containsKey('gender')
          ? () => (values['gender'] as SignupGender?)?.toSdk()
          : null,
      dateOfBirthUtc: values.containsKey('dateOfBirthUtc')
          ? () => UserFormAssembly.floorToUtcMidnight(
              values['dateOfBirthUtc'] as DateTime?,
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
      email: (values['email'] as String?)?.trim(),
      phone: () => PhoneNumber.toInternationalOrNull(
        values['phone'] as String?,
        defaultCountryCode: defaultCountryCode,
      ),
      emergencyContact: () => UserFormAssembly.mergeEmergencyContact(
        name: UserFormAssembly.maybe('emergencyContactName', values),
        relation: values['emergencyContactRelation'] as String?,
        phone: PhoneNumber.toInternationalOrNull(
          values['emergencyContactPhone'] as String?,
          defaultCountryCode: defaultCountryCode,
        ),
      ),
      medicalNotes: () => UserFormAssembly.maybe('medicalInfo', values),
    );
  }

  /// Extracts map values and calls `notifier.updateUser` with ValueGetter
  /// pattern.
  static Future<void> update({
    required Map<String, dynamic> values,
    required String username,
    required ClUsersMasterNotifier notifier,
  }) async {
    // Only pass a ValueGetter for fields that the form actually rendered —
    // hidden fields stay out of the PATCH so the server doesn't reject them
    // (e.g. members can't self-edit DOB or gender; sending those keys, even
    // as `null`, trips the server's PROTECTED_FIELDS guard with 403).
    await notifier.updateUser(
      username,
      email: (values['email'] as String?)?.trim(),
      firstName: () => UserFormAssembly.maybe('firstName', values),
      middleName: () => UserFormAssembly.maybe('middleName', values),
      lastName: () => UserFormAssembly.maybe('lastName', values),
      nickname: () => UserFormAssembly.maybe('nickname', values),
      phone: () => UserFormAssembly.maybe('phone', values),
      dateOfBirthUtc: values.containsKey('dateOfBirthUtc')
          ? () => UserFormAssembly.floorToUtcMidnight(
              values['dateOfBirthUtc'] as DateTime?,
            )
          : null,
      useNamePublicly: values['useNamePublicly'] as bool?,
      emergencyContact: () => UserFormAssembly.mergeEmergencyContact(
        name: UserFormAssembly.maybe('emergencyContactName', values),
        relation: values['emergencyContactRelation'] as String?,
        phone: UserFormAssembly.maybe('emergencyContactPhone', values),
      ),
      medicalNotes: () => UserFormAssembly.maybe('medicalInfo', values),
      gender: values.containsKey('gender')
          ? () => (values['gender'] as SignupGender?)?.toSdk()
          : null,
      address: () => assembleSdkAddress(values),
    );
  }
}
