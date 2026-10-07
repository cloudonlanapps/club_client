import 'package:cl_club_forms/src/constants/form_spacing.dart';
import 'package:cl_club_forms/src/widgets/form/form_body.dart';
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _nameId = 'name';
const _againId = 'again';
const _mismatch = 'The two names differ.';

/// A two-field form built only from the helpers.
class _ProbeForm extends StatefulWidget {
  const _ProbeForm({super.key});

  @override
  State<_ProbeForm> createState() => _ProbeFormState();
}

class _ProbeFormState extends State<_ProbeForm> with FormContract<_ProbeForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      values[_nameId] == values[_againId] ? null : _mismatch;

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    _nameId: (values[_nameId] as String).trim(),
  };

  @override
  Widget build(BuildContext context) => ShadForm(
    key: formKey,
    initialValue: const {_nameId: '', _againId: ''},
    child: FormBody(
      error: formError,
      children: [
        LabeledFormRow(
          label: 'Name',
          required: true,
          field: ShadInputFormField(
            id: _nameId,
            validator: (v) => v.trim().isEmpty ? 'Name is required' : null,
          ),
        ),
        LabeledFormRow(
          label: 'Again',
          field: ShadInputFormField(id: _againId),
        ),
      ],
    ),
  );
}

Future<GlobalKey<_ProbeFormState>> _pump(WidgetTester tester) async {
  final key = GlobalKey<_ProbeFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: _ProbeForm(key: key)),
    ),
  );
  return key;
}

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(ShadInputFormField).at(field), text);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 52: the form helpers', () {
    testWidgets('Issue 52: a required row marks its label', (tester) async {
      await _pump(tester);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Again'), findsOneWidget);
    });

    testWidgets('Issue 52: rows and labels take their gaps from FormSpacing', (
      tester,
    ) async {
      await _pump(tester);
      final body = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(FormBody),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(body.spacing, FormSpacing.rowGap);
      final row = tester.widget<Column>(
        find
            .descendant(
              of: find.byType(LabeledFormRow).first,
              matching: find.byType(Column),
            )
            .first,
      );
      expect(row.spacing, FormSpacing.labelGap);
    });
  });

  group('Issue 52: the form contract', () {
    testWidgets('Issue 52: validate refuses an invalid field, on the field', (
      tester,
    ) async {
      final key = await _pump(tester);
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text(_mismatch), findsNothing);
    });

    testWidgets('Issue 52: validate refuses a broken rule across fields, '
        'inline', (tester) async {
      final key = await _pump(tester);
      await _type(tester, 0, 'Asha');
      await _type(tester, 1, 'Ben');
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text(_mismatch), findsOneWidget);

      await _type(tester, 1, 'Asha');
      expect(key.currentState!.validate(), {_nameId: 'Asha'});
      await tester.pumpAndSettle();
      expect(find.text(_mismatch), findsNothing);
    });

    testWidgets('Issue 52: validate returns the assembled values', (
      tester,
    ) async {
      final key = await _pump(tester);
      await _type(tester, 0, ' Asha ');
      await _type(tester, 1, ' Asha ');
      expect(key.currentState!.validate(), {_nameId: 'Asha'});
    });

    testWidgets('Issue 52: isDirty follows the fields', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);
      await _type(tester, 0, 'Asha');
      expect(key.currentState!.isDirty, isTrue);
      await _type(tester, 0, '');
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 52: showErrors marks the field the server refused and '
        'shows the form-level message inline', (tester) async {
      final key = await _pump(tester);
      await _type(tester, 0, 'Asha');
      await _type(tester, 1, 'Asha');
      key.currentState!.showErrors(
        fieldErrors: const {_nameId: 'Name already taken.'},
        formError: 'Could not save.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Name already taken.'), findsOneWidget);
      expect(find.text('Could not save.'), findsOneWidget);

      key.currentState!.showErrors();
      await tester.pumpAndSettle();
      expect(find.text('Could not save.'), findsNothing);
    });
  });
}
