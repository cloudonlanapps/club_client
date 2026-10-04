import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A titled card grouping the inputs of one part of `ClubIdentityForm`.
class ClubIdentityFormSection extends StatelessWidget {
  const ClubIdentityFormSection({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final help = description;
    return ShadCard(
      title: Text(title),
      description: help == null ? null : Text(help),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: children,
        ),
      ),
    );
  }
}
