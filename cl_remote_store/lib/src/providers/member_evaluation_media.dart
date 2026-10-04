import 'package:cl_remote_store/src/models/evaluation_member_media.dart';
import 'package:cl_remote_store/src/models/member_evaluation_key.dart';
import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One published evaluation's media on its member's surface
/// (club_core#173): the stored member copy PDF and the evidence on its
/// public items.
///
/// Null, with no server call, unless [evaluationsProvider] is `true`.
/// Refetched when `evaluationsVersion` is bumped (a republish replaces the
/// member copy).
final AutoDisposeFutureProviderFamily<
  EvaluationMemberMedia?,
  MemberEvaluationKey
>
clMemberEvaluationMediaProvider = FutureProvider.autoDispose
    .family<EvaluationMemberMedia?, MemberEvaluationKey>((ref, key) async {
      ref
        ..watch(clManualRefreshProvider)
        ..watch(clResourceVersionProvider.select((s) => s.evaluationsVersion));
      if (ref.watch(evaluationsProvider) != true) return null;
      final client = await ref.watch(secureClientProvider.future);
      final grouped = await client.myEvaluations.listMyEvaluationMedia(
        key.username,
        key.evaluationId,
      );
      return EvaluationMemberMedia.fromGrouped(grouped);
    });
