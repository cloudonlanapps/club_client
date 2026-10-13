import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

/// A field the server refused at its schema: its `path`, the names from the
/// request's top level down to the field joined by [schemaPathSeparator]
/// (`email`, `address.pincode`, `sessions.1.startMinute`), and the reason.
typedef SchemaRefusedField = ({String path, String message});

/// Joins the names of a refused field's path.
const String schemaPathSeparator = '.';

/// Shown on a field the server refused without saying why.
const String schemaRefusalFallbackMessage = 'This value was not accepted.';

/// The key of a refused field's path in the SDK's entry for it.
const String schemaRefusalPathKey = 'loc';

/// The key of a refused field's reason in the SDK's entry for it.
const String schemaRefusalReasonKey = 'msg';

/// What the server's validators put before their own reason.
const List<String> schemaRefusalReasonPrefixes = [
  'Value error, ',
  'Assertion failed, ',
];

/// The fields the server refused at its schema, when [error] is a schema
/// rejection (422 `VALIDATION_ERROR`, club_client#114, club_sdk#19), in the
/// server's order; empty for any other error.
///
/// The SDK keeps each refused field under
/// [ServerException.refusedFieldsKey] with its path, whose first name is the
/// part of the request it came in (`body`, `query`, `path`) and is left out
/// here. A refusal of the request as a whole has no name after that and is
/// not a field.
List<SchemaRefusedField> schemaRefusedFields(Object error) {
  if (error is! ServerException || error.code != SdkErrorCode.validationError) {
    return const [];
  }
  final entries = error.details?[ServerException.refusedFieldsKey];
  if (entries is! List) return const [];
  return [
    for (final entry in entries)
      if (entry is Map && entry[schemaRefusalPathKey] is List)
        if ((entry[schemaRefusalPathKey] as List).skip(1).toList()
            case final names when names.isNotEmpty)
          (
            path: names.join(schemaPathSeparator),
            message: schemaRefusalReason(entry[schemaRefusalReasonKey]),
          ),
  ];
}

/// The reason of a refused field as a form shows it: the server's own
/// words, without its validator's prefix and starting with a capital;
/// [schemaRefusalFallbackMessage] when it gave none.
String schemaRefusalReason(Object? reason) {
  var text = reason is String ? reason.trim() : '';
  for (final prefix in schemaRefusalReasonPrefixes) {
    if (text.startsWith(prefix)) text = text.substring(prefix.length).trim();
  }
  if (text.isEmpty) return schemaRefusalFallbackMessage;
  return text[0].toUpperCase() + text.substring(1);
}

/// What a schema rejection puts on the fields of a form
/// (club_client#114): [fieldIds] maps a server field path (see
/// [SchemaRefusedField]) to the id of the form field that holds it, and the
/// answer maps each such id to the server's reason.
///
/// A refused field inside one the form holds as a whole (a list or a
/// composite field) shows on that one: `sessions.1.startMinute` matches
/// `sessions`. The first reason stays on a field refused more than once. A
/// field the form does not hold is left out, so an empty answer means the
/// rejection is about nothing the form holds, as for any other error.
Map<String, String> schemaFieldErrors(
  Object error,
  Map<String, String> fieldIds,
) {
  final errors = <String, String>{};
  for (final refused in schemaRefusedFields(error)) {
    final names = refused.path.split(schemaPathSeparator);
    for (var length = names.length; length > 0; length--) {
      final fieldId = fieldIds[names.take(length).join(schemaPathSeparator)];
      if (fieldId == null) continue;
      errors.putIfAbsent(fieldId, () => refused.message);
      break;
    }
  }
  return errors;
}
