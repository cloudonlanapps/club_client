import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'screens/forms_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UiLibExampleApp());
}

class UiLibExampleApp extends StatefulWidget {
  const UiLibExampleApp({super.key});

  @override
  State<UiLibExampleApp> createState() => _UiLibExampleAppState();
}

class _UiLibExampleAppState extends State<UiLibExampleApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'ui_lib example',
      themeMode: themeMode,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadBlueColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadBlueColorScheme.dark(),
      ),
      home: FormsShell(onThemeToggle: toggleTheme, themeMode: themeMode),
    );
  }
}
