// workflow_eval: the evaluation entry points, end to end (club_core#174,
// design 4.1–4.3).
//
// With evaluations on: an admin who does not coach designs a template from
// the Club Management *Reviews* entry and finds no *Add Review* on a
// member's profile; a coach opens the member's profile, starts a review with
// *Add Review*, answers it, saves and publishes it; the member finds it under
// their own *Reviews* and opens it, with its member copy offered as a PDF.
// With evaluations off, no *Reviews* entry appears and the route refuses.
//
// Fixtures (all `workflow_eval_` prefixed): a coach and a member, created
// with the admin SDK in setUpAll; the admin is the stack's sudo user (an
// admin who does not coach). Everything past setUpAll runs through the UI.
//
// Run (single file, fresh server):
//   just app-test-one app_test_server2.conf workflow_eval_evaluations_test.dart

import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '_helpers/auth.dart';
import '_helpers/capabilities.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kCoach = 'workflow_eval_coach';
const _kCoachPwd = 'WorkflowEvalCoachPwd!2024';
const _kMember = 'workflow_eval_member';
const _kMemberPwd = 'WorkflowEvalMemberPwd!2024';
const _kTemplate = 'workflow_eval_template';
const _kQuestion = 'Skates backwards in drills';

const _kReviews = 'Reviews';
const _kAddReview = 'Add Review';

late Capabilities _caps;

Future<SecureClient> _adminClient() async {
  final c = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
  await c.auth.login(_kSudoUsername, _kSudoPassword);
  return c;
}

/// Taps the sidebar entry [label]; the [last] one when two share it (the
/// Club Management *Reviews* follows the Main one). Invoked directly: the
/// entry can sit below the fold of the sidebar's scroll view.
Future<void> _sidebar(
  WidgetTester tester,
  String label, {
  bool last = false,
}) async {
  final labels = find.descendant(
    of: find.byType(SidebarItem),
    matching: find.text(label),
  );
  await waitFor(
    tester,
    () => labels.evaluate().isNotEmpty,
    description: 'sidebar entry "$label"',
  );
  final entry = find.ancestor(
    of: last ? labels.last : labels.first,
    matching: find.byType(SidebarItem),
  );
  tester.widget<SidebarItem>(entry.first).onTap();
  await settle(tester);
}

/// Opens [username]'s profile from the Members list, as staff do.
Future<void> _openProfile(WidgetTester tester, String username) async {
  await _sidebar(tester, 'Members');
  final card = find.byKey(ValueKey(username));
  await waitFor(
    tester,
    () => card.evaluate().isNotEmpty,
    description: 'user card "$username" in the members list',
  );
  await tester.tap(card);
  await settle(tester);
  await waitFor(
    tester,
    () => find.text('Personal details').evaluate().isNotEmpty,
    description: "$username's profile to render",
  );
}

/// Invokes the one [ShadButton] labelled [label] (the last when several).
Future<void> _press(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ShadButton, label);
  await waitFor(
    tester,
    () => button.evaluate().isNotEmpty,
    description: 'button "$label"',
  );
  invokeShadButton(tester, button.last, reason: label);
  await settle(tester);
}

/// Invokes the card / lifecycle action labelled [label].
Future<void> _action(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ActionButton, label);
  await waitFor(
    tester,
    () => button.evaluate().isNotEmpty,
    description: 'action "$label"',
  );
  final widget = tester.widget<ActionButton>(button.first);
  expect(widget.onPressed, isNotNull, reason: '"$label" should be enabled');
  widget.onPressed!.call();
  await settle(tester);
}

