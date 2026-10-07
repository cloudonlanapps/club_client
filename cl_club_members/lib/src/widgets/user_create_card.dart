import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The card of the create-user view: its heading, the form and, under it,
/// the actions. Scrolls when the form is taller than the view.
class UserCreateCard extends StatelessWidget {
  const UserCreateCard({required this.form, required this.actions, super.key});

  /// Heading above the form.
  static const String title = 'Creating new profile';

  /// Around the card.
  static const EdgeInsets margin = EdgeInsets.fromLTRB(24, 0, 24, 16);

  /// Inside the card.
  static const double padding = 20;

  /// Between the heading, the form and the actions.
  static const double sectionGap = 16;

  /// The create form.
  final Widget form;

  /// The view's Cancel and Create actions.
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ShadCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: sectionGap,
            children: [
              Text(title, style: ShadTheme.of(context).textTheme.h4),
              form,
              actions,
            ],
          ),
        ),
      ),
    );
  }
}
