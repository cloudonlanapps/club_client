// Issue 396: the club's labels are checked as Finalize checks them: a label
// lacking a print language is listed, unless the template overrides it.
import 'package:cl_club_applications/src/utils/application_label_gaps.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationFormFields, ApplicationLabelOption;
import 'package:flutter_test/flutter_test.dart';

const List<ApplicationLabelOption> _labels = [
  ApplicationLabelOption(
    id: 'field.full_name',
    text: {'en': 'Full name', 'mr': 'पूर्ण नाव'},
  ),
  ApplicationLabelOption(
    id: 'field.address',
    text: {'en': 'Address', 'mr': 'पत्ता', 'hi': ' '},
  ),
  ApplicationLabelOption(
    id: 'section.personal',
    text: {'en': 'Personal', 'mr': 'वैयक्तिक', 'hi': 'व्यक्तिगत'},
  ),
];

/// The gaps of [template], each as `key (name): languages`.
List<String> _gaps(Map<String, Object?> template) => [
  for (final gap in applicationLabelGaps(_labels, template))
    '${gap.key} (${gap.name}): ${gap.languages.join(', ')}',
];

void main() {
  group('Issue 396: applicationLabelGaps', () {
    test('Issue 396: each label lacking a print language, blank counted as '
        "lacking, in the labels' order", () {
      expect(
        _gaps({
          ApplicationFormFields.languagesId: ['en', 'mr', 'hi'],
        }),
        ['field.full_name (Full name): hi', 'field.address (Address): hi'],
      );
    });

    test('Issue 396: a label the template overrides is not listed', () {
      expect(
        _gaps({
          ApplicationFormFields.languagesId: ['en', 'hi'],
          ApplicationFormFields.labelOverridesId: {
            'field.full_name': {'en': 'Player', 'hi': 'खिलाड़ी'},
          },
        }),
        ['field.address (Address): hi'],
      );
    });

    test('Issue 396: a template printing in English alone lacks none', () {
      expect(_gaps(const {}), isEmpty);
    });
  });
}
