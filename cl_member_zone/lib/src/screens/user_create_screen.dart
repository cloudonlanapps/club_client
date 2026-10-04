import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [UserCreateView] for `/memberzone/users/new`.
class UserCreateScreen extends StatelessWidget {
  const UserCreateScreen({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return UserCreateView(onCreated: onCreated, onCancel: onCancel);
  }
}