Future<void> _waitText(WidgetTester tester, String text) => waitFor(
  tester,
  // Questions render as markdown, so rich text counts too.
  () => find.text(text, findRichText: true).evaluate().isNotEmpty,
  description: '"$text" to show',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  setUpAll(() async {
    _caps = await stackCapabilities(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );
    final admin = await _adminClient();
    try {
      for (final (username, password, first) in [
        (_kCoach, _kCoachPwd, 'Evalcoach'),
        (_kMember, _kMemberPwd, 'Evalmember'),
      ]) {
        await admin.users.createUser(
          username: username,
          passwordHash: password,
          firstName: first,
          lastName: 'Workflow',
          phone: '7400500${username.length}1',
          email: '$username@example.com',
          gender: Gender.preferNotToSay,
          dateOfBirthUtc: DateTime.utc(1995, 1, 1),
        );
      }
      await admin.users.assignRole(_kCoach, 'coach');
    } finally {
      await admin.auth.logout();
    }
  });

  tearDownAll(() async {
    final admin = await _adminClient();
    try {
      if (_caps.evaluations) {
        // The coach's evaluation goes first: a template in use stays.
        final coach = await createRemoteSecureClient(baseUrl: _kApiBaseUrl);
        await coach.auth.login(_kCoach, _kCoachPwd);
        final mine = await coach.evaluations.listEvaluations();
        for (final e in mine.items) {
          if (e.createdFor != _kMember) continue;
          if (e.status == EvaluationStatus.published) {
            await coach.evaluations.unpublishEvaluation(e.id);
          }
          if (e.status != EvaluationStatus.draft) {
            await coach.evaluations.revertEvaluation(e.id);
          }
          await coach.evaluations.deleteEvaluation(e.id);
        }
        await coach.auth.logout();
        final templates = await admin.evaluations.listTemplates();
        for (final t in templates.items) {
          if (t.name == _kTemplate) {
            await admin.evaluations.deleteTemplate(t.id);
          }
        }
      }
      await admin.users.deleteUser(_kCoach);
      await admin.users.deleteUser(_kMember);
    } finally {
      await admin.auth.logout();
    }
  });

  testWidgets('a template, a review started from a profile, and the member '
      'reading it', (tester) async {
    if (skipUnless(enabled: _caps.evaluations, feature: 'evaluations')) {
      return;
    }
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);

    // 1. The admin, who does not coach, designs a template.
    await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
    await _sidebar(tester, _kReviews, last: true);
    await _press(tester, 'Add template');
    await waitFor(
      tester,
      () => find
          .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'name')
          .evaluate()
          .isNotEmpty,
      description: 'template designer',
    );
    await enterTextById(tester, 'name', _kTemplate);
    // The add bar is a "+" labelled only for semantics.
    final addBar = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Add an item',
      ),
      matching: find.byType(ShadButton),
    );
    invokeShadButton(tester, addBar.first, reason: 'Add an item');
    await settle(tester);
    await _press(tester, 'Yes / No');
    // The question is a textarea, not a ShadInputFormField.
    await tester.enterText(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ShadTextareaFormField && w.id == 'text',
        ),
        matching: find.byType(EditableText),
      ),
      _kQuestion,
    );
    await _press(tester, 'Add');
    expect(
      find.widgetWithText(ShadButton, 'Add'),
      findsNothing,
      reason: 'the item dialog should close once the question is valid',
    );
    await _waitText(tester, _kQuestion);
    await _press(tester, 'Create');
    await waitFor(
      tester,
      () =>
          find.text('New template').evaluate().isEmpty &&
          find.text(_kTemplate).evaluate().isNotEmpty,
      description: 'the created template to open',
    );

    // The admin has no Add Review on a member's profile.
    await _openProfile(tester, _kMember);
    expect(find.text(_kAddReview), findsNothing);
    await logout(tester);

    // 2. The coach starts a review from the member's profile.
    await loginViaUi(tester, _kCoach, _kCoachPwd);
    await _openProfile(tester, _kMember);
    await _press(tester, _kAddReview);
    await _waitText(tester, 'Start a review');
    await tester.tap(find.text('Choose a template'));
    await settle(tester);
    await tester.tap(find.text(_kTemplate).last);
    await settle(tester);
    await _press(tester, 'Start');

    // The new draft opens in the editor: answer, save, publish.
    await _waitText(tester, _kQuestion);
    await _press(tester, 'Yes');
    await _action(tester, 'Finalize');
    await waitFor(
      tester,
      () => find.widgetWithText(ActionButton, 'Publish').evaluate().isNotEmpty,
      description: 'the saved evaluation to offer Publish',
    );
    await _action(tester, 'Publish');
    await _press(tester, 'Publish'); // the confirmation
    await waitFor(
      tester,
      () =>
          find.widgetWithText(ActionButton, 'Unpublish').evaluate().isNotEmpty,
      description: 'the evaluation to be published',
    );
    await logout(tester);

    // 3. The member reads it under Reviews, with its PDF offered.
    await loginViaUi(tester, _kMember, _kMemberPwd);
    final entries = find.descendant(
      of: find.byType(SidebarItem),
      matching: find.text(_kReviews),
    );
    expect(entries, findsOneWidget, reason: 'a member has one Reviews entry');
    await _sidebar(tester, _kReviews);
    await _waitText(tester, _kTemplate);
    await tester.tap(find.text(_kTemplate).first);
    await settle(tester);
    await _waitText(tester, _kQuestion);
    await waitFor(
      tester,
      () => find.byIcon(LucideIcons.download).evaluate().isNotEmpty,
      description: 'the member copy to be offered',
    );
    await logout(tester);
  });

  testWidgets('with evaluations off there is no Reviews entry or route', (
    tester,
  ) async {
    if (skipIf(enabled: _caps.evaluations, feature: 'evaluations')) return;
    await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
    await ensureLoggedOut(tester);

    await loginViaUi(tester, _kCoach, _kCoachPwd);
    await _sidebar(tester, 'Members');
    expect(
      find.descendant(
        of: find.byType(SidebarItem),
        matching: find.text(_kReviews),
      ),
      findsNothing,
    );
    await _openProfile(tester, _kMember);
    expect(find.text(_kAddReview), findsNothing);

    // The route itself refuses.
    await go(tester, '/memberzone/reviews');
    await _waitText(tester, 'Access Denied');
    await logout(tester);
  });
}
