import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to control contact FAB visibility.
///
/// Used by PublicShellScaffold to show/hide the FAB.
/// - Landing page sets to false (has its own animated FAB)
/// - Detail pages set to true via PublicPageShell
final contactFabVisibilityProvider = StateProvider<bool>((ref) => true);
