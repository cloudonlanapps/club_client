import 'package:flutter/widgets.dart';

import '../form/form_contract.dart';
import 'marketing_values_equal.dart';

/// What a marketing form adds to [FormContract]: its values as they stand,
/// unchecked, for the host's live preview ([draft]), and an [isDirty] that
/// compares the lists it holds item by item.
mixin MarketingFormDraft<T extends StatefulWidget> on FormContract<T> {
  /// What the form holds now, shaped as [validate] would return it but
  /// without checking it; empty before the form is built.
  Map<String, dynamic> get draft {
    final values = fieldValues;
    return values == null ? const {} : assemble(values);
  }

  /// Whether anything differs from its initial value. The rows of a list
  /// are new maps after every edit, so they are compared by what they hold.
  @override
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !marketingValuesEqual(form.initialValue, form.value);
  }
}
