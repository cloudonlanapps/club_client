// The example is the package's own host, and reaches every form's state
// through the contract they share, which the barrel does not export.
// ignore: implementation_imports
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:flutter/widgets.dart';

import '../constants/demo_sizes.dart';
import 'form_demo_group.dart';

/// Builds a form with its sample data, as a host would mount it: with [key]
/// on it, through which the host reaches the form's state.
typedef FormDemoBuilder = Widget Function(GlobalKey<FormContract> key);

/// One line of the sidebar: a form, or one variant of a form, with the
/// sample data it is shown with.
@immutable
class FormDemoEntry {
  /// Creates an entry.
  const FormDemoEntry({
    required this.id,
    required this.title,
    required this.group,
    required this.formType,
    required this.builder,
    this.maxWidth = DemoSizes.formMaxWidth,
  });

  /// Names the entry apart from every other; never shown.
  final String id;

  /// The name shown in the sidebar and above the form.
  final String title;

  /// The family the sidebar lists the entry under.
  final FormDemoGroup group;

  /// The form's widget class, as the package's barrel exports it.
  final Type formType;

  /// Builds the form with its sample data.
  final FormDemoBuilder builder;

  /// Widest the card around the form grows.
  final double maxWidth;
}
