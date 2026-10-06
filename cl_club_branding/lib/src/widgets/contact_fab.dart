import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart' show contactInfoProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';
import 'package:ui_lib/ui_lib.dart' show launchContactUrl;

/// The contact button — WhatsApp, call, email — for the apps' auth and
/// onboarding shells and the website alike (club_core#53).
///
/// Reads `contactInfoProvider`, so it shows the server's details once they
/// arrive and the host's bundled ones until then; the WhatsApp message and
/// email subject are in the current locale's language. The dial closes by
/// itself [autoHideDuration] after opening.
///
/// Wrapped in `HeroMode(enabled: false)`: the dial's buttons are
/// `FloatingActionButton`s sharing the default hero tag, which would clash
/// with the host's own FAB during a route transition.
class ContactFab extends ConsumerStatefulWidget {
  const ContactFab({super.key});

  /// How long the dial stays open.
  static const Duration autoHideDuration = Duration(seconds: 3);

  /// How long the dial takes to open and close.
  static const Duration animationDuration = Duration(milliseconds: 250);

  /// The size of each action's icon.
  static const double actionIconSize = 20;

  @override
  ConsumerState<ContactFab> createState() => ContactFabState();
}

class ContactFabState extends ConsumerState<ContactFab>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Timer? autoHideTimer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: ContactFab.animationDuration,
    )..addStatusListener(onAnimationStatusChange);
  }

  @override
  void dispose() {
    autoHideTimer?.cancel();
    final c = controller;
    if (c != null) {
      c.removeStatusListener(onAnimationStatusChange);
      try {
        c.dispose();
      } on Object catch (_) {
        // SpeedDial may have disposed it already.
      }
      controller = null;
    }
    super.dispose();
  }

  void onAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      startAutoHideTimer();
    } else if (status == AnimationStatus.dismissed) {
      autoHideTimer?.cancel();
    }
  }

  void startAutoHideTimer() {
    autoHideTimer?.cancel();
    autoHideTimer = Timer(ContactFab.autoHideDuration, () {
      final c = controller;
      if (mounted && c != null && c.isCompleted) c.reverse();
    });
  }

  /// Closes the dial and opens [url].
  Future<void> launch(String url) async {
    controller?.reverse();
    await launchContactUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(contactInfoProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final ctrl = controller;
    if (ctrl == null) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final buttonBg = theme.colorScheme.secondary;
    final buttonFg = theme.colorScheme.secondaryForeground;

    return HeroMode(
      enabled: false,
      child: SpeedDial(
        controller: ctrl,
        closedForegroundColor: theme.colorScheme.primaryForeground,
        openForegroundColor: theme.colorScheme.destructiveForeground,
        closedBackgroundColor: theme.colorScheme.primary,
        openBackgroundColor: theme.colorScheme.destructive,
        labelsStyle: theme.textTheme.small.copyWith(
          fontWeight: FontWeight.w500,
        ),
        labelsBackgroundColor: theme.colorScheme.card,
        speedDialChildren: [
          SpeedDialChild(
            child: const Icon(
              LucideIcons.messageCircle,
              size: ContactFab.actionIconSize,
            ),
            foregroundColor: buttonFg,
            backgroundColor: buttonBg,
            label: 'WhatsApp',
            onPressed: () => launch(contact.whatsappUrl(languageCode)),
          ),
          SpeedDialChild(
            child: const Icon(
              LucideIcons.phone,
              size: ContactFab.actionIconSize,
            ),
            foregroundColor: buttonFg,
            backgroundColor: buttonBg,
            label: 'Call Us',
            onPressed: () => launch(contact.phoneUrl),
          ),
          SpeedDialChild(
            child: const Icon(
              LucideIcons.mail,
              size: ContactFab.actionIconSize,
            ),
            foregroundColor: buttonFg,
            backgroundColor: buttonBg,
            label: 'Email',
            onPressed: () => launch(contact.emailUrl(languageCode)),
          ),
        ],
        child: const Icon(LucideIcons.messageCircle),
      ),
    );
  }
}
