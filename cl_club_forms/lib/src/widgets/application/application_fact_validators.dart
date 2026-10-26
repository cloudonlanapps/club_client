import '../../models/application/application_custom_text.dart';
import '../../models/application/application_fact_type.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';

/// Checks of one fact of the facts form: its name, and a whole value for
/// its type. Each returns `null` when it is fine, or the message.
abstract final class ApplicationFactValidators {
  /// What a fact's name looks like: a lower-case letter, then lower-case
  /// letters, digits and `_`.
  static final RegExp namePattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// A day as the template stores it.
  static final RegExp dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// A time of day as the template stores it, 24-hour.
  static final RegExp timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// A fact's [name]: there, and like an identifier.
  static String? name(Object? name) {
    if (name is! String || name.isEmpty) {
      return ApplicationFormStrings.factNameRequired;
    }
    if (!namePattern.hasMatch(name)) {
      return ApplicationFormStrings.factNameForm(name);
    }
    return null;
  }

  /// The value of [fact], a row of the facts form, for its type.
  static String? value(Map<Object?, Object?> fact) {
    final value = fact[ApplicationFormFields.valueKey];
    final from = fact[ApplicationFormFields.fromKey];
    final to = fact[ApplicationFormFields.toKey];
    final type = ApplicationFactType.fromJson(
      fact[ApplicationFormFields.typeKey],
    );
    return switch (type) {
      ApplicationFactType.name || null =>
        (value is String && value.trim().isNotEmpty) ||
                (ApplicationCustomText.fromJson(
                          value,
                        ).text[ApplicationFormFields.english] ??
                        '')
                    .isNotEmpty
            ? null
            : ApplicationFormStrings.englishRequired,
      ApplicationFactType.date =>
        isDay(value) ? null : ApplicationFormStrings.dateRequired,
      ApplicationFactType.dateRange => range(from, to),
      ApplicationFactType.time =>
        value is String && timePattern.hasMatch(value)
            ? null
            : ApplicationFormStrings.timeRequired,
      ApplicationFactType.amount =>
        value is int && value >= 0
            ? null
            : ApplicationFormStrings.amountRequired,
      ApplicationFactType.choices =>
        value is List && value.isNotEmpty
            ? null
            : ApplicationFormStrings.choicesRequired,
    };
  }

  /// A range from [from] to [to]: both days, the last not before the
  /// first.
  static String? range(Object? from, Object? to) {
    if (!isDay(from) || !isDay(to)) return ApplicationFormStrings.rangeRequired;
    return (to! as String).compareTo(from! as String) < 0
        ? ApplicationFormStrings.rangeOrder
        : null;
  }

  /// Whether [value] is a day as stored.
  static bool isDay(Object? value) =>
      value is String && dayPattern.hasMatch(value);
}
