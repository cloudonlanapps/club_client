import 'package:cl_remote_store/src/models/audit_log_scope.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rows fetched per page.
const int auditLogPageSize = 50;

/// Master provider for the audit log, family-keyed by [AuditLogScope].
///
/// Each scope (the global feed, or a single event / group / venue / user)
/// gets its own cached [AuditLogPage]. Manual-refresh model — no background
/// polling; the panel's Refresh button calls
/// [ClAuditLogMasterNotifier.refresh].
///
/// Role gating matches the server: the global feed loads only for a
/// super-admin; an entity scope loads only for an admin. Anyone else gets an
/// empty page without a server round-trip (the API would 403). SDK access
/// stays inside this module per the SDK-boundary rule.
final AsyncNotifierProviderFamily<
  ClAuditLogMasterNotifier,
  AuditLogPage,
  AuditLogScope
>
clAuditLogMasterProvider =
    AsyncNotifierProvider.family<
      ClAuditLogMasterNotifier,
      AuditLogPage,
      AuditLogScope
    >(
      ClAuditLogMasterNotifier.new,
    );

class ClAuditLogMasterNotifier
    extends FamilyAsyncNotifier<AuditLogPage, AuditLogScope> {
  int _offset = 0;

  @override
  Future<AuditLogPage> build(AuditLogScope scope) async {
    // Manual-refresh participation (top-bar refresh also bumps this).
    ref.watch(clManualRefreshProvider);

    final currentUser = ref.watch(currentUserProvider);
    if (!_allowed(currentUser, scope)) {
      return _empty;
    }

    final client = await ref.watch(secureClientProvider.future);
    return client.auditLog.list(
      offset: _offset,
      // Pin the page size here rather than leaning on the SDK default, so
      // changing it stays a one-line edit in this module.
      // ignore: avoid_redundant_argument_values
      limit: auditLogPageSize,
      username: scope.username,
      resourceType: scope.resourceType,
      resourceId: scope.resourceIdWire,
      verbose: scope.verbose,
    );
  }

  /// Re-fetch the current page (the Refresh button).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }

  /// Jump to a page boundary (Prev / Next). Clamps negatives to 0.
  Future<void> loadPage(int offset) async {
    _offset = offset < 0 ? 0 : offset;
    await refresh();
  }

  /// Advance one page if more rows exist.
  Future<void> nextPage() async {
    final page = state.valueOrNull;
    if (page == null || !page.hasMore) return;
    await loadPage(_offset + page.limit);
  }

  /// Go back one page if not already at the start.
  Future<void> previousPage() async {
    if (_offset == 0) return;
    final page = state.valueOrNull;
    await loadPage(_offset - (page?.limit ?? auditLogPageSize));
  }

  static bool _allowed(UserInfo? user, AuditLogScope scope) {
    if (user == null) return false;
    return scope.isGlobal ? user.isSuperAdmin : user.isAdmin;
  }

  AuditLogPage get _empty => const AuditLogPage(
    total: 0,
    offset: 0,
    limit: auditLogPageSize,
    rows: <AuditLogRow>[],
  );
}
