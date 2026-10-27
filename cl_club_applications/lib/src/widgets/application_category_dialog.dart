import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_view_strings.dart';

/// One age category a member fits, as the category dialog offers it: its
/// `index` in the template and the `name` shown.
typedef ApplicationCategoryChoice = ({int index, String name});

/// Asks which of the age categories in [choices] a member's form ticks,
/// when the member fits more than one (club_client#337). Resolves to the
/// chosen category's index on **Download**, and to null on **Cancel** or
/// when the dialog is dismissed. Nothing is remembered: it asks on every
/// download.
Future<int?> showApplicationCategoryDialog(
  BuildContext context, {
  required List<ApplicationCategoryChoice> choices,
}) => showShadDialog<int>(
  context: context,
  builder: (_) => ApplicationCategoryDialog(choices: choices),
);

/// "Which age category?", with one choice per category in [choices],
/// **Cancel** and **Download**. **Download** is off until one is chosen;
/// each answer closes the dialog with its value, and the caller acts on it.
class ApplicationCategoryDialog extends StatefulWidget {
  const ApplicationCategoryDialog({required this.choices, super.key});

  /// Key of the **Download** button.
  static const Key downloadKey = ValueKey('application.category.download');

  /// Key of the **Cancel** button.
  static const Key cancelKey = ValueKey('application.category.cancel');

  /// Key of the choice of the category at [index].
  static Key choiceKey(int index) => ValueKey('application.category.$index');

  /// The categories to choose among, in the template's order.
  final List<ApplicationCategoryChoice> choices;

  @override
  State<ApplicationCategoryDialog> createState() =>
      ApplicationCategoryDialogState();
}

/// State of [ApplicationCategoryDialog]: the category chosen so far.
class ApplicationCategoryDialogState extends State<ApplicationCategoryDialog> {
  /// The index of the category chosen; null before a choice.
  int? chosen;

  @override
  Widget build(BuildContext context) {
    final picked = chosen;
    return ShadDialog(
      title: const Text(ApplicationViewStrings.chooseCategoryTitle),
      description: const Text(ApplicationViewStrings.chooseCategoryMessage),
      actions: [
        ShadButton.outline(
          key: ApplicationCategoryDialog.cancelKey,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ApplicationViewStrings.chooseCategoryCancel),
        ),
        ShadButton(
          key: ApplicationCategoryDialog.downloadKey,
          enabled: picked != null,
          onPressed: () => Navigator.of(context).pop(picked),
          child: const Text(ApplicationViewStrings.chooseCategoryDownload),
        ),
      ],
      child: ShadRadioGroup<int>(
        onChanged: (index) => setState(() => chosen = index),
        items: [
          for (final choice in widget.choices)
            ShadRadio<int>(
              key: ApplicationCategoryDialog.choiceKey(choice.index),
              value: choice.index,
              label: Text(choice.name),
            ),
        ],
      ),
    );
  }
}
