import 'package:flutter/widgets.dart';

/// Field-id constants, texts and keys of the `ShadForm` inside
/// `ClubLanguageForm`.
class ClubLanguageFormFields {
  ClubLanguageFormFields._();

  /// The language code to add.
  static const String languageCodeId = 'languageCode';

  /// Label of [languageCodeId].
  static const String languageCodeLabel = 'Add a language code';

  /// Hint shown in the empty input.
  static const String languageCodePlaceholder = 'e.g. mr or hi';

  /// Key of the input, for tests and the integration suite.
  static const Key languageCodeKey = ValueKey('clubIdentity.addLanguage');
}
