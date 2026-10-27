import 'package:shadcn_ui/shadcn_ui.dart';

import 'profile_languages_editor.dart';
import 'profile_options_form_values.dart';

/// `ShadForm` field holding the club's languages, edited by a
/// [ProfileLanguagesEditor]; a validator's message shows under the list.
///
/// The value is typed as a plain list because a form hands its fields
/// their initial values as plain lists.
class ProfileLanguagesField extends ShadFormBuilderField<List<Object?>> {
  ProfileLanguagesField({
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.onChanged,
    super.key,
  }) : super(
         builder: (state) => ProfileLanguagesEditor(
           initialLanguages: ProfileOptionsFormValues.languages(state.value),
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
