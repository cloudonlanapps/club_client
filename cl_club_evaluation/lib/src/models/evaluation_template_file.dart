import 'dart:convert';

import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationLayoutEntry,
        EvaluationTemplateCreateForm,
        EvaluationTemplateCreateFormFields;

import '../constants/template_file_strings.dart';
import 'evaluation_item_adapter.dart';
import 'evaluation_template_copy.dart';
import 'template_file_exception.dart';

/// A template as a JSON file and back (club_client#27): **Export** writes
/// the server's create payload — `{name, layout}`, items inline — in an
/// envelope naming the format and its version; **Import** reads one into
/// the designer's initial values.
///
/// Items are written with the SDK's `toMap()` and read with its
/// `fromMap()`, so the file follows the API. A file holds no id, no origin
/// and no other server-owned field: an imported template is new
/// throughout, as a duplicate is.
abstract final class EvaluationTemplateFile {
  /// [template] as the text of an export file.
  static String encode(sdk.EvaluationTemplate template) {
    final byId = {for (final item in template.items) ?item.id: item};
    final layout = [
      for (final entry in template.layout)
        if (entry case sdk.EvaluationLayoutSection(:final section))
          sdk.EvaluationLayoutSection(section, [
            for (final id in entry.items) ?byId[id],
          ])
        else if (byId[entry.items.single] case final item?)
          sdk.EvaluationLayoutItem(item),
    ];
    final file = {
      TemplateFileStrings.formatKey: TemplateFileStrings.format,
      TemplateFileStrings.versionKey: TemplateFileStrings.version,
      TemplateFileStrings.nameKey: template.name,
      TemplateFileStrings.layoutKey: [
        for (final entry in layout) entry.toWire(itemMap),
      ],
    };
    const encoder = JsonEncoder.withIndent(TemplateFileStrings.indent);
    return '${encoder.convert(file)}\n';
  }

  /// [item]'s wire shape without its server-owned fields and empty values.
  static Map<String, dynamic> itemMap(sdk.EvaluationTemplateItem item) => {
    for (final MapEntry(:key, :value) in item.toMap().entries)
      if (value != null &&
          !TemplateFileStrings.serverOwnedItemKeys.contains(key))
        key: value,
  };

  /// The file name an export of template [name] is saved under: the name,
  /// with what a file name cannot hold replaced, and the extension.
  static String fileName(String name) {
    final base = name
        .replaceAll(
          RegExp(TemplateFileStrings.fileNameForbidden),
          TemplateFileStrings.fileNameFiller,
        )
        .trim();
    final usable =
        base.replaceAll(TemplateFileStrings.fileNameFiller, '').isEmpty
        ? TemplateFileStrings.fallbackFileName
        : base;
    return '$usable.${TemplateFileStrings.extension}';
  }

  /// The designer's initial values from the bytes of an export file: its
  /// name as given, and its items as new ones. Throws
  /// [TemplateFileException] naming what is wrong with a file this app
  /// cannot read.
  static Map<String, dynamic> initialValues(List<int> bytes) {
    final Object? file;
    try {
      file = json.decode(utf8.decode(bytes));
    } on FormatException {
      throw const TemplateFileException(TemplateFileStrings.notJson);
    }
    if (file is! Map<String, dynamic> ||
        file[TemplateFileStrings.formatKey] != TemplateFileStrings.format) {
      throw const TemplateFileException(TemplateFileStrings.notTemplateFile);
    }
    final version = file[TemplateFileStrings.versionKey];
    if (version != TemplateFileStrings.version) {
      throw TemplateFileException(TemplateFileStrings.unknownVersion(version));
    }
    final name = file[TemplateFileStrings.nameKey];
    final layout = file[TemplateFileStrings.layoutKey];
    if (name is! String || layout is! List) {
      throw const TemplateFileException(TemplateFileStrings.notTemplateFile);
    }
    return {
      ...EvaluationTemplateCreateForm.emptyValues,
      EvaluationTemplateCreateFormFields.nameId: name,
      EvaluationTemplateCreateFormFields.layoutId: [
        for (final (index, wire) in layout.indexed)
          EvaluationTemplateCopy.fresh(entry(wire, index + 1)),
      ],
    };
  }

  /// Layout entry [wire], at [position] (1-based) of the file, as the
  /// designer holds it. Throws [TemplateFileException] when it cannot be
  /// read.
  static EvaluationLayoutEntry entry(Object? wire, int position) {
    try {
      final read =
          sdk.EvaluationLayoutEntry<sdk.EvaluationTemplateItem>.fromWire(
            wire,
            (item) => sdk.EvaluationTemplateItem.fromMap(
              Map<String, dynamic>.from(item! as Map),
            ),
          );
      return switch (read) {
        sdk.EvaluationLayoutSection(:final section, :final items) =>
          EvaluationLayoutEntry.section(
            title: section,
            items: [for (final i in items) EvaluationItemAdapter.toValue(i)],
          ),
        sdk.EvaluationLayoutItem(:final item) => EvaluationLayoutEntry.item(
          EvaluationItemAdapter.toValue(item),
        ),
      };
    } on Object {
      throw TemplateFileException(
        TemplateFileStrings.unreadableEntry(position),
      );
    }
  }
}
