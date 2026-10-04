/// Form-local postal address — the five fields the user form edits.
///
/// Mirrors the SDK `Address` shape without importing `club_sdk_2`, keeping
/// `ui_lib` SDK-free. The caller adapts between [FormAddress] and the SDK
/// `Address` at the boundary (see `cl_club_members` `user_form_helpers.dart`).
class FormAddress {
  const FormAddress({
    this.addrLine1,
    this.addrLine2,
    this.city,
    this.state,
    this.pincode,
  });

  final String? addrLine1;
  final String? addrLine2;
  final String? city;
  final String? state;
  final String? pincode;

  /// True when every field is null or blank.
  bool get isEmpty =>
      (addrLine1?.trim().isEmpty ?? true) &&
      (addrLine2?.trim().isEmpty ?? true) &&
      (city?.trim().isEmpty ?? true) &&
      (state?.trim().isEmpty ?? true) &&
      (pincode?.trim().isEmpty ?? true);
}
