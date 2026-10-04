import 'package:flutter/material.dart';

import '../theme/semantic_colors.dart';

/// Rounded-square avatar with initials over a coloured background.
class AvatarCircleVariant extends StatelessWidget {
  const AvatarCircleVariant({
    required this.name,
    super.key,
    this.size = 36,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final bgColor = color ?? SemanticColors.info;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}
