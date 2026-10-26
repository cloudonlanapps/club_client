import 'package:flutter/widgets.dart';

/// Builds the editor of one item of an application list, seeded from
/// [initial] (the item as the template's JSON holds it) and reporting the
/// item through [onChanged] on every edit.
typedef ApplicationItemBuilder =
    Widget Function({
      required Object? initial,
      required ValueChanged<Object?> onChanged,
      required bool enabled,
    });
