import 'package:club_sdk_2/club_sdk_2.dart';

/// The item ids a refused save names, when [error] is the server's 422
/// `INCOMPLETE` (club_core#173); null for any other error.
///
/// `saveEvaluation` rethrows the SDK's [ServerException] unchanged; the ids
/// it carries are at `details['details']['itemIds']`: the required
/// questions left unanswered and the answers missing a required coach note.
List<int>? evaluationIncompleteItemIds(Object error) {
  if (error is! ServerException || error.code != SdkErrorCode.incomplete) {
    return null;
  }
  final inner = error.details?['details'];
  final ids = inner is Map ? inner['itemIds'] : null;
  if (ids is! List) return const [];
  return [for (final id in ids) (id as num).toInt()];
}
