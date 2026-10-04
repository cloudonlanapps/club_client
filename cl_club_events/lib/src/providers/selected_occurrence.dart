import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/occurrence_key.dart';

/// Provider for the currently selected occurrence key.
final selectedOccurrenceProvider = StateProvider<OccurrenceKey?>((ref) => null);
