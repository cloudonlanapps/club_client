import 'package:flutter/material.dart';

/// Responsive width helper - returns max content width based on screen size
double getMaxContentWidth(double screenWidth) {
  if (screenWidth < 1000) return double.infinity; // Mobile/Tablet: full width
  if (screenWidth < 1280) return 1140; // Small desktop
  if (screenWidth < 1536) return 1320; // Large desktop
  return 1440; // Extra large
}

/// Reusable responsive container widget that centers content with max width
/// constraints
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.padding,
    this.backgroundColor,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = getMaxContentWidth(screenWidth);
    final isMobile = screenWidth < 768;
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 24,
      vertical: isMobile ? 40 : 60,
    );

    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding ?? defaultPadding, child: child),
        ),
      ),
    );
  }
}
