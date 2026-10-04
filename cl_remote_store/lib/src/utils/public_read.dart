import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/public_source.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs one public read for the provider owning [ref] (club_core#53).
///
/// The provider re-runs when the connection recovers and on a manual
/// refresh. A read that succeeds tells the network monitor the server is
/// online; one that fails asks it to check, and rethrows so the provider
/// shows the error.
Future<T> readPublic<T>(
  Ref ref,
  Future<T> Function(PublicSource source) read,
) async {
  ref
    ..watch(networkStatusProvider)
    ..watch(clManualRefreshProvider);
  final source = ref.watch(clPublicSourceProvider);
  // Captured before the await: the provider may be disposed by the time the
  // read settles, and its ref with it.
  final monitor = ref.read(networkStatusProvider.notifier);
  try {
    final value = await read(source);
    monitor.markOnline();
    return value;
  } on Object {
    monitor.checkNow();
    rethrow;
  }
}
