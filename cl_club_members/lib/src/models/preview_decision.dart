/// What the user decided in the profile photo preview (`AvatarPreviewDialog`).
class PreviewDecision {
  const PreviewDecision({required this.allowOthersToSee});

  /// Whether the photo is to be visible to other members.
  final bool allowOthersToSee;
}
