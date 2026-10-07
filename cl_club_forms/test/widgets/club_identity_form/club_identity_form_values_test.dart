// ClubIdentityFormValues: how the club identity section forms spread a
// host's values over their inputs and gather them back, and their one rule
// across fields.
import 'package:cl_club_forms/cl_club_forms.dart' show FormTranslatedText;
import 'package:cl_club_forms/src/widgets/club_identity_form/club_identity_form_values.dart';
import 'package:cl_club_forms/src/widgets/club_identity_form/translated_text_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

const _textIds = ['name'];
const _translatedIds = ['tagline', 'city'];
const _labels = {'name': 'Name', 'tagline': 'Tagline', 'city': 'City'};

String _t(String id, String language) =>
    TranslatedTextInputs.translationIdOf(id, language);

Map<String, dynamic> _spread(
  Map<String, dynamic> values, {
  List<String> languages = const ['mr', 'hi'],
}) => ClubIdentityFormValues.spread(
  values: values,
  textIds: _textIds,
  translatedIds: _translatedIds,
  languages: languages,
);

Map<String, dynamic> _gather(
  Map<String, dynamic> raw, {
  Map<String, dynamic> initialValues = const {},
  List<String> languages = const ['mr', 'hi'],
}) => ClubIdentityFormValues.gather(
  raw: raw,
  initialValues: initialValues,
  textIds: _textIds,
  translatedIds: _translatedIds,
  languages: languages,
);

String? _missing(Map<String, dynamic> gathered) =>
    ClubIdentityFormValues.missingDefaultError(
      gathered: gathered,
      translatedIds: _translatedIds,
      labels: _labels,
    );

