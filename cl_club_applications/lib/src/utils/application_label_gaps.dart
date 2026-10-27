import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationCompleteness, ApplicationFormFields, ApplicationLabelOption;

/// One club label a template cannot be finalized with yet: its key, its
/// name (its English text, or the key) and the print languages it lacks,
/// by code.
typedef ApplicationLabelGap = ({
  String key,
  String name,
  List<String> languages,
});

/// The club's [labels] that lack one of [template]'s print languages, as
/// Finalize checks them (club_client#396, club_server#133): a blank text
/// counts as lacking, and a label the template overrides
/// (`label_overrides`) is not listed, since its override prints instead. In
/// the labels' order.
List<ApplicationLabelGap> applicationLabelGaps(
  List<ApplicationLabelOption> labels,
  Map<String, Object?> template,
) {
  final languages = ApplicationCompleteness.languagesOf(template);
  final raw = template[ApplicationFormFields.labelOverridesId];
  final overridden = raw is Map ? raw.keys.toSet() : const <Object?>{};
  return [
    for (final label in labels)
      if (!overridden.contains(label.id))
        if ([
              for (final code in languages)
                if ((label.text[code] ?? '').trim().isEmpty) code,
            ]
            case final lacking when lacking.isNotEmpty)
          (key: label.id, name: nameOf(label), languages: lacking),
  ];
}

/// [label] as the editor names it: its English text, or its id.
String nameOf(ApplicationLabelOption label) {
  final english = (label.text[ApplicationFormFields.english] ?? '').trim();
  return english.isEmpty ? label.id : english;
}
