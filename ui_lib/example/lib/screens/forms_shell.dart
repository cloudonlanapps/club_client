import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'admin_user_review_form_screen.dart';
import 'evaluation_screen.dart';
import 'identity_documents_screen.dart';

class _NavEntry {
  const _NavEntry({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;
}

const List<_NavEntry> _navEntries = [
  _NavEntry(title: 'Identity documents', builder: _identityDocsBuilder),
  _NavEntry(title: 'Admin user review form', builder: _adminUserReviewBuilder),
  _NavEntry(title: 'Evaluation forms', builder: _evaluationBuilder),
];

Widget _identityDocsBuilder(BuildContext _) => const IdentityDocumentsScreen();

Widget _adminUserReviewBuilder(BuildContext _) =>
    const AdminUserReviewFormScreen();

Widget _evaluationBuilder(BuildContext _) => const SingleChildScrollView(
  padding: EdgeInsets.all(16),
  child: EvaluationScreen(),
);

class FormsShell extends StatefulWidget {
  const FormsShell({
    required this.onThemeToggle,
    required this.themeMode,
    super.key,
  });

  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  State<FormsShell> createState() => _FormsShellState();
}

class _FormsShellState extends State<FormsShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final entry = _navEntries[selectedIndex];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        if (isMobile) {
          return Scaffold(
            appBar: AppBar(title: Text(entry.title), actions: [_themeToggle()]),
            drawer: Drawer(
              child: _Sidebar(
                selectedIndex: selectedIndex,
                onSelect: (i) {
                  Navigator.of(context).pop();
                  setState(() => selectedIndex = i);
                },
              ),
            ),
            body: Builder(builder: entry.builder),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 240,
                child: _Sidebar(
                  selectedIndex: selectedIndex,
                  onSelect: (i) => setState(() => selectedIndex = i),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.card,
                        border: Border(
                          bottom: BorderSide(color: theme.colorScheme.border),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(entry.title, style: theme.textTheme.large),
                          const Spacer(),
                          _themeToggle(),
                        ],
                      ),
                    ),
                    Expanded(child: Builder(builder: entry.builder)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeToggle() {
    return IconButton(
      icon: Icon(
        widget.themeMode == ThemeMode.light
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
      ),
      onPressed: widget.onThemeToggle,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(right: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ui_lib', style: theme.textTheme.large),
                  const SizedBox(height: 2),
                  Text('Forms', style: theme.textTheme.muted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'FORMS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            for (var i = 0; i < _navEntries.length; i++)
              _SidebarItem(
                title: _navEntries[i].title,
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.foreground,
          ),
        ),
      ),
    );
  }
}
