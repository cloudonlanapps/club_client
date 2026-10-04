import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to control navbar visibility.
/// Used by LandingPage to hide navbar in initial view.
final navbarVisibilityProvider = StateProvider<bool>((ref) => true);
