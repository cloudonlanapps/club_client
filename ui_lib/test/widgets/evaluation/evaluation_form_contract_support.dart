// The forms and the pump shared by the Issue 92 tests of evaluation's four
// forms.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

const List<EvaluationStartChoice> contractTemplates = [
  (id: 1, label: 'Skating'),
];
const List<EvaluationStartMember> contractMembers = [
  (username: 'ana', label: 'Ana Rao'),
];
const List<EvaluationStartChoice> contractEvents = [
  (id: 9, label: 'Spring camp'),
];

Map<String, dynamic> contractTemplateValues({String name = 'Skating'}) => {
  EvaluationTemplateCreateFormFields.nameId: name,
  EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
};

Widget contractTemplateForm({
  Key? key,
  bool enabled = true,
  Map<String, dynamic>? initialValues,
}) => EvaluationTemplateCreateForm(
  key: key,
  enabled: enabled,
  initialValues: initialValues,
  onEditItem: (_) async => null,
  onEditSectionTitle: (_) async => null,
);

Widget contractStartForm({Key? key, bool enabled = true, bool fixed = false}) =>
    EvaluationStartForm(
      key: key,
      enabled: enabled,
      templates: contractTemplates,
      members: contractMembers,
      events: contractEvents,
      fixedTemplate: fixed ? contractTemplates.single : null,
      fixedMember: fixed ? contractMembers.single : null,
    );

Widget contractItemForm(
  EvaluationItemValue item, {
  Key? key,
  bool enabled = true,
  bool readOnly = false,
}) => EvaluationItemForm(
  key: key,
  kind: item.kind,
  enabled: enabled,
  readOnly: readOnly,
  initialValues: EvaluationItemFormValues.fromItem(item),
);

Future<void> pumpContractForm(WidgetTester tester, Widget form) async {
  await tallSurface(tester);
  // A new key each time: a form pumped after another of its type starts
  // afresh.
  await tester.pumpWidget(
    wrapEvaluation(KeyedSubtree(key: UniqueKey(), child: form)),
  );
  await tester.pumpAndSettle();
}
