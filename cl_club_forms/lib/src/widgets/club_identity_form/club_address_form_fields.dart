/// Field-id constants and labels of the `ShadForm` inside `ClubAddressForm`.
class ClubAddressFormFields {
  ClubAddressFormFields._();

  /// The first address line; translatable.
  static const String addressId = 'address';

  /// The second address line; translatable.
  static const String addressLine2Id = 'addressLine2';

  /// The city; translatable.
  static const String cityId = 'city';

  /// The state; translatable.
  static const String stateId = 'state';

  /// The postal code.
  static const String postalCodeId = 'postalCode';

  /// Label of [addressId].
  static const String addressLabel = 'Address';

  /// Label of [addressLine2Id].
  static const String addressLine2Label = 'Address line 2';

  /// Label of [cityId].
  static const String cityLabel = 'City';

  /// Label of [stateId].
  static const String stateLabel = 'State';

  /// Label of [postalCodeId].
  static const String postalCodeLabel = 'Postal code';

  /// Every field's label, in the order the form shows them.
  static const Map<String, String> labels = {
    addressId: addressLabel,
    addressLine2Id: addressLine2Label,
    cityId: cityLabel,
    stateId: stateLabel,
    postalCodeId: postalCodeLabel,
  };

  /// The plain text fields; each value is a `String`.
  static const List<String> textIds = [postalCodeId];

  /// The translatable fields; each value is a `FormTranslatedText`.
  static const List<String> translatedIds = [
    addressId,
    addressLine2Id,
    cityId,
    stateId,
  ];
}
