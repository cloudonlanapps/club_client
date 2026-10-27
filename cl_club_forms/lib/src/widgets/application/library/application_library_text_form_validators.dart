import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_text_value.dart';
import '../application_form_strings.dart';
import 'application_library_text_form_fields.dart';

/// Checks of `ApplicationLibraryTextForm` (club_client#389), as the server
/// makes them (club_server#126). Each returns `null` when fine, or its
/// message.
abstract final class ApplicationLibraryTextFormValidators {
  /// A kind must be picked.
  static String? kind(ApplicationClauseKind? value) =>
      value == null ? ApplicationFormStrings.libraryKindRequired : null;

  /// A name of 1–100 characters, once trimmed.
  static String? name(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return ApplicationFormStrings.libraryNameRequired;
    if (name.length > ApplicationLibraryTextFormFields.nameMaxLength) {
      return ApplicationFormStrings.libraryNameTooLong(
        ApplicationLibraryTextFormFields.nameMaxLength,
      );
    }
    return null;
  }

  /// The text, written in one language at least.
  static String? text(ApplicationTextValue? value) =>
      value == null ? ApplicationFormStrings.libraryTextRequired : null;
}
