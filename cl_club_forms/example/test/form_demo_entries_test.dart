import 'dart:io';

import 'package:cl_club_forms_example/data/form_demo_entries.dart';
import 'package:cl_club_forms_example/models/form_demo_group.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `…Form` widgets the barrel of `cl_club_forms` exports, read from the
/// file: a name in a `show` list that ends in `Form`.
Set<String> exportedForms() {
  final barrel = File('../lib/cl_club_forms.dart').readAsStringSync();
  final names = <String>{};
  for (final export in RegExp(r'show\s+([^;]+);').allMatches(barrel)) {
    for (final name in export.group(1)!.split(',')) {
      if (name.trim().endsWith('Form')) names.add(name.trim());
    }
  }
  return names;
}

void main() {
  test('Issue 76: every form the barrel exports has an entry', () {
    final exported = exportedForms();
    // Guards the reading of the barrel: an empty set would pass anything.
    expect(exported.length, greaterThanOrEqualTo(32));
    expect(exported, contains('LoginForm'));

    final shown = {
      for (final entry in FormDemoEntries.all) entry.formType.toString(),
    };
    expect(
      exported.difference(shown),
      isEmpty,
      reason: 'forms of the barrel with no entry in example/lib/data/',
    );
    expect(
      shown.difference(exported),
      isEmpty,
      reason: 'entries for something the barrel does not export as a form',
    );
  });

  test('Issue 76: entries have distinct ids and titles', () {
    final all = FormDemoEntries.all;
    expect({for (final e in all) e.id}, hasLength(all.length));
    expect({for (final e in all) e.title}, hasLength(all.length));
  });

  test('Issue 76: every family of the sidebar has an entry', () {
    for (final group in FormDemoGroup.values) {
      expect(FormDemoEntries.of(group), isNotEmpty, reason: group.title);
    }
  });
}
