import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/profile_label_language.dart';
import 'profile_options_form_values.dart';
import 'profile_positions_editor.dart';

/// `ShadForm` field holding the club's positions, edited by a
/// [ProfilePositionsEditor]; a validator's message shows under the list.
///
/// The value is typed as a plain list because a form hands its fields
/// their initial values as plain lists; `ProfileOptionsFormValues` reads
/// it.
class ProfilePositionsField extends ShadFormBuilderField<List<Object?>> {
  ProfilePositionsField({
    required List<ProfileLabelLanguage> labelLanguages,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => ProfilePositionsEditor(
           labelLanguages: labelLanguages,
           initialRows: ProfileOptionsFormValues.positions(
             state.value,
             labelLanguages,
           ),
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
