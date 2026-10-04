import 'package:cl_remote_store/src/models/evaluation_member_media.dart';
import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One evaluation's media as its effective owner sees it (club_core#173):
/// the evidence on every item, private ones included, by item id, and the
/// stored member copy once published. Keyed by evaluation id.
///
/// The owner's editor reads it to show each answer's evidence with its
/// kind (image, video or PDF), which the staff view's answers do not carry.
/// Null, with no server call, unless [evaluationsProvider] is `true`.
/// Refetched when `evaluationsVersion` is bumped (uploading or detaching
/// evidence, publishing).
final AutoDisposeFutureProviderFamily<EvaluationMemberMedia?, int>
clEvaluationMediaProvider = FutureProvider.autoDispose
    .family<EvaluationMemberMedia?, int>((ref, evaluationId) async {
      ref
        ..watch(clManualRefreshProvider)
        ..watch(clResourceVersionProvider.select((s) => s.evaluationsVersion));
      if (ref.watch(evaluationsProvider) != true) return null;
      final client = await ref.watch(secureClientProvider.future);
      final grouped = await client.evaluationMedia.listGrouped(evaluationId);
      return EvaluationMemberMedia.fromGrouped(grouped);
    });
