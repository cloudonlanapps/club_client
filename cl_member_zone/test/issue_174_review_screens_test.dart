import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

class _Templates extends ClEvaluationTemplatesMasterNotifier {
  @override
  Future<Map<int, EvaluationTemplate>> build() async => const {};
}

class _Evaluations extends ClEvaluationsMasterNotifier {
  @override
  Future<Map<int, EvaluationStaffView>> build() async => const {};
}

UserPrivate _user({
  String username = 'member_a',
  bool admin = false,
  bool coach = false,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required UserPrivate viewer,
  bool? evaluations = true,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        evaluationsProvider.overrideWithValue(evaluations),
        clEvaluationTemplatesMasterProvider.overrideWith(_Templates.new),
        clEvaluationsMasterProvider.overrideWith(_Evaluations.new),
        clMemberEvaluationsProvider.overrideWith(
          (ref, username) async => const <EvaluationMemberView>[],
        ),
      ],
      child: ShadApp(home: ShadToaster(child: screen)),
    ),
  );
  // A spinner never settles.
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

const _denied = 'Access Denied';

void main() {
  group('Issue 174: ReviewsScreen picks the view by role', () {
    Widget screen() => ReviewsScreen(
      onOpenEvaluation: (_) {},
      onOpenTemplate: (_) {},
      onCreateTemplate: () {},
      onDuplicateTemplate: (_) {},
      onOpenTemplates: () {},
      onHome: () {},
    );

    testWidgets('Issue 174: a coach gets the coach view', (tester) async {
      await _pump(tester, screen(), viewer: _user(coach: true));
      expect(find.byType(CoachReviewsView), findsOneWidget);
      expect(find.byType(TemplateLibraryView), findsNothing);
    });

    testWidgets('Issue 174: an admin who coaches gets the coach view', (
      tester,
    ) async {
      await _pump(tester, screen(), viewer: _user(admin: true, coach: true));
      expect(find.byType(CoachReviewsView), findsOneWidget);
    });

    testWidgets('Issue 174: an admin who does not coach gets the templates', (
      tester,
    ) async {
      await _pump(tester, screen(), viewer: _user(admin: true));
      expect(find.byType(TemplateLibraryView), findsOneWidget);
      expect(find.byType(CoachReviewsView), findsNothing);
    });

    testWidgets('Issue 173: every coach is offered the template library on '
        'the coach view', (tester) async {
      var opened = 0;
      await _pump(
        tester,
        ReviewsScreen(
          onOpenEvaluation: (_) {},
          onOpenTemplate: (_) {},
          onCreateTemplate: () {},
          onDuplicateTemplate: (_) {},
          onOpenTemplates: () => opened++,
          onHome: () {},
        ),
        viewer: _user(coach: true),
      );
      final view = tester.widget<CoachReviewsView>(
        find.byType(CoachReviewsView),
      );
      view.onOpenTemplates();
      expect(opened, 1);
    });

    testWidgets('Issue 173: the admin library duplicates through the '
        'screen', (tester) async {
      final duplicated = <int>[];
      await _pump(
        tester,
        ReviewsScreen(
          onOpenEvaluation: (_) {},
          onOpenTemplate: (_) {},
          onCreateTemplate: () {},
          onDuplicateTemplate: duplicated.add,
          onOpenTemplates: () {},
          onHome: () {},
        ),
        viewer: _user(admin: true),
      );
      tester
          .widget<TemplateLibraryView>(find.byType(TemplateLibraryView))
          .onDuplicateTemplate(3);
      expect(duplicated, [3]);
    });

    testWidgets('Issue 174: a member is refused', (tester) async {
      await _pump(tester, screen(), viewer: _user());
      expect(find.text(_denied), findsOneWidget);
    });

    testWidgets('Issue 174: evaluations off refuses even a coach', (
      tester,
    ) async {
      await _pump(
        tester,
        screen(),
        viewer: _user(coach: true),
        evaluations: false,
      );
      expect(find.text(_denied), findsOneWidget);
      expect(find.byType(CoachReviewsView), findsNothing);
    });

    testWidgets('Issue 174: an unknown capability shows neither', (
      tester,
    ) async {
      await _pump(
        tester,
        screen(),
        viewer: _user(coach: true),
        evaluations: null,
        settle: false,
      );
      expect(find.text(_denied), findsNothing);
      expect(find.byType(CoachReviewsView), findsNothing);
    });
  });

  group('Issue 174: the member review screens', () {
    testWidgets('Issue 174: every member reaches their reviews', (
      tester,
    ) async {
      await _pump(
        tester,
        MyReviewsScreen(onOpen: (_) {}, onHome: () {}),
        viewer: _user(),
      );
      expect(find.byType(MyReviewsView), findsOneWidget);
    });

    testWidgets('Issue 174: my reviews are refused with evaluations off', (
      tester,
    ) async {
      await _pump(
        tester,
        MyReviewsScreen(onOpen: (_) {}, onHome: () {}),
        viewer: _user(),
        evaluations: false,
      );
      expect(find.text(_denied), findsOneWidget);
    });

    Widget review({String? username}) => MyReviewScreen(
      evaluationId: 7,
      username: username,
      onBack: () {},
      onOpenPdfBytes: (_) {},
      onHome: () {},
    );

    testWidgets('Issue 174: a member reads their own review', (tester) async {
      await _pump(tester, review(), viewer: _user());
      expect(find.byType(EvaluationReadView), findsOneWidget);
    });

    testWidgets("Issue 174: a coach reads a member's review", (tester) async {
      await _pump(
        tester,
        review(username: 'member_a'),
        viewer: _user(username: 'coach_a', coach: true),
      );
      expect(find.byType(EvaluationReadView), findsOneWidget);
    });

    testWidgets("Issue 174: a member may not read another's review", (
      tester,
    ) async {
      await _pump(
        tester,
        review(username: 'member_b'),
        viewer: _user(),
      );
      expect(find.text(_denied), findsOneWidget);
    });
  });

  group('Issue 174: the staff review screens', () {
    Widget create({int? copyOf}) => TemplateCreateScreen(
      copyOfTemplateId: copyOf,
      onCreated: (_) {},
      onCancel: () {},
      onHome: () {},
    );
    Widget detail() => TemplateDetailScreen(
      templateId: 3,
      onBack: () {},
      onDuplicate: (_) {},
      onHome: () {},
    );
    Widget edit() => ReviewEditScreen(
      evaluationId: 4,
      onBack: () {},
      onDeleted: () {},
      onTransferred: () {},
      onOpenPdfBytes: (_) {},
      onHome: () {},
    );

    testWidgets('Issue 174: an admin designs templates', (tester) async {
      await _pump(tester, create(), viewer: _user(admin: true));
      expect(find.byType(TemplateCreateView), findsOneWidget);
      await _pump(tester, detail(), viewer: _user(admin: true));
      expect(find.byType(TemplateDetailView), findsOneWidget);
    });

    testWidgets('Issue 173: a coach who is not admin designs templates too', (
      tester,
    ) async {
      await _pump(tester, create(copyOf: 3), viewer: _user(coach: true));
      final view = tester.widget<TemplateCreateView>(
        find.byType(TemplateCreateView),
      );
      expect(view.copyOfTemplateId, 3);
      await _pump(tester, detail(), viewer: _user(coach: true));
      expect(find.byType(TemplateDetailView), findsOneWidget);
    });

    testWidgets('Issue 173: a member may not design templates', (
      tester,
    ) async {
      await _pump(tester, create(), viewer: _user());
      expect(find.text(_denied), findsOneWidget);
      await _pump(tester, detail(), viewer: _user());
      expect(find.text(_denied), findsOneWidget);
    });

    Widget library() => TemplateLibraryScreen(
      onOpenTemplate: (_) {},
      onCreateTemplate: () {},
      onDuplicateTemplate: (_) {},
      onHome: () {},
    );

    testWidgets('Issue 174: an admin who coaches reaches the template '
        'library', (tester) async {
      await _pump(tester, library(), viewer: _user(admin: true, coach: true));
      expect(find.byType(TemplateLibraryView), findsOneWidget);
    });

    testWidgets('Issue 173: a coach who is not admin reaches the template '
        'library', (tester) async {
      await _pump(tester, library(), viewer: _user(coach: true));
      expect(find.byType(TemplateLibraryView), findsOneWidget);
    });

    testWidgets('Issue 173: a member may not reach the template library', (
      tester,
    ) async {
      await _pump(tester, library(), viewer: _user());
      expect(find.text(_denied), findsOneWidget);
      expect(find.byType(TemplateLibraryView), findsNothing);
    });

    testWidgets('Issue 174: a coach edits a review', (tester) async {
      await _pump(tester, edit(), viewer: _user(coach: true));
      expect(find.byType(EvaluationEditView), findsOneWidget);
    });

    testWidgets('Issue 174: an admin who does not coach may not', (
      tester,
    ) async {
      await _pump(tester, edit(), viewer: _user(admin: true));
      expect(find.text(_denied), findsOneWidget);
    });
  });
}
