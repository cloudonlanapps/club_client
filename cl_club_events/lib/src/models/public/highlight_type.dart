import 'package:flutter/material.dart';

/// Kinds of thing the landing page's highlight carousel shows.
enum HighlightType {
  camp('Camp', Icons.sports_hockey),
  news('News', Icons.newspaper),
  vipVisit('VIP Visit', Icons.star),
  offer('Offer', Icons.local_offer),
  event('Event', Icons.event);

  const HighlightType(this.label, this.icon);

  /// Display name.
  final String label;

  /// Icon for the kind.
  final IconData icon;
}
