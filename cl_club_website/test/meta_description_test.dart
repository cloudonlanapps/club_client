import 'package:cl_club_website/src/utils/meta_description.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Issue 29: a description is one plain line', () {
    expect(
      metaDescriptionFrom('Learn with **professional coaches**,\n  all year.'),
      'Learn with professional coaches, all year.',
    );
  });

  test('Issue 29: a long description is cut at a word', () {
    final description = metaDescriptionFrom(
      List.filled(60, 'skating').join(' '),
    )!;
    expect(description.length, lessThanOrEqualTo(metaDescriptionMaxLength));
    expect(description, endsWith('skating…'));
  });

  test('Issue 29: nothing to say is no description', () {
    expect(metaDescriptionFrom(null), isNull);
    expect(metaDescriptionFrom('  \n '), isNull);
  });
}
