import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/application_fact_strings.dart';
import '../constants/application_view_sizes.dart';

/// The (?) at the right end of the Facts heading (club_client#389): opens,
/// on hover and on tap, what a fact is and how a text prints one with
/// `{name}`, with one example of each type. Hover opens it while the
/// pointer is over it; a tap keeps it open until the next tap or a tap
/// outside.
class ApplicationFactsHelp extends StatefulWidget {
  const ApplicationFactsHelp({super.key});

  @override
  State<ApplicationFactsHelp> createState() => ApplicationFactsHelpState();
}

/// State of [ApplicationFactsHelp]: the popover and whether a tap holds it
/// open.
class ApplicationFactsHelpState extends State<ApplicationFactsHelp> {
  /// Shows and hides the help.
  final ShadPopoverController controller = ShadPopoverController();

  /// Whether a tap opened it, so leaving with the pointer keeps it open.
  bool pinned = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(onChanged);
  }

  @override
  void dispose() {
    controller
      ..removeListener(onChanged)
      ..dispose();
    super.dispose();
  }

  /// A closed help is no longer held open.
  void onChanged() {
    if (!controller.isOpen) pinned = false;
  }

  /// A tap holds the help open, or closes it.
  void toggle() {
    pinned = !pinned;
    pinned ? controller.show() : controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadPopover(
      controller: controller,
      popover: (context) => const SizedBox(
        width: ApplicationViewSizes.helpWidth,
        child: ApplicationFactsHelpBody(),
      ),
      child: Semantics(
        button: true,
        label: ApplicationFactStrings.helpLabel,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => controller.show(),
          onExit: (_) {
            if (!pinned) controller.hide();
          },
          child: GestureDetector(
            key: const ValueKey('application.facts.help'),
            behavior: HitTestBehavior.opaque,
            onTap: toggle,
            child: Icon(
              LucideIcons.circleHelp,
              size: ApplicationViewSizes.helpIcon,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// What the Facts help says.
class ApplicationFactsHelpBody extends StatelessWidget {
  const ApplicationFactsHelpBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: ApplicationViewSizes.smallGap,
      children: [
        Text(ApplicationFactStrings.helpTitle, style: theme.textTheme.large),
        Text(ApplicationFactStrings.helpIntro, style: theme.textTheme.small),
        Text(
          ApplicationFactStrings.helpExamplesTitle,
          style: theme.textTheme.small,
        ),
        for (final (type, fact, use) in ApplicationFactStrings.helpExamples)
          Text(
            ApplicationFactStrings.helpExample(type, fact, use),
            style: theme.textTheme.muted,
          ),
        Text(ApplicationFactStrings.helpNote, style: theme.textTheme.muted),
      ],
    );
  }
}
