extension StringExtensions on String {
  /// "john doe" → "John Doe"
  String toTitleCase() {
    return trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// "John Doe" → "JD"
  String toInitials() {
    if (trim().isEmpty) return '';
    final words = trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return (words.first.substring(0, 1) + words.last.substring(0, 1))
        .toUpperCase();
  }

  /// Truncate to maxLength with "..."
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
