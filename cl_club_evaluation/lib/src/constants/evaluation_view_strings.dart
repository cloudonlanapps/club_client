/// Every user-facing string of the evaluation views, in evaluation terms
/// (a member reads "reviews"; staff read "evaluations" and "templates").
abstract final class EvaluationViewStrings {
  // Lists.

  /// A member with no published review.
  static const String noReviews = 'No reviews yet.';

  /// A coach with no live evaluation.
  static const String noEvaluations = 'No evaluations yet.';

  /// A library with no live template.
  static const String noTemplates = 'No templates yet.';

  /// The coach view's draft group.
  static const String drafts = 'Drafts';

  /// The coach view's group of finalized evaluations, awaiting publication.
  static const String finalized = 'Finalized';

  /// The coach view's published group.
  static const String published = 'Published';

  /// The coach view's evaluations heading.
  static const String myEvaluations = 'My evaluations';

  /// The template list's heading.
  static const String templates = 'Templates';

  /// The coach view's heading over the templates to start from.
  static const String startNew = 'New';

  /// Opens the template library, at the end of the coach view.
  static const String manageTemplates = 'Manage Templates';

  /// An evaluation about no one event.
  static const String general = 'General';

  /// Joins the facts of a row caption.
  static const String separator = ' · ';

  /// A template an evaluation uses, on its library row.
  static const String inUse = 'In use';

  /// A template's question count, e.g. "4 questions".
  static String questionCount(int n) => n == 1 ? '1 question' : '$n questions';

  /// When a review was published.
  static String publishedOn(String day) => 'Published $day';

  /// Who wrote a review.
  static String byCoach(String name) => 'by $name';

  /// The name a duplicated template starts with.
  static String copyName(String name) => '$name (copy)';

  // Statuses.

  /// `EvaluationStatus.draft`.
  static const String statusDraft = 'Draft';

  /// `EvaluationStatus.saved`: answered in full and awaiting publication.
  static const String statusFinalized = 'Finalized';

  /// `EvaluationStatus.published`.
  static const String statusPublished = 'Published';

  // Actions.

  /// Starts an evaluation from a template.
  static const String start = 'Start';

  /// Opens the template designer.
  static const String addTemplate = 'Add template';

  /// Creates the template.
  static const String create = 'Create';

  /// Leaves without saving.
  static const String cancel = 'Cancel';

  /// Saves a dialog's value.
  static const String save = 'Save';

  /// draft → saved: the draft autosaves, so this finalizes it.
  static const String finalize = 'Finalize';

  /// Closes a read-only dialog.
  static const String close = 'Close';

  /// saved → published.
  static const String publish = 'Publish';

  /// published → saved.
  static const String unpublish = 'Unpublish';

  /// saved → draft.
  static const String revert = 'Revert to draft';

  /// Hands the evaluation to another coach.
  static const String transfer = 'Transfer';

  /// Deletes a draft.
  static const String delete = 'Delete';

  /// Renames a template.
  static const String rename = 'Rename';

  /// Downloads the stored member copy.
  static const String downloadPdf = 'Download PDF';

  /// Opens the template designer pre-filled with a copy of a template.
  static const String duplicate = 'Duplicate';

  /// Attaches evidence to an answer.
  static const String attachEvidence = 'Attach evidence';

  /// Removes one evidence file.
  static const String removeEvidence = 'Remove evidence';

  /// Leaves a view.
  static const String back = 'Back';

  /// Adds an item from its dialog.
  static const String add = 'Add';

  /// Discards a dirty form.
  static const String discard = 'Discard';

  /// Keeps editing a dirty form.
  static const String keepEditing = 'Keep editing';

  // Titles and labels.

  /// The start dialog's title.
  static const String startReview = 'Start a review';

  /// The template designer's heading.
  static const String newTemplate = 'New template';

  /// The rename dialog's title.
  static const String renameTemplate = 'Rename template';

  /// The rename field's label.
  static const String templateName = 'Template name';

  /// The section title dialog's title and field.
  static const String sectionTitle = 'Section title';

  /// The layout card's title.
  static const String questions = 'Questions';

  /// The Review Period section's title, and its period row's label.
  static const String reviewPeriod = 'Review Period';

  /// No event and no review period, on a draft.
  static const String noPeriod = 'Tap to set the review period.';

  /// Joins the two ends of a period in the Review Period section.
  static const String periodTo = ' to ';

  /// The Review Management card's title.
  static const String reviewManagement = 'Review Management';

  /// The Review Info card's title.
  static const String reviewInfo = 'Review Info';

  /// Review Info: who created the evaluation.
  static const String createdBy = 'Created by';

  /// Review Info: the coach it was transferred to.
  static const String owner = 'Owner';

  /// Review Info: when it was created.
  static const String created = 'Created';

  /// Review Info: when it last changed.
  static const String updated = 'Updated';

  /// Review Info: when it was published.
  static const String publishedAt = 'Published';

  /// Review Info: its status.
  static const String status = 'Status';

  /// Review Info: its template.
  static const String template = 'Template';

  /// The stamp of a finalized evaluation.
  static const String stampReady = 'Ready';

  /// The stamp of a published evaluation.
  static const String stampPublished = 'Published';

  /// The existing-question picker's title.
  static const String existingQuestion = 'Existing question';

  /// The existing-question search field.
  static const String searchQuestions = 'Search questions';

  /// The existing-question type filter, unset.
  static const String anyType = 'Any type';

  /// No existing question matches.
  static const String noQuestionsFound = 'No questions match.';

  /// The transfer picker's title.
  static const String transferTo = 'Transfer to coach';

  /// No other coach to transfer to.
  static const String noCoaches = 'No other coach.';

