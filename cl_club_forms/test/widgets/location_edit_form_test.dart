import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets('respects initial values and returns them trimmed', (
    tester,
  ) async {
    final key = GlobalKey<LocationEditFormState>();
    await tester.pumpWidget(
      _wrap(
        LocationEditForm(
          key: key,
          initialAddress: '1 Rink Rd',
          initialMapUri: 'https://maps.example/x',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 Rink Rd'), findsOneWidget);

    final result = key.currentState!.validate();
    expect(result, isNotNull);
    expect(result!.address, '1 Rink Rd');
    expect(result.mapUri, 'https://maps.example/x');
  });

  testWidgets('returns empty strings when started blank', (tester) async {
    final key = GlobalKey<LocationEditFormState>();
    await tester.pumpWidget(
      _wrap(
        LocationEditForm(
          key: key,
          initialAddress: '',
          initialMapUri: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final result = key.currentState!.validate();
    expect(result, const LocationEditResult(address: '', mapUri: ''));
  });
}
