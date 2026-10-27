import 'package:cl_remote_store/cl_remote_store.dart'
    show ClApplicationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationTemplate;
import 'package:flutter/widgets.dart';

import '../../models/application_editor_options.dart';

/// Saves a section's values to draft `id` (an `ApplicationFormSubmit`
/// section method).
typedef ApplicationSectionSave =
    Future<ApplicationTemplate> Function({
      required int id,
      required Map<String, dynamic> values,
      required ClApplicationsMasterNotifier notifier,
    });

/// Builds a section's form: its key, the template as the forms hold it,
/// what the forms choose from, and whether it responds.
typedef ApplicationSectionFormBuilder =
    Widget Function(
      Key key,
      Map<String, dynamic> template,
      ApplicationEditorOptions options, {
      required bool enabled,
    });

/// How the editor hosts one section's form: builds it, drives it through
/// the `GlobalKey` of its state, and saves what it returns.
abstract interface class ApplicationSectionSpec {
  /// Builds the form under the key it is given.
  ApplicationSectionFormBuilder get build;

  /// Saves the form's values.
  ApplicationSectionSave get save;

  /// The form's values, or null when invalid.
  Map<String, dynamic>? validate(GlobalKey key);

  /// Whether anything in the form changed.
  bool isDirty(GlobalKey key);

  /// Puts what the server refused back on the form.
  void showErrors(
    GlobalKey key, {
    Map<String, String> fieldErrors = const {},
    String? formError,
  });
}

/// An [ApplicationSectionSpec] whose form's state is an [S].
class TypedApplicationSectionSpec<S extends State<StatefulWidget>>
    implements ApplicationSectionSpec {
  const TypedApplicationSectionSpec({
    required this.build,
    required this.save,
    required this.onValidate,
    required this.onIsDirty,
    required this.onShowErrors,
  });

  @override
  final ApplicationSectionFormBuilder build;

  @override
  final ApplicationSectionSave save;

  /// The state's `validate()`.
  final Map<String, dynamic>? Function(S state) onValidate;

  /// The state's `isDirty`.
  final bool Function(S state) onIsDirty;

  /// The state's `showErrors`.
  final void Function(S state, Map<String, String> fields, String? form)
  onShowErrors;

  /// The form's state under [key], when it is built.
  S? stateOf(GlobalKey key) => switch (key.currentState) {
    final S state => state,
    _ => null,
  };

  @override
  Map<String, dynamic>? validate(GlobalKey key) => switch (stateOf(key)) {
    final S state => onValidate(state),
    null => null,
  };

  @override
  bool isDirty(GlobalKey key) => switch (stateOf(key)) {
    final S state => onIsDirty(state),
    null => false,
  };

  @override
  void showErrors(
    GlobalKey key, {
    Map<String, String> fieldErrors = const {},
    String? formError,
  }) {
    if (stateOf(key) case final S state) {
      onShowErrors(state, fieldErrors, formError);
    }
  }
}
