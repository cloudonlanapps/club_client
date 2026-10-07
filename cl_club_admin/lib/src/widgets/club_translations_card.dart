import 'package:cl_club_forms/cl_club_forms.dart'
    show ClubLanguageForm, ClubLanguageFormFields, ClubLanguageFormState;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/club_identity_messages.dart';
import 'club_identity_section_body.dart';

/// The Translations card of the club details screen: the languages the
/// translatable fields of the three sections offer a text in, and a
/// [ClubLanguageForm] with a button to add one.
///
/// Adding a language stores nothing: it hands the code to [onAdd], and the
/// sections then offer an input for it. A translation is saved with the
/// section it is typed in.
class ClubTranslationsCard extends StatefulWidget {
  const ClubTranslationsCard({
    required this.languages,
    required this.onAdd,
    super.key,
  });

  /// Key of the card, for tests and the integration suite.
  static const Key cardKey = ValueKey('clubIdentity.section.translations');

  /// Key of the button that adds the typed language code.
  static const Key addKey = ValueKey('clubIdentity.addLanguage.add');

  /// Space inside the card, as in the section cards.
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Gap under the title and between the card's parts.
  static const double gap = 16;

  /// The language codes offered so far.
  final List<String> languages;

  /// Called with a valid language code that is not in [languages].
  final ValueChanged<String> onAdd;

  @override
  State<ClubTranslationsCard> createState() => ClubTranslationsCardState();
}

/// State of [ClubTranslationsCard]: holds the language form's key.
class ClubTranslationsCardState extends State<ClubTranslationsCard> {
  /// Key of the language code form.
  final formKey = GlobalKey<ClubLanguageFormState>();

  /// Hands the typed code to the host when it is valid, and empties the
  /// field.
  void add() {
    final form = formKey.currentState;
    final values = form?.validate();
    if (form == null || values == null) return;
    form.reset();
    widget.onAdd(values[ClubLanguageFormFields.languageCodeId] as String);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final languages = widget.languages;
    return ShadCard(
      key: ClubTranslationsCard.cardKey,
      padding: ClubTranslationsCard.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ClubTranslationsCard.gap,
        children: [
          Text(
            ClubIdentityMessages.translationsTitle,
            style: theme.textTheme.h4,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ClubIdentitySectionBody.formMaxWidth,
            ),
            child: ClubIdentitySectionBody(
              description: ClubIdentityMessages.translationsDescription,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: ClubTranslationsCard.gap,
                children: [
                  Text(
                    languages.isEmpty
                        ? ClubIdentityMessages.noLanguages
                        : ClubIdentityMessages.languagesPrefix +
                              languages.join(
                                ClubIdentityMessages.languagesSeparator,
                              ),
                    style: theme.textTheme.small,
                  ),
                  ClubLanguageForm(
                    key: formKey,
                    languages: languages,
                    onSubmitted: add,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ShadButton.outline(
                      key: ClubTranslationsCard.addKey,
                      onPressed: add,
                      child: const Text(ClubIdentityMessages.addLanguage),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
