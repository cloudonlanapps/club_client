import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../utils/hex_color.dart';

/// Colour-token overrides for one brightness of a club's colour scheme.
///
/// Every token is optional: a null one keeps the base shadcn scheme's value.
/// A site reads them from its `assets/config/theme.json` (`fromMap`, colours
/// as `#RRGGBB` or `#AARRGGBB`); an app that only names a scheme leaves them
/// all null.
@immutable
class ClubColorTokens {
  /// Overrides for the tokens given; the rest keep the scheme's defaults.
  const ClubColorTokens({
    this.background,
    this.foreground,
    this.card,
    this.cardForeground,
    this.popover,
    this.popoverForeground,
    this.secondary,
    this.secondaryForeground,
    this.muted,
    this.mutedForeground,
    this.accent,
    this.accentForeground,
    this.border,
    this.input,
  });

  /// Reads tokens from a theme.json brightness block, skipping malformed
  /// colours.
  factory ClubColorTokens.fromMap(Map<String, dynamic> map) {
    return ClubColorTokens(
      background: parseHexColor(map[backgroundKey] as String?),
      foreground: parseHexColor(map[foregroundKey] as String?),
      card: parseHexColor(map[cardKey] as String?),
      cardForeground: parseHexColor(map[cardForegroundKey] as String?),
      popover: parseHexColor(map[popoverKey] as String?),
      popoverForeground: parseHexColor(map[popoverForegroundKey] as String?),
      secondary: parseHexColor(map[secondaryKey] as String?),
      secondaryForeground: parseHexColor(
        map[secondaryForegroundKey] as String?,
      ),
      muted: parseHexColor(map[mutedKey] as String?),
      mutedForeground: parseHexColor(map[mutedForegroundKey] as String?),
      accent: parseHexColor(map[accentKey] as String?),
      accentForeground: parseHexColor(map[accentForegroundKey] as String?),
      border: parseHexColor(map[borderKey] as String?),
      input: parseHexColor(map[inputKey] as String?),
    );
  }

  /// Reads tokens from the JSON [toJson] writes.
  factory ClubColorTokens.fromJson(String source) =>
      ClubColorTokens.fromMap(json.decode(source) as Map<String, dynamic>);

  /// The `background` key in a theme.json block.
  static const String backgroundKey = 'background';

  /// The `foreground` key in a theme.json block.
  static const String foregroundKey = 'foreground';

  /// The `card` key in a theme.json block.
  static const String cardKey = 'card';

  /// The `cardForeground` key in a theme.json block.
  static const String cardForegroundKey = 'cardForeground';

  /// The `popover` key in a theme.json block.
  static const String popoverKey = 'popover';

  /// The `popoverForeground` key in a theme.json block.
  static const String popoverForegroundKey = 'popoverForeground';

  /// The `secondary` key in a theme.json block.
  static const String secondaryKey = 'secondary';

  /// The `secondaryForeground` key in a theme.json block.
  static const String secondaryForegroundKey = 'secondaryForeground';

  /// The `muted` key in a theme.json block.
  static const String mutedKey = 'muted';

  /// The `mutedForeground` key in a theme.json block.
  static const String mutedForegroundKey = 'mutedForeground';

  /// The `accent` key in a theme.json block.
  static const String accentKey = 'accent';

  /// The `accentForeground` key in a theme.json block.
  static const String accentForegroundKey = 'accentForeground';

  /// The `border` key in a theme.json block.
  static const String borderKey = 'border';

  /// The `input` key in a theme.json block.
  static const String inputKey = 'input';

  /// Override for the scheme's `background`; null keeps the default.
  final Color? background;

  /// Override for the scheme's `foreground`; null keeps the default.
  final Color? foreground;

  /// Override for the scheme's `card`; null keeps the default.
  final Color? card;

  /// Override for the scheme's `cardForeground`; null keeps the default.
  final Color? cardForeground;

  /// Override for the scheme's `popover`; null keeps the default.
  final Color? popover;

  /// Override for the scheme's `popoverForeground`; null keeps the default.
  final Color? popoverForeground;

  /// Override for the scheme's `secondary`; null keeps the default.
  final Color? secondary;

  /// Override for the scheme's `secondaryForeground`; null keeps the default.
  final Color? secondaryForeground;

  /// Override for the scheme's `muted`; null keeps the default.
  final Color? muted;

  /// Override for the scheme's `mutedForeground`; null keeps the default.
  final Color? mutedForeground;

