import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/models/form_translated_text.dart';

import 'club_identity_form_fields.dart';
import 'translated_text_inputs.dart';

/// Pure-UI editor for the club's identity (club_core#20): name, short name,
/// inquiry email and the public contact block, as one form (no SDK / no
/// Riverpod).
///
/// Plain fields are `String`s; translatable fields are [FormTranslatedText]s,
/// a default plus optional variants per language. Each input is its own form
/// field (a variant's id is [translationId]); [ClubIdentityFormState.validate]
/// assembles them back into the flat map the host's adapter reads, every
/// value trimmed and empty variants dropped.
///
/// The languages offered are [languages] (what the host declares) plus any
/// the initial values already carry, plus any the user adds by code. The host
/// drives the form through a `GlobalKey<ClubIdentityFormState>`; the form
/// owns no Save button.
class ClubIdentityForm extends StatefulWidget {
  const ClubIdentityForm({
    required this.initialValues,
    this.languages = const [],
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// Keyed by the field ids below: a `String` for each of [textIds], a
  /// [FormTranslatedText] for each of [translatedIds]; missing reads empty.
  final Map<String, dynamic> initialValues;

  /// Language codes the host offers translations in.
  final List<String> languages;

  final bool enabled;

  /// Called on every edit, so the host can re-read `isDirty`.
  final VoidCallback? onChanged;

  // Field ids — referenced by the host's adapter.
  static const String nameId = 'name';
  static const String shortNameId = 'shortName';
  static const String inquiryEmailId = 'inquiryEmail';
  static const String phoneNumberId = 'phoneNumber';
  static const String emailId = 'email';
  static const String whatsappNumberId = 'whatsappNumber';
  static const String whatsappMessageId = 'whatsappMessage';
  static const String emailSubjectId = 'emailSubject';
  static const String taglineId = 'tagline';
  static const String addressId = 'address';
  static const String addressLine2Id = 'addressLine2';
  static const String cityId = 'city';
  static const String stateId = 'state';
  static const String postalCodeId = 'postalCode';
  static const String instagramUrlId = 'instagramUrl';

  /// The plain text fields.
  static const List<String> textIds = [
    nameId,
    shortNameId,
    inquiryEmailId,
    phoneNumberId,
    emailId,
    whatsappNumberId,
    postalCodeId,
    instagramUrlId,
  ];

  /// The translatable fields, with the label a form-level message names.
  static const Map<String, String> translatedLabels = {
    taglineId: 'Tagline',
    whatsappMessageId: 'WhatsApp message',
    emailSubjectId: 'Email subject',
    addressId: 'Address',
    addressLine2Id: 'Address line 2',
    cityId: 'City',
    stateId: 'State',
  };

  /// The translatable fields.
  static Iterable<String> get translatedIds => translatedLabels.keys;

  /// The form field id of [id]'s variant in [language].
  static String translationId(String id, String language) =>
      TranslatedTextInputs.translationIdOf(id, language);

  /// Every field empty.
  static Map<String, dynamic> get emptyValues => {
    for (final id in textIds) id: '',
    for (final id in translatedIds) id: const FormTranslatedText(''),
  };

  @override
  State<ClubIdentityForm> createState() => ClubIdentityFormState();
}

class ClubIdentityFormState extends State<ClubIdentityForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// The languages offered, in order: declared, then carried by the initial
  /// values, then added.
  late final List<String> languages = [
    ...widget.languages,
    ...{
      for (final id in ClubIdentityForm.translatedIds)
        ...initialTranslated(id).byLanguage.keys,
    }.where((l) => !widget.languages.contains(l)).toList()..sort(),
  ];

  /// A cross-field problem found by [validate].
  String? formError;

  FormTranslatedText initialTranslated(String id) =>
      widget.initialValues[id] as FormTranslatedText? ??
      const FormTranslatedText('');

  String initialText(String id) => widget.initialValues[id] as String? ?? '';

  /// Offer [language] on every translatable field.
  void addLanguage(String language) {
    if (languages.contains(language)) return;
    setState(() => languages.add(language));
  }

  /// The values as [validate] would return them, from a raw field map.
  Map<String, dynamic> assemble(Map<String, dynamic> raw) => {
    for (final id in ClubIdentityForm.textIds)
      id: (raw[id] as String? ?? '').trim(),
    for (final id in ClubIdentityForm.translatedIds)
      id: FormTranslatedText(raw[id] as String? ?? '', {
        for (final language in languages)
          language:
              raw[ClubIdentityForm.translationId(id, language)] as String? ??
              '',
      }).trimmed(),
  };

  Map<String, dynamic> get initialAssembled => {
    for (final id in ClubIdentityForm.textIds) id: initialText(id).trim(),
    for (final id in ClubIdentityForm.translatedIds)
      id: initialTranslated(id).trimmed(),
  };

  /// Validates; returns every field's value when valid, else `null`. A
  /// translatable field with variants needs its default text, which a
  /// form-level message says.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final values = assemble(form.value);
    final missingDefault = ClubIdentityForm.translatedIds.where((id) {
      final value = values[id] as FormTranslatedText;
      return value.defaultValue.isEmpty && value.byLanguage.isNotEmpty;
    }).firstOrNull;
    setState(
      () => formError = missingDefault == null
          ? null
          : '${ClubIdentityForm.translatedLabels[missingDefault]} has a '
                'translation but no default text.',
    );
    return formError == null ? values : null;
  }

  /// Whether any field differs from its initial value.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    form.save();
    return !mapEquals(assemble(form.value), initialAssembled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final problem = formError;
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      onChanged: () {
        if (formError != null) setState(() => formError = null);
        widget.onChanged?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          if (problem != null)
            Text(
              problem,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ClubIdentityFormFields(
            initialText: initialText,
            initialTranslated: initialTranslated,
            languages: List.unmodifiable(languages),
            enabled: widget.enabled,
            onAddLanguage: addLanguage,
          ),
        ],
      ),
    );
  }
}
