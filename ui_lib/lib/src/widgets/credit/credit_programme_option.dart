import 'package:flutter/foundation.dart';

/// A programme the grant form can bind credit to: form-local, so the form
/// never imports the SDK's `Event` (club_core#101).
@immutable
class CreditProgrammeOption {
  const CreditProgrammeOption({required this.id, required this.title});

  final int id;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditProgrammeOption && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}
