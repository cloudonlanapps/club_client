import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets(
    'Issue 311: didUpdateWidget defers onCanSubmitChanged so parent '
    'setState does not run during build',
    (tester) async {
      final formKey = GlobalKey<UserFormState>();
      var parentIsSubmitting = false;
      var notifyCount = 0;
      late StateSetter parentSetState;

      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                parentSetState = setState;
                return UserForm(
                  defaultCountryCode: '91',
                  key: formKey,
                  enabled: !parentIsSubmitting,
                  onCheckUsernameAvailable: (_) async => true,
                  onCanSubmitChanged: (_) {
                    notifyCount += 1;
                    // Mirror UserCreateView's wiring: setState on the
                    // parent inside the callback. Pre-fix this crashes
                    // because the callback fires from didUpdateWidget
                    // while the parent is still building.
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial post-frame notification from initState.
      expect(notifyCount, greaterThanOrEqualTo(1));
      final baselineNotifyCount = notifyCount;

      // Drive canSubmit to true by simulating a successful availability
      // check. This goes through the same code path the embedded
      // UsernameAvailabilityField uses.
      formKey.currentState!.onAvailabilityChanged('demo-user', 'demo-user');
      await tester.pumpAndSettle();
      expect(notifyCount, greaterThan(baselineNotifyCount));
      expect(tester.takeException(), isNull);

      // Now trigger a parent rebuild that turns the form off, as the host
      // does while it saves. The form rebuilds under the parent's build.
      parentIsSubmitting = true;
      parentSetState(() {});
      await tester.pumpAndSettle();

      // No "setState called during build" FlutterError may escape: the
      // form never calls the parent back from inside a build.
      expect(
        tester.takeException(),
        isNull,
        reason:
            'onCanSubmitChanged invoked from didUpdateWidget must be '
            'deferred so the parent callback can safely call setState.',
      );
    },
  );
}
