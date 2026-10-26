import 'package:flutter/widgets.dart';

import '../form/form_contract.dart';
import 'application_form_values.dart';

/// What the section forms of an application add to [FormContract]: their
/// fields are lists and custom fields.
mixin ApplicationSectionContract<T extends StatefulWidget> on FormContract<T> {
  /// Whether anything differs from its initial value. Overridden because a
  /// section's values are lists of maps, which an edit replaces and
  /// `mapEquals` would compare by identity: they are compared item by item
  /// (rule 8).
  @override
  bool get isDirty {
    final form = formKey.currentState;
    return form != null &&
        !ApplicationFormValues.same(form.initialValue, form.value);
  }

  /// Lists and custom fields have nothing of their own to focus.
  @override
  bool get focusFirstInvalid => false;
}
