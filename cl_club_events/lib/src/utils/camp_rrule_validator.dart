/// Validation result for a camp RRULE string.
///
/// `null` value means the RRULE satisfies the camp constraints
/// (`FREQ=DAILY` plus a bound — either `COUNT=N` or `UNTIL=...`).
/// A non-null result is a human-readable explanation that the form can
/// surface as a validator message before submission.
class CampRruleValidator {
  CampRruleValidator._();

  /// Validates an RRULE+EXDATE block for camp use.
  ///
  /// Inputs may contain an `EXDATE:...` line in addition to the RRULE
  /// proper (e.g. `'FREQ=DAILY;COUNT=5\nEXDATE:20260105T090000Z'`); only
  /// the RRULE line is checked. Returns `null` on success or an error
  /// message string on failure. Mirrors the server's
  /// `INVALID_RRULE_FOR_CAMP` rejection so the UI can surface the same
  /// failure mode before sending.
  static String? validate(String? rrule) {
    if (rrule == null || rrule.trim().isEmpty) {
      return 'A camp requires a recurrence rule.';
    }

    final rruleLine = rrule
        .split('\n')
        .map((line) => line.trim())
        .firstWhere(
          (line) => line.toUpperCase().startsWith('FREQ='),
          orElse: () => '',
        );
    if (rruleLine.isEmpty) {
      return 'Recurrence rule must start with FREQ=.';
    }

    final parts = rruleLine.split(';').map((p) => p.trim()).toList();
    final freq = _findValue(parts, 'FREQ');
    if (freq == null) {
      return 'Recurrence rule must specify FREQ.';
    }
    if (freq.toUpperCase() != 'DAILY') {
      return 'Camps must use FREQ=DAILY (got FREQ=$freq).';
    }

    final count = _findValue(parts, 'COUNT');
    final until = _findValue(parts, 'UNTIL');
    if (count == null && until == null) {
      return 'Camps must declare a bound: either COUNT=N or UNTIL=...';
    }
    if (count != null) {
      final n = int.tryParse(count);
      if (n == null || n < 1) {
        return 'COUNT must be a positive integer (got "$count").';
      }
    }

    return null;
  }

  static String? _findValue(List<String> parts, String key) {
    final upperKey = key.toUpperCase();
    for (final part in parts) {
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      if (part.substring(0, eq).toUpperCase() == upperKey) {
        return part.substring(eq + 1);
      }
    }
    return null;
  }
}
