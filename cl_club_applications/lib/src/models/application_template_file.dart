import 'dart:convert';

import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationContent, ApplicationTemplate;

/// An application template as a JSON file, to carry it from one server to
/// another (dev to prod): its content only, never its id, state, layout or
/// dates, so an imported file always becomes a new draft that is finalized
/// on its own server.
abstract final class ApplicationTemplateFile {
  /// What a file says it is.
  static const String format = 'club.application';

  /// The file layout's version.
  static const int version = 1;

  /// The key of the content in the file.
  static const String contentKey = 'content';

  /// The file's extension.
  static const String extension = '.json';

  /// The keys of a template's content, as [encode] writes them.
  static final Set<String> _contentKeys = const ApplicationContent()
      .toMap()
      .keys
      .toSet();

  /// [template] as the file's text, indented for reading.
  static String encode(ApplicationTemplate template) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'version': version,
        contentKey: template.content.toMap(),
      });

  /// The content of a file's [bytes]; a bare content map is read too.
  /// Throws a [FormatException] for anything else.
  static ApplicationContent decode(List<int> bytes) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const FormatException('not JSON');
    }
    if (json is! Map<String, dynamic>) {
      throw const FormatException('not an object');
    }
    if (json.containsKey('format') && json['format'] != format) {
      throw const FormatException('not an application file');
    }
    final content = json.containsKey('format') ? json[contentKey] : json;
    if (content is! Map<String, dynamic>) {
      throw const FormatException('no content');
    }
    // A bare object is content only when it holds a key of one: any other
    // JSON object would read as an empty template.
    if (!json.containsKey('format') &&
        !content.keys.any(_contentKeys.contains)) {
      throw const FormatException('not application content');
    }
    try {
      return ApplicationContent.fromMap(content);
    } on Object {
      throw const FormatException('content not readable');
    }
  }

  /// The file name for an application titled [title].
  static String fileName(String title) {
    final name = title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
    return '${name.isEmpty ? 'application' : name}$extension';
  }
}