  /// An event whose title is not loaded.
  static const String event = 'Event';

  // Confirmations.

  /// The discard prompt's title.
  static const String discardTitle = 'Discard this template?';

  /// The discard prompt's message.
  static const String discardMessage =
      'The name and questions you entered will be lost.';

  /// The delete prompt's title.
  static const String deleteTitle = 'Delete this draft?';

  /// The delete prompt's message.
  static const String deleteMessage =
      'The draft and its answers are removed. This cannot be undone here.';

  /// The prompt before leaving a changed item: its title.
  static const String discardItemTitle = 'Discard your changes?';

  /// The prompt before leaving a changed item: its message.
  static const String discardItemMessage =
      'The changes to this item will be lost.';

  /// The prompt before deleting an item: its title.
  static const String deleteItemTitle = 'Delete this item?';

  /// The prompt before deleting an item: its message.
  static const String deleteItemMessage = 'It is removed from the template.';

  /// The prompt before deleting a section: its title.
  static const String deleteSectionTitle = 'Delete this section?';

  /// The prompt before deleting a section: its message.
  static const String deleteSectionMessage =
      'Its items stay in the template, outside any section.';

  /// The prompt before clearing an answer that has evidence: its title.
  static const String clearAnswerTitle = 'Clear this answer?';

  /// The prompt before clearing an answer that has evidence: its message.
  static const String clearAnswerMessage =
      'Clearing this answer also removes its evidence.';

  /// Confirms clearing an answer.
  static const String clear = 'Clear';

  /// The template delete prompt's title.
  static const String deleteTemplateTitle = 'Delete this template?';

  /// The template delete prompt's message.
  static const String deleteTemplateMessage = 'It leaves the library.';

  /// The publish prompt's title.
  static const String publishTitle = 'Publish this evaluation?';

  /// The publish prompt's message.
  static const String publishMessage =
      'The member is notified and can read it, without private items.';

  // Notices and toasts.

  /// A frozen template's explanation.
  static const String templateFrozen =
      'This template is in use by an evaluation, so its questions and '
      'layout are fixed. Renaming still works.';

  /// A review that is not on the member surface.
  static const String reviewMissing = 'This review is not available.';

  /// An evaluation that is not the caller's.
  static const String evaluationMissing = 'This evaluation is not available.';

  /// A template that is not in the library.
  static const String templateMissing = 'This template is not available.';

  /// Something failed to load.
  static const String loadFailed = 'Could not load. Please try again.';

  /// A write failed with no more specific message.
  static const String saveFailed = 'Could not save. Please try again.';

  /// The template was created.
  static const String templateCreated = 'Template created.';

  /// The template was deleted.
  static const String templateDeleted = 'Template deleted.';

  /// The template was renamed.
  static const String templateRenamed = 'Template renamed.';

  /// The layout was changed.
  static const String questionsUpdated = 'Questions updated.';

  /// The review period was changed.
  static const String periodUpdated = 'Review period updated.';

  /// The answer could not be saved.
  static const String answerFailed = 'Could not save this answer.';

  /// The form has gaps before saving.
  static const String completeMarked = 'Complete the marked answers first.';

  /// The draft was finalized.
  static const String evaluationFinalized = 'Evaluation finalized.';

  /// The evaluation was published.
  static const String evaluationPublished = 'Evaluation published.';

  /// The evaluation was unpublished.
  static const String evaluationUnpublished = 'Evaluation unpublished.';

  /// The evaluation was reverted to a draft.
  static const String evaluationReverted = 'Evaluation is a draft again.';

  /// The evaluation was transferred.
  static const String evaluationTransferred = 'Evaluation transferred.';

  /// The draft was deleted.
  static const String evaluationDeleted = 'Draft deleted.';

  /// Evidence could not be attached.
  static const String evidenceFailed = 'Could not attach the evidence.';

  /// Evidence could not be removed.
  static const String evidenceRemoveFailed = 'Could not remove the evidence.';

  /// A stored PDF — the member copy or evidence — could not be downloaded.
  static const String pdfOpenFailed = 'Could not open the PDF.';

  // Server refusals, said for people.

  /// 422 `TEMPLATE_IN_USE`.
  static const String templateInUse =
      'This template is in use by an evaluation and cannot change.';

  /// 422 `NOT_ELIGIBLE`.
  static const String notEligible =
      'The member is not eligible for this event and period.';

  /// 422 `PERIOD_IN_FUTURE`.
  static const String periodInFuture =
      'The review period cannot end after today.';

  /// 404 `EVENT_NOT_FOUND`.
  static const String eventNotFound = 'That event no longer exists.';

  /// 422 `INVALID_STATE`.
  static const String invalidState =
      'Only a draft can change. Revert it to a draft first.';

  /// 422 `INCOMPLETE`.
  static const String incomplete = 'Some answers are incomplete.';

  /// 422 `INVALID_EVIDENCE`.
  static const String invalidEvidence =
      'Evidence is an image, a video or a PDF, on a question that allows it.';

  /// 422 `INVALID_ANSWER`.
  static const String invalidAnswer = 'That answer does not fit the question.';

  /// 422 `INVALID_LAYOUT`.
  static const String invalidLayout = 'The layout must place every question.';

  /// 422 `TEMPLATE_NAME_TAKEN`.
  static const String templateNameTaken =
      'A template with this name already exists.';

  /// 422 `DUPLICATE_EVALUATION`.
  static const String duplicateEvaluation =
      'A review of this member with this template and period already exists.';

  /// 422 `ITEM_TYPE_FIXED`.
  static const String itemTypeFixed = "A question's type cannot change.";
}
