import 'package:flutter/material.dart';

/// Loading indicator for content section.
class LoadingContent extends StatelessWidget {
  const LoadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
