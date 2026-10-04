import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive expiry timestamp for the current auth session.
///
/// Set on login/restore and on token refresh. Cleared on logout.
/// Watched by the session countdown widget to display remaining time.
final tokenExpiryProvider = StateProvider<DateTime?>((ref) => null);
