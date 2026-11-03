import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [username]'s full name from the users master, or the username while it
/// is not known.
String requestsDisplayName(WidgetRef ref, String username) {
  final user = ref.watch(clUsersMasterProvider).valueOrNull?[username];
  final name = user == null ? '' : '${user.firstName} ${user.lastName}'.trim();
  return name.isEmpty ? username : name;
}
