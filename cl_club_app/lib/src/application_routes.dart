import 'package:cl_club_applications/cl_club_applications.dart'
    show ProfileApplicationsSection, PublishedApplicationsList;
import 'package:cl_member_zone/cl_member_zone.dart'
    show ApplicationScreen, ApplicationsScreen, MyApplicationsScreen;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'utils/pdf_actions.dart';
import 'utils/router_helpers.dart';

/// The Applications routes under the member-zone shell (club_client#321,
/// #380): a member's own list, the admin's list of every template, and the
/// admin's editor of one. `mine` comes before `:id` so it never parses as
/// an id.
List<RouteBase> applicationRoutes() => [
  GoRoute(
    path: myApplicationsPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: MyApplicationsScreen(
        pdfAction: appPdfAction,
        onOpenProfile: () => context.push('/memberzone/profile'),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: applicationsPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: ApplicationsScreen(
        onOpen: (id) => context.push(applicationPath(id)),
        onHome: () => context.go('/'),
      ),
    ),
  ),
  GoRoute(
    path: '$applicationsPath/:id',
    pageBuilder: (context, state) {
      final id = intPathParam(state, 'id');
      if (id == null) return notFoundPage(context);
      return NoTransitionPage(
        child: ApplicationScreen(
          applicationId: id,
          onBack: () => popOrGo(context, applicationsPath),
          onDeleted: () => popOrGo(context, applicationsPath),
          pdfAction: appPdfAction,
          onHome: () => context.go('/'),
        ),
      );
    },
  ),
];

/// The profile's Applications section for [member], injected into the
/// profile views (club_client#321): [own] on one's own profile, where No to
/// "Is your profile complete?" only closes the question (club_client#340).
Widget profileApplicationsSection(UserPrivate member, {required bool own}) =>
    ProfileApplicationsSection(
      member: member,
      own: own,
      pdfAction: appPdfAction,
    );

/// The waiting page's list of the published applications for [user],
/// injected into onboarding (club_client#321). No to "Is your profile
/// complete?" calls [onOpenProfile] (club_client#340).
Widget waitingPageApplications(
  UserPrivate user, {
  required VoidCallback onOpenProfile,
}) => PublishedApplicationsList(
  currentUser: user,
  pdfAction: appPdfAction,
  onOpenProfile: onOpenProfile,
);
