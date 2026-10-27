import 'package:cl_club_applications/src/models/application_editor_options.dart';
import 'package:cl_club_applications/src/models/application_form_json.dart';
import 'package:cl_club_applications/src/utils/application_places.dart';
import 'package:cl_club_applications/src/utils/application_text_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';

void main() {
  test('Issue 321: a place reads the same from the client and the server', () {
    expect(ApplicationPlaces.label('form_footer'), 'Footer line');
    expect(ApplicationPlaces.label('formFooter'), 'Footer line');
    expect(ApplicationPlaces.label('terms[1].body'), 'Term 2 text');
    expect(ApplicationPlaces.label('terms[0].heading'), 'Term 1 heading');
    expect(ApplicationPlaces.label('terms_notes[0].text'), 'Note 1');
    expect(ApplicationPlaces.label('termsNotes[0].text'), 'Note 1');
    expect(ApplicationPlaces.label('selections[2]'), 'Selection 3');
    expect(
      ApplicationPlaces.label('labelOverrides.field.full_name'),
      'Label field.full_name',
    );
  });

  test('Issue 321: the reader reads a text in each language, and a fact '
      'as its value', () {
    final reader = ApplicationTextReader(
      template: ApplicationFormJson.fromContent(ApplicationSamples.content),
      options: ApplicationEditorOptions.from(
        ApplicationSamples.labels,
        ApplicationSamples.clauses,
      ),
    );
    expect(
      reader.read({'en': 'Camp', 'mr': 'शिबिर'}),
      'Camp / शिबिर',
    );
    expect(
      reader.read([
        {'en': 'Camp'},
        {'en': 'Rink'},
      ]),
      'Camp · Rink',
    );
    expect(reader.factValue('kinds', 'mr'), 'बर्फावर');
  });
}
