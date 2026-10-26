import 'dart:async';

import 'package:cl_club_applications/cl_club_applications.dart'
    show ProfileApplicationsSection, PublishedApplicationsList;
import 'package:cl_member_zone/cl_member_zone.dart'
    show ApplicationScreen, ApplicationsScreen;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'utils/open_pdf_bytes.dart';
import 'utils/router_helpers.dart';

/// The Applications routes under the member-zone shell (club_client#321):
/// the list for every member, and the admin's editor of one template.
List<RouteBase> applicationRoutes() => [
  GoRoute(
    path: applicationsPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: ApplicationsScreen(
        onOpen: (id) => context.push(applicationPath(id)),
        onOpenPdfBytes: (bytes) => unawaited(openPdfBytes(bytes)),
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
          onOpenPdfBytes: (bytes) => unawaited(openPdfBytes(bytes)),
          onHome: () => context.go('/'),
        ),
      );
    },
  ),
];

/// The profile's Applications section for [member], injected into the
/// profile views (club_client#321): [own] on one's own profile.
Widget profileApplicationsSection(UserPrivate member, {required bool own}) =>
    ProfileApplicationsSection(
      member: member,
      own: own,
      onOpenPdfBytes: (bytes) => unawaited(openPdfBytes(bytes)),
    );

/// The waiting page's list of the published applications for [user],
/// injected into onboarding (club_client#321).
Widget waitingPageApplications(UserPrivate user) => PublishedApplicationsList(
  currentUser: user,
  onOpenPdfBytes: (bytes) => unawaited(openPdfBytes(bytes)),
);
