import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [GroupCreateView] for
/// `/memberzone/groups/new`.
class GroupCreateScreen extends StatelessWidget {
  const GroupCreateScreen({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return GroupCreateView(onCreated: onCreated, onCancel: onCancel);
  }
}
