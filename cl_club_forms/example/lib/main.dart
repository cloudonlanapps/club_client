import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'screens/forms_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClubFormsExampleApp());
}

class ClubFormsExampleApp extends StatefulWidget {
  const ClubFormsExampleApp({super.key});

  @override
  State<ClubFormsExampleApp> createState() => _ClubFormsExampleAppState();
}

class _ClubFormsExampleAppState extends State<ClubFormsExampleApp> {
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
      title: 'cl_club_forms example',
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
