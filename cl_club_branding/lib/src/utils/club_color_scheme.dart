import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/club_color_source.dart';

/// The club's colour scheme for [brightness]: [source]'s named shadcn scheme,
/// its brand colour and tokens applied over it, and [customColors] as the
/// scheme's `custom` map (ui_lib's `lightCustomColors` / `darkCustomColors`).
///
/// Both integrators build their themes with it: the app from `club.json`'s
/// colour name, the site from `assets/config/theme.json`.
ShadColorScheme buildClubColorScheme({
  required Brightness brightness,
  required ClubColorSource source,
  required Map<String, Color> customColors,
}) {
  final base = ShadColorScheme.fromName(
    source.schemeName,
    brightness: brightness,
  );
  final tokens = source.tokensFor(brightness);
  return base.copyWith(
    primary: source.primary ?? base.primary,
    background: tokens.background ?? base.background,
    foreground: tokens.foreground ?? base.foreground,
    card: tokens.card ?? base.card,
    cardForeground: tokens.cardForeground ?? base.cardForeground,
    popover: tokens.popover ?? base.popover,
    popoverForeground: tokens.popoverForeground ?? base.popoverForeground,
    secondary: tokens.secondary ?? base.secondary,
    secondaryForeground: tokens.secondaryForeground ?? base.secondaryForeground,
    muted: tokens.muted ?? base.muted,
    mutedForeground: tokens.mutedForeground ?? base.mutedForeground,
    accent: tokens.accent ?? base.accent,
    accentForeground: tokens.accentForeground ?? base.accentForeground,
    border: tokens.border ?? base.border,
    input: tokens.input ?? base.input,
    custom: customColors,
  );
}
