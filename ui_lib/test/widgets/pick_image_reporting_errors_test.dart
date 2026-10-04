import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

const _pickedStub = PickedImage(
  bytes: [1, 2, 3],
  filename: 'photo.png',
  mimeType: 'image/png',
);

/// Pumps a button that runs [pickImageReportingErrors] with [picker] and
/// records the result, inside a ShadToaster-capable app.
Future<List<PickedImage?>> _pumpAndPick(
  WidgetTester tester, {
  required ConfirmImagePicker picker,
}) async {
  final results = <PickedImage?>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                results.add(
                  await pickImageReportingErrors(context, picker: picker),
                );
              },
              child: const Text('pick'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('pick'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets(
    'Issue 709: a throwing picker surfaces a toast (no silent failure)',
    (tester) async {
      final results = await _pumpAndPick(
        tester,
        picker: () async => throw Exception('dialog crashed'),
      );

      expect(find.textContaining("Couldn't open the image picker"), findsOne);
      expect(results, [null]);
    },
  );

  testWidgets(
    'Issue 709: a cancelled pick (null) stays silent',
    (tester) async {
      final results = await _pumpAndPick(tester, picker: () async => null);

      expect(
        find.textContaining("Couldn't open the image picker"),
        findsNothing,
      );
      expect(results, [null]);
    },
  );

  testWidgets(
    'Issue 709: a successful pick returns the image and shows no toast',
    (tester) async {
      final results = await _pumpAndPick(
        tester,
        picker: () async => _pickedStub,
      );

      expect(
        find.textContaining("Couldn't open the image picker"),
        findsNothing,
      );
      expect(results, [_pickedStub]);
    },
  );
}
