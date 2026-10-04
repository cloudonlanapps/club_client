import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

typedef _F = ClubIdentityForm;

Map<String, dynamic> _initial({
  Map<String, dynamic> overrides = const {},
}) => {
  ..._F.emptyValues,
  _F.nameId: 'Example Club',
  _F.phoneNumberId: '+10000000000',
  _F.taglineId: const FormTranslatedText('Skate with us', {'mr': 'Namaskar'}),
  ...overrides,
};

Future<GlobalKey<ClubIdentityFormState>> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  List<String> languages = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<ClubIdentityFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClubIdentityForm(
            key: key,
            initialValues: initialValues ?? _initial(),
            languages: languages,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Finder _input(String id) => find.byKey(ValueKey('clubIdentity.$id'));

Future<void> _enter(WidgetTester tester, String id, String text) async {
  await tester.enterText(
    find.descendant(of: _input(id), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
}

void main() {
  group('Issue 20: ClubIdentityForm', () {
    testWidgets('Issue 20: shows the stored values and returns them, '
        'translations included', (tester) async {
      final key = await _pump(tester);

      expect(find.text('Example Club'), findsOneWidget);
      expect(find.text('Skate with us'), findsOneWidget);
      expect(find.text('Namaskar'), findsOneWidget);

      final values = key.currentState!.validate()!;
      expect(values[_F.nameId], 'Example Club');
      expect(values[_F.phoneNumberId], '+10000000000');
      expect(values[_F.emailId], '');
      expect(
        values[_F.taglineId],
        const FormTranslatedText('Skate with us', {'mr': 'Namaskar'}),
      );
      expect(values[_F.cityId], const FormTranslatedText(''));
    });

    testWidgets('Issue 20: values come back trimmed, and an emptied '
        'translation is dropped', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, _F.shortNameId, '  EXC ');
      await _enter(tester, _F.translationId(_F.taglineId, 'mr'), '   ');

      final values = key.currentState!.validate()!;
      expect(values[_F.shortNameId], 'EXC');
      expect(values[_F.taglineId], const FormTranslatedText('Skate with us'));
    });

    testWidgets('Issue 20: a phone that is not E.164 is refused', (
      tester,
    ) async {
      final key = await _pump(tester);

      await _enter(tester, _F.phoneNumberId, '98765 43210');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('international format'), findsOneWidget);
    });

    testWidgets('Issue 20: a bad email or relative URL is refused', (
      tester,
    ) async {
      final key = await _pump(tester);

      await _enter(tester, _F.inquiryEmailId, 'desk-at-club');
      await _enter(tester, _F.instagramUrlId, 'instagram.com/club');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.textContaining('full link'), findsOneWidget);
    });

    testWidgets('Issue 20: a translation without a default text is refused '
        'with a form-level message', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, _F.taglineId, '');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(
        find.text('Tagline has a translation but no default text.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 20: the declared languages each get an input per '
        'translatable field', (tester) async {
      await _pump(
        tester,
        initialValues: {..._F.emptyValues},
        languages: const ['hi'],
      );

      for (final id in _F.translatedIds) {
        expect(_input(_F.translationId(id, 'hi')), findsOneWidget);
      }
    });

    testWidgets('Issue 20: adding a language code offers it on every '
        'translatable field', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, 'addLanguage', 'Marathi');
      await tester.tap(
        find.byKey(const ValueKey('clubIdentity.addLanguage.add')),
      );
      await tester.pump();
      expect(find.textContaining('two- or three-letter'), findsOneWidget);

      await _enter(tester, 'addLanguage', 'hi');
      await tester.tap(
        find.byKey(const ValueKey('clubIdentity.addLanguage.add')),
      );
      await tester.pumpAndSettle();

      expect(_input(_F.translationId(_F.cityId, 'hi')), findsOneWidget);
      await _enter(tester, _F.cityId, 'Pune');
      await _enter(tester, _F.translationId(_F.cityId, 'hi'), 'पुणे');

      final values = key.currentState!.validate()!;
      expect(
        values[_F.cityId],
        const FormTranslatedText('Pune', {'hi': 'पुणे'}),
      );
    });

    testWidgets('Issue 20: isDirty follows the edits', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await _enter(tester, _F.emailId, 'desk@club.example');
      expect(key.currentState!.isDirty, isTrue);

      await _enter(tester, _F.emailId, '');
      expect(key.currentState!.isDirty, isFalse);
    });
  });
}