void main() {
  group('Issue 61: ClubIdentityFormValues.translatedOf', () {
    test('Issue 61: it reads the stored value, and a missing one as '
        'empty', () {
      const stored = FormTranslatedText('Skate', {'mr': 'Namaskar'});
      expect(
        ClubIdentityFormValues.translatedOf(const {
          'tagline': stored,
        }, 'tagline'),
        stored,
      );
      expect(
        ClubIdentityFormValues.translatedOf(const {}, 'tagline'),
        const FormTranslatedText(''),
      );
      expect(
        ClubIdentityFormValues.translatedOf(const {}, 'tagline').isEmpty,
        isTrue,
      );
    });
  });

  group('Issue 61: ClubIdentityFormValues.spread', () {
    test('Issue 61: a translatable field becomes its default and one field '
        'per language, in the id@language form', () {
      expect(
        TranslatedTextInputs.translationIdOf('tagline', 'mr'),
        'tagline@mr',
      );
      expect(
        _spread(const {
          'name': 'Example Club',
          'tagline': FormTranslatedText('Skate', {
            'mr': 'Namaskar',
            'hi': 'Namaste',
          }),
          'city': FormTranslatedText('Example City'),
        }),
        {
          'name': 'Example Club',
          'tagline': 'Skate',
          'tagline@mr': 'Namaskar',
          'tagline@hi': 'Namaste',
          'city': 'Example City',
          'city@mr': '',
          'city@hi': '',
        },
      );
    });

    test('Issue 61: missing values spread as empty texts', () {
      expect(_spread(const {}, languages: const ['mr']), {
        'name': '',
        'tagline': '',
        'tagline@mr': '',
        'city': '',
        'city@mr': '',
      });
    });

    test('Issue 61: without languages only the defaults are spread, and a '
        'translation in a language not offered gets no field', () {
      expect(
        _spread(const {
          'tagline': FormTranslatedText('Skate', {'mr': 'Namaskar'}),
        }, languages: const []),
        {'name': '', 'tagline': 'Skate', 'city': ''},
      );
      expect(
        _spread(
          const {
            'tagline': FormTranslatedText('Skate', {'mr': 'Namaskar'}),
          },
          languages: const ['hi'],
        ).keys,
        isNot(contains('tagline@mr')),
      );
    });

    test('Issue 61: keys the form does not own are left out', () {
      expect(
        _spread(const {'postalCode': '000000'}).keys,
        isNot(contains('postalCode')),
      );
    });
  });

  group('Issue 61: ClubIdentityFormValues.gather', () {
    test('Issue 61: texts are trimmed and translations gathered back into '
        'one value per field', () {
      expect(
        _gather({
          'name': '  Example Club ',
          'tagline': ' Skate ',
          _t('tagline', 'mr'): ' Namaskar ',
          _t('tagline', 'hi'): 'Namaste',
          'city': 'Example City',
          _t('city', 'mr'): '',
          _t('city', 'hi'): '',
        }),
        {
          'name': 'Example Club',
          'tagline': const FormTranslatedText('Skate', {
            'mr': 'Namaskar',
            'hi': 'Namaste',
          }),
          'city': const FormTranslatedText('Example City'),
        },
      );
    });

    test('Issue 61: a translation left empty or blank is dropped', () {
      final gathered = _gather({
        'tagline': 'Skate',
        _t('tagline', 'mr'): '   ',
        _t('tagline', 'hi'): 'Namaste',
      });
      expect(
        gathered['tagline'],
        const FormTranslatedText('Skate', {'hi': 'Namaste'}),
      );
    });

    test('Issue 61: fields missing from the raw map gather as empty', () {
      expect(_gather(const {}), {
        'name': '',
        'tagline': const FormTranslatedText(''),
        'city': const FormTranslatedText(''),
      });
    });

    test('Issue 61: a stored translation in a language the form does not '
        'offer is kept as it was', () {
      final gathered = _gather(
        {'tagline': 'Skate', _t('tagline', 'hi'): 'Namaste'},
        initialValues: const {
          'tagline': FormTranslatedText('Skate', {
            'mr': 'Namaskar',
            'hi': 'Old',
          }),
        },
        languages: const ['hi'],
      );
      expect(
        gathered['tagline'],
        const FormTranslatedText('Skate', {'mr': 'Namaskar', 'hi': 'Namaste'}),
      );
    });

    test('Issue 61: a stored translation in an offered language is what '
        'its input holds, so emptying the input removes it', () {
      final gathered = _gather(
        {'tagline': 'Skate', _t('tagline', 'mr'): ''},
        initialValues: const {
          'tagline': FormTranslatedText('Skate', {'mr': 'Namaskar'}),
        },
        languages: const ['mr'],
      );
      expect(gathered['tagline'], const FormTranslatedText('Skate'));
    });

    test('Issue 61: spreading values and gathering them back returns '
        'them', () {
      const values = <String, dynamic>{
        'name': 'Example Club',
        'tagline': FormTranslatedText('Skate', {
          'mr': 'Namaskar',
          'hi': 'Namaste',
        }),
        'city': FormTranslatedText(''),
      };
      expect(_gather(_spread(values), initialValues: values), values);
    });
  });

  group('Issue 61: ClubIdentityFormValues.missingDefaultError', () {
    test('Issue 61: fields that are empty, or have their default, pass', () {
      expect(
        _missing(const {
          'tagline': FormTranslatedText('Skate', {'mr': 'Namaskar'}),
          'city': FormTranslatedText(''),
        }),
        isNull,
      );
      expect(_missing(const {}), isNull);
    });

    test('Issue 61: a field with a translation and no default is named by '
        'its label', () {
      expect(
        _missing(const {
          'tagline': FormTranslatedText('Skate'),
          'city': FormTranslatedText('', {'mr': 'Udaharan'}),
        }),
        'City has a translation but no default text.',
      );
    });

    test('Issue 61: translations in several languages without a default '
        'are refused just the same', () {
      expect(
        _missing(const {
          'tagline': FormTranslatedText('', {
            'mr': 'Namaskar',
            'hi': 'Namaste',
          }),
        }),
        'Tagline has a translation but no default text.',
      );
    });

    test('Issue 61: of several such fields the first in the order of the form '
        'is named', () {
      expect(
        _missing(const {
          'city': FormTranslatedText('', {'mr': 'Udaharan'}),
          'tagline': FormTranslatedText('', {'mr': 'Namaskar'}),
        }),
        'Tagline has a translation but no default text.',
      );
    });

    test('Issue 61: a default typed as spaces only gathers as no default', () {
      expect(
        _missing(_gather({'tagline': '   ', _t('tagline', 'mr'): 'Namaskar'})),
        'Tagline has a translation but no default text.',
      );
    });
  });

  group('Issue 61: FormTranslatedText', () {
    test('Issue 61: two values are equal when their default and their '
        'translations are, whatever the order of the languages', () {
      const a = FormTranslatedText('Skate', {
        'mr': 'Namaskar',
        'hi': 'Namaste',
      });
      const b = FormTranslatedText('Skate', {
        'hi': 'Namaste',
        'mr': 'Namaskar',
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const FormTranslatedText('Skate', {'mr': 'Namaskar'})));
      expect(
        a,
        isNot(
          const FormTranslatedText('Skate!', {
            'mr': 'Namaskar',
            'hi': 'Namaste',
          }),
        ),
      );
    });

    test('Issue 61: copyWith replaces what it is given and keeps the rest', () {
      const value = FormTranslatedText('Skate', {'mr': 'Namaskar'});
      expect(
        value.copyWith(defaultValue: 'Glide'),
        const FormTranslatedText('Glide', {'mr': 'Namaskar'}),
      );
      expect(
        value.copyWith(byLanguage: const {}),
        const FormTranslatedText('Skate'),
      );
    });

    test('Issue 61: trimmed leaves a blank default empty and keeps the '
        'translations in more than one language', () {
      expect(
        const FormTranslatedText('  ', {
          'mr': ' Namaskar',
          'hi': 'Namaste ',
        }).trimmed(),
        const FormTranslatedText('', {'mr': 'Namaskar', 'hi': 'Namaste'}),
      );
    });
  });
}
