import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import 'application_text_value_editor.dart';

/// `ShadForm` field holding one printed text of an application, edited by
/// an [ApplicationTextValueEditor]; a validator's message shows under it.
///
/// The value is an [ApplicationTextValue], not its JSON: `ShadForm` would
/// merge a map value into the map it started from.
///
/// The editor is seeded once; a host that sets the field's value from
/// outside (an inserted library clause) gives a new `editorKey` with it, so
/// the editor is seeded again from that value.
class ApplicationTextValueField
    extends ShadFormBuilderField<ApplicationTextValue?> {
  ApplicationTextValueField({
    required List<ApplicationLanguageOption> languages,
    bool requireEnglish = false,
    bool multiline = false,
    Key? editorKey,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => ApplicationTextValueEditor(
           key: editorKey,
           languages: languages,
           requireEnglish: requireEnglish,
           multiline: multiline,
           initialValue: state.value,
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
