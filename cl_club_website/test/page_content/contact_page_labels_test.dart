import 'package:cl_club_website/src/page_content/contact/contact_form_labels.dart';
import 'package:cl_club_website/src/page_content/contact/contact_page_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 166: the site owns its contact-page copy', () {
    test('Issue 166: ContactPageLabels round-trips through a map', () {
      final labels = ContactPageLabels.fromMap(const <String, dynamic>{
        'form': {'title': 'Write to us'},
        'info': <String, dynamic>{},
        'map': <String, dynamic>{},
      });

      final again = ContactPageLabels.fromMap(labels.toMap());

      expect(again, labels);
      expect(again.form.title, 'Write to us');
    });

    test('Issue 166: ContactFormLabels copyWith replaces only the given '
        'field', () {
      final form = ContactFormLabels.fromMap(const <String, dynamic>{
        'title': 'Write to us',
      });

      final changed = form.copyWith(title: 'Contact');

      expect(changed.title, 'Contact');
      expect(changed.description, form.description);
    });
  });
}
