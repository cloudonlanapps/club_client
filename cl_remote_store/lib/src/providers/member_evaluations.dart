import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A member's published evaluations, most recently published first
/// (club_core#173), keyed by username.
///
/// The member surface: read by the member themselves and by any coach,
/// without private items. Empty, with no server call, unless
/// [evaluationsProvider] is `true`. Refetched when `evaluationsVersion` is
/// bumped by an evaluation write.
final AutoDisposeFutureProviderFamily<List<EvaluationMemberView>, String>
clMemberEvaluationsProvider = FutureProvider.autoDispose
    .family<List<EvaluationMemberView>, String>((ref, username) async {
      ref
        ..watch(clManualRefreshProvider)
        ..watch(clResourceVersionProvider.select((s) => s.evaluationsVersion));
      if (ref.watch(evaluationsProvider) != true) return const [];
      final client = await ref.watch(secureClientProvider.future);
      return fetchAllPages(
        ({required offset, required limit}) => client.myEvaluations
            .listMyEvaluations(username, offset: offset, limit: limit),
      );
    });
