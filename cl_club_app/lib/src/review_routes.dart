import 'dart:async';

import 'package:cl_member_zone/cl_member_zone.dart'
    show
        MyReviewScreen,
        MyReviewsScreen,
        ReviewEditScreen,
        ReviewsScreen,
        TemplateCreateScreen,
        TemplateDetailScreen,
        TemplateLibraryScreen;
import 'package:go_router/go_router.dart';

import 'utils/open_pdf_bytes.dart';
import 'utils/router_helpers.dart';

/// The member's published reviews.
const String myReviewsPath = '/memberzone/reviews/mine';

/// The staff reviews page: the coach view or the template library.
const String reviewsPath = '/memberzone/reviews';

/// The evaluation template library, for coaches (and admins who coach).
const String templateLibraryPath = '$reviewsPath/templates';

/// The evaluation template designer.
const String templateCreatePath = '$templateLibraryPath/new';

/// Query parameter naming the template the designer starts from as a copy.
const String templateCopyParam = 'copy';

/// The designer pre-filled with a copy of template [id] (**Duplicate**).
String templateCopyPath(int id) => '$templateCreatePath?$templateCopyParam=$id';

/// The member-zone path of evaluation [id], in its owner's editor.
String reviewEditPath(int id) => '$reviewsPath/$id';

/// The member-zone path of evaluation template [id].
String templatePath(int id) => '$templateLibraryPath/$id';

/// The member-zone path of published review [id], read-only.
String myReviewPath(int id) => '$myReviewsPath/$id';

/// Query parameter naming the member whose review a coach reads.
const String reviewUsernameParam = 'username';

/// The review routes under the member-zone shell (club_core#174, design
/// 4.2). Literal segments come before `:id` so `mine` and `templates`
/// never parse as an id.
List<RouteBase> reviewRoutes() => [
  GoRoute(
    path: myReviewsPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: MyReviewsScreen(
        onOpen: (id) => context.push(myReviewPath(id)),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: '$myReviewsPath/:id',
    pageBuilder: (context, state) => NoTransitionPage(
      child: MyReviewScreen(
        evaluationId: int.parse(state.pathParameters['id']!),
        username: state.uri.queryParameters[reviewUsernameParam],
        onBack: () => popOrGo(context, myReviewsPath),
        onOpenPdfBytes: (bytes) => unawaited(openPdfBytes(bytes)),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: reviewsPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: ReviewsScreen(
        onOpenEvaluation: (id) => context.push(reviewEditPath(id)),
        onOpenTemplate: (id) => context.push(templatePath(id)),
        onCreateTemplate: () => context.push(templateCreatePath),
        onDuplicateTemplate: (id) => context.push(templateCopyPath(id)),
        onOpenTemplates: () => context.push(templateLibraryPath),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: templateLibraryPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: TemplateLibraryScreen(
        onOpenTemplate: (id) => context.push(templatePath(id)),
        onCreateTemplate: () => context.push(templateCreatePath),
        onDuplicateTemplate: (id) => context.push(templateCopyPath(id)),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: templateCreatePath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: TemplateCreateScreen(
        copyOfTemplateId: int.tryParse(
          state.uri.queryParameters[templateCopyParam] ?? '',
        ),
        onCreated: (id) => context.pushReplacement(templatePath(id)),
        onCancel: () => popOrGo(context, reviewsPath),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: '$templateLibraryPath/:id',
    pageBuilder: (context, state) => NoTransitionPage(
      child: TemplateDetailScreen(
        templateId: int.parse(state.pathParameters['id']!),
        onBack: () => popOrGo(context, reviewsPath),
        onDuplicate: (id) => context.push(templateCopyPath(id)),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: '$reviewsPath/:id',
    pageBuilder: (context, state) => NoTransitionPage(
      child: ReviewEditScreen(
        evaluationId: int.parse(state.pathParameters['id']!),
        onBack: () => popOrGo(context, reviewsPath),
        onDeleted: () => popOrGo(context, reviewsPath),
        onTransferred: () => popOrGo(context, reviewsPath),
        onOpenPdfBytes: (bytes) => unawaited(openPdfBytes(bytes)),
        onHome: () => context.go('/'),
      ),
    ),
  ),
];
