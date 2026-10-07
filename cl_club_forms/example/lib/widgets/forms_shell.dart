// The example is the package's own host, and reaches every form's state
// through the contract they share, which the barrel does not export.
// ignore: implementation_imports
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:flutter/material.dart';

import '../constants/demo_keys.dart';
import '../constants/demo_sizes.dart';
import '../constants/demo_strings.dart';
import '../data/form_demo_entries.dart';
import '../models/form_demo_entry.dart';
import 'form_preview.dart';
import 'forms_sidebar.dart';
import 'forms_top_bar.dart';
import 'top_bar_actions.dart';

/// The demo's frame: the sidebar of forms, the chosen form beside it, and a
/// top bar with the demo's own controls. On a narrow window the sidebar is
/// a drawer and the controls are icons.
class FormsShell extends StatefulWidget {
  /// Creates the shell.
  const FormsShell({
    required this.themeMode,
    required this.onThemeToggle,
    super.key,
  });

  /// The theme in use, which the toggle shows.
  final ThemeMode themeMode;

  /// Switches between the light and the dark theme.
  final VoidCallback onThemeToggle;

  @override
  State<FormsShell> createState() => FormsShellState();
}

/// State of [FormsShell]: the entry being shown and the key of its form.
class FormsShellState extends State<FormsShell> {
  /// The entry being shown.
  FormDemoEntry selected = FormDemoEntries.all.first;

  /// The key of the form being shown; a new one mounts the form afresh.
  GlobalKey<FormContract> formKey = GlobalKey<FormContract>();

  /// Shows [entry], its form fresh.
  void select(FormDemoEntry entry) => setState(() {
    selected = entry;
    formKey = GlobalKey<FormContract>();
  });

  /// Validates the form shown, so its messages appear on it.
  void validate() => formKey.currentState?.validate();

  /// Mounts the form shown afresh: back to its sample data, no messages.
  void reset() => setState(() => formKey = GlobalKey<FormContract>());

  @override
  Widget build(BuildContext context) {
    final preview = FormPreview(entry: selected, formKey: formKey);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < DemoSizes.drawerBreakpoint;
        final actions = TopBarActions(
          themeMode: widget.themeMode,
          compact: compact,
          onValidate: validate,
          onReset: reset,
          onThemeToggle: widget.onThemeToggle,
        );
        if (compact) {
          return Scaffold(
            appBar: AppBar(
              title: Text(selected.title),
              actions: [actions],
              leading: Builder(
                builder: (context) => IconButton(
                  key: DemoKeys.openSidebar,
                  icon: const Icon(Icons.menu),
                  tooltip: DemoStrings.openSidebar,
                  onPressed: Scaffold.of(context).openDrawer,
                ),
              ),
            ),
            drawer: Drawer(
              width: DemoSizes.sidebarWidth,
              child: Builder(
                builder: (context) => FormsSidebar(
                  selected: selected,
                  onSelect: (entry) {
                    // Closes the drawer this shell opened.
                    Navigator.of(context).pop();
                    select(entry);
                  },
                ),
              ),
            ),
            body: preview,
          );
        }
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: DemoSizes.sidebarWidth,
                child: FormsSidebar(selected: selected, onSelect: select),
              ),
              Expanded(
                child: Column(
                  children: [
                    FormsTopBar(title: selected.title, trailing: actions),
                    Expanded(child: preview),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
