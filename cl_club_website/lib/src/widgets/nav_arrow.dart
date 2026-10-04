import 'package:flutter/material.dart';

/// Navigation arrow button for carousels
class NavArrow extends StatelessWidget {
  const NavArrow({required this.icon, required this.onTap, super.key});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
