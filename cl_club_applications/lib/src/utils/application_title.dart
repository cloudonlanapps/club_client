import 'package:cl_club_forms/cl_club_forms.dart' show ApplicationFormFields;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationStatus, ApplicationTemplate;

import '../constants/application_view_strings.dart';

/// [template]'s title in English, as its lists show it.
String applicationTitle(ApplicationTemplate template) {
  final title =
      template.content.title?.texts?[ApplicationFormFields.english]?.trim() ??
      '';
  return title.isEmpty ? ApplicationViewStrings.untitled : title;
}

/// The published templates of [templates], by title.
List<ApplicationTemplate> publishedApplications(
  Iterable<ApplicationTemplate> templates,
) =>
    templates.where((t) => t.status == ApplicationStatus.published).toList()
      ..sort((a, b) => applicationTitle(a).compareTo(applicationTitle(b)));