  /// Override for the scheme's `accent`; null keeps the default.
  final Color? accent;

  /// Override for the scheme's `accentForeground`; null keeps the default.
  final Color? accentForeground;

  /// Override for the scheme's `border`; null keeps the default.
  final Color? border;

  /// Override for the scheme's `input`; null keeps the default.
  final Color? input;

  /// A copy with the given tokens replaced; a getter returning null clears
  /// that override.
  ClubColorTokens copyWith({
    Color? Function()? background,
    Color? Function()? foreground,
    Color? Function()? card,
    Color? Function()? cardForeground,
    Color? Function()? popover,
    Color? Function()? popoverForeground,
    Color? Function()? secondary,
    Color? Function()? secondaryForeground,
    Color? Function()? muted,
    Color? Function()? mutedForeground,
    Color? Function()? accent,
    Color? Function()? accentForeground,
    Color? Function()? border,
    Color? Function()? input,
  }) {
    return ClubColorTokens(
      background: background != null ? background() : this.background,
      foreground: foreground != null ? foreground() : this.foreground,
      card: card != null ? card() : this.card,
      cardForeground: cardForeground != null
          ? cardForeground()
          : this.cardForeground,
      popover: popover != null ? popover() : this.popover,
      popoverForeground: popoverForeground != null
          ? popoverForeground()
          : this.popoverForeground,
      secondary: secondary != null ? secondary() : this.secondary,
      secondaryForeground: secondaryForeground != null
          ? secondaryForeground()
          : this.secondaryForeground,
      muted: muted != null ? muted() : this.muted,
      mutedForeground: mutedForeground != null
          ? mutedForeground()
          : this.mutedForeground,
      accent: accent != null ? accent() : this.accent,
      accentForeground: accentForeground != null
          ? accentForeground()
          : this.accentForeground,
      border: border != null ? border() : this.border,
      input: input != null ? input() : this.input,
    );
  }

  /// The set tokens as `#AARRGGBB` strings, which [ClubColorTokens.fromMap]
  /// reads back.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (background != null) backgroundKey: formatHexColor(background!),
      if (foreground != null) foregroundKey: formatHexColor(foreground!),
      if (card != null) cardKey: formatHexColor(card!),
      if (cardForeground != null)
        cardForegroundKey: formatHexColor(cardForeground!),
      if (popover != null) popoverKey: formatHexColor(popover!),
      if (popoverForeground != null)
        popoverForegroundKey: formatHexColor(popoverForeground!),
      if (secondary != null) secondaryKey: formatHexColor(secondary!),
      if (secondaryForeground != null)
        secondaryForegroundKey: formatHexColor(secondaryForeground!),
      if (muted != null) mutedKey: formatHexColor(muted!),
      if (mutedForeground != null)
        mutedForegroundKey: formatHexColor(mutedForeground!),
      if (accent != null) accentKey: formatHexColor(accent!),
      if (accentForeground != null)
        accentForegroundKey: formatHexColor(accentForeground!),
      if (border != null) borderKey: formatHexColor(border!),
      if (input != null) inputKey: formatHexColor(input!),
    };
  }

  /// [toMap] as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'ClubColorTokens('
        'background: $background, '
        'foreground: $foreground, '
        'card: $card, '
        'cardForeground: $cardForeground, '
        'popover: $popover, '
        'popoverForeground: $popoverForeground, '
        'secondary: $secondary, '
        'secondaryForeground: $secondaryForeground, '
        'muted: $muted, '
        'mutedForeground: $mutedForeground, '
        'accent: $accent, '
        'accentForeground: $accentForeground, '
        'border: $border, '
        'input: $input)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubColorTokens &&
        other.background == background &&
        other.foreground == foreground &&
        other.card == card &&
        other.cardForeground == cardForeground &&
        other.popover == popover &&
        other.popoverForeground == popoverForeground &&
        other.secondary == secondary &&
        other.secondaryForeground == secondaryForeground &&
        other.muted == muted &&
        other.mutedForeground == mutedForeground &&
        other.accent == accent &&
        other.accentForeground == accentForeground &&
        other.border == border &&
        other.input == input;
  }

  @override
  int get hashCode => Object.hash(
    background,
    foreground,
    card,
    cardForeground,
    popover,
    popoverForeground,
    secondary,
    secondaryForeground,
    muted,
    mutedForeground,
    accent,
    accentForeground,
    border,
    input,
  );
}
