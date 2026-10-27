import 'dart:convert';

import 'package:cl_club_applications/src/models/application_template_file.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';

List<int> _bytes(Object? json) => utf8.encode(jsonEncode(json));

void main() {
  group('Issue 400: ApplicationTemplateFile', () {
    test('Issue 400: encode then decode round-trips the content', () {
      final template = ApplicationSamples.template(
        status: ApplicationStatus.published,
      );
      final text = ApplicationTemplateFile.encode(template);
      expect(
        ApplicationTemplateFile.decode(utf8.encode(text)),
        ApplicationSamples.content,
      );
    });

    test('Issue 400: the file carries its format, version and the content '
        'only', () {
      final json =
          jsonDecode(
                ApplicationTemplateFile.encode(
                  ApplicationSamples.template(
                    status: ApplicationStatus.saved,
                    layout: const ApplicationLayout(
                      name: 'one page',
                      spreadWithGuardian: 1,
                      spreadWithoutGuardian: 1,
                    ),
                  ),
                ),
              )
              as Map<String, dynamic>;
      expect(json.keys, unorderedEquals(['format', 'version', 'content']));
      expect(json['format'], 'club.application');
      expect(json['version'], 1);
      final content = json['content'] as Map<String, dynamic>;
      for (final key in ['id', 'status', 'layout', 'createdAt', 'updatedAt']) {
        expect(content.containsKey(key), isFalse, reason: key);
      }
    });

    test('Issue 400: a bare content object is read too', () {
      expect(
        ApplicationTemplateFile.decode(
          _bytes(ApplicationSamples.content.toMap()),
        ),
        ApplicationSamples.content,
      );
    });

    test('Issue 400: anything else is a FormatException', () {
      for (final (why, bytes) in [
        ('not JSON', utf8.encode('not json {')),
        ('not UTF-8', [0xff, 0xfe, 0xfd]),
        ('a list', _bytes([1, 2])),
        ('another JSON object', _bytes({'name': 'a review template'})),
        (
          'another format',
          _bytes({'format': 'club.review', 'content': <String, Object?>{}}),
        ),
        ('no content', _bytes({'format': 'club.application', 'version': 1})),
        (
          'unreadable content',
          _bytes({
            'format': 'club.application',
            'version': 1,
            'content': {'languages': 5},
          }),
        ),
      ]) {
        expect(
          () => ApplicationTemplateFile.decode(bytes),
          throwsFormatException,
          reason: why,
        );
      }
    });

    test('Issue 400: the file is named after the title', () {
      expect(ApplicationTemplateFile.fileName('Camp 2026'), 'Camp 2026.json');
      expect(ApplicationTemplateFile.fileName('a/b: c?'), 'a_b_ c_.json');
      expect(ApplicationTemplateFile.fileName('  '), 'application.json');
    });
  });
}
