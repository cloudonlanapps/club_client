import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../application_text_mode.dart';
import '../application_text_sources.dart';
import 'application_text_value_editor.dart';

/// `ShadForm` field holding one printed text of an application, edited by
/// an [ApplicationTextValueEditor]; a validator's message shows under it.
///
/// The value is an [ApplicationTextValue], not its JSON: `ShadForm` would
/// merge a map value into the map it started from.
class ApplicationTextValueField
    extends ShadFormBuilderField<ApplicationTextValue?> {
  ApplicationTextValueField({
    required List<ApplicationTextMode> modes,
    required List<ApplicationLanguageOption> languages,
    required ApplicationTextSources sources,
    ApplicationClauseKind? clauseKind,
    bool requireEnglish = false,
    bool multiline = false,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => ApplicationTextValueEditor(
           modes: modes,
           languages: languages,
           sources: sources,
           clauseKind: clauseKind,
           requireEnglish: requireEnglish,
           multiline: multiline,
           initialValue: state.value,
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
