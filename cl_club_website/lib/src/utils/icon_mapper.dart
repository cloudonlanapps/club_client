import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Maps icon names from JSON to Lucide IconData.
/// Fallback to a default icon if name not found.
IconData mapIconName(String iconName) {
  const iconMap = <String, IconData>{
    'target': LucideIcons.target,
    'eye': LucideIcons.eye,
    'heart': LucideIcons.heart,
    'star': LucideIcons.star,
    'trophy': LucideIcons.trophy,
    'users': LucideIcons.users,
    'shield': LucideIcons.shield,
    'award': LucideIcons.award,
    'flag': LucideIcons.flag,
    'medal': LucideIcons.medal,
    'sparkles': LucideIcons.sparkles,
    'handshake': LucideIcons.handshake,
  };
  return iconMap[iconName] ?? LucideIcons.circle;
}
