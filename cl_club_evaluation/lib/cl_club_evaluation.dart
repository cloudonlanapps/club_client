/// Member evaluations (club_core#173): the member's reviews, the coach's
/// evaluations and their editor, the admin's template library and
/// designer, and the start-review dialog. Screens in `cl_member_zone` gate
/// and wrap these views; other packages open the start dialog.
library;

export 'src/views/coach_reviews_view.dart' show CoachReviewsView;
export 'src/views/evaluation_edit_view.dart' show EvaluationEditView;
export 'src/views/evaluation_read_view.dart' show EvaluationReadView;
export 'src/views/my_reviews_view.dart' show MyReviewsView;
export 'src/views/template_create_view.dart' show TemplateCreateView;
export 'src/views/template_detail_view.dart' show TemplateDetailView;
export 'src/views/template_library_view.dart' show TemplateLibraryView;
export 'src/widgets/start_review_dialog.dart' show showStartReviewDialog;
