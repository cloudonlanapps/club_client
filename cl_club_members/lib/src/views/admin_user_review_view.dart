import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../utils/member_write_messages.dart';

/// Holds the current search query for the review pager.
///
/// Kept in Riverpod (not [State]) so typing into the search input does not
/// rebuild the parent view — only the inner [Consumer] that swaps the body
/// between pager and search results watches it. Auto-disposed so the query
/// resets when the page is closed.
final AutoDisposeStateProvider<String> reviewSearchQueryProvider =
    StateProvider.autoDispose<String>((_) => '');

/// Admin-only review surface for pending users.
///
/// Renders a [PageView] over all pending users so the admin can swipe
/// between them without bouncing back to the list. The route's optional
/// `?username=X` is used only as the initial page hint.
///
/// State isolation: each PageView child is wrapped in a [KeyedSubtree]
/// keyed by username so Flutter creates a fresh per-page [State] for each
/// user rather than recycling whichever [State] happens to occupy the
/// PageView slot. This is the fix for the per-page state bleed that
/// caused the original PageView (issue #385) to be reverted in #380.
class AdminUserReviewView extends ConsumerStatefulWidget {
  const AdminUserReviewView({
    required this.currentUser,
    required this.username,
    required this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final String username;
  final VoidCallback onBack;

  @override
  ConsumerState<AdminUserReviewView> createState() =>
      AdminUserReviewViewState();
}

class AdminUserReviewViewState extends ConsumerState<AdminUserReviewView> {
  PageController? _controller;
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  // Issue 507: on mobile the inline search input is collapsed to a trailing
  // search icon to give the documents grid more vertical room. Tapping the
  // icon expands the input and focuses it. Desktop always shows the input.
  bool _searchExpanded = false;

  // Only `pending` users belong in the review swipe — they are the ones
  // waiting on admin action. `registered` users (including those just sent
  // back via "Reject" → reconsiderUser) are waiting on the user, not the
  // admin, so they must exit the swipe immediately and the next pending
  // user must slide in. See issue #680.
  bool _isPending(UserInfo u) => u.status == UserStatus.pending;

  List<UserInfo> _pendingFrom(Map<String, UserInfo> users) {
    final list = users.values.where(_isPending).toList()
      ..sort((a, b) => a.username.compareTo(b.username));
    return list;
  }

  int _initialIndexFor(List<UserInfo> pending) {
    final i = pending.indexWhere((u) => u.username == widget.username);
    return i >= 0 ? i : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to review users.',
        onHome: widget.onBack,
      );
    }

    final usersAsync = ref.watch(clUsersMasterProvider);
    if (usersAsync.isLoading) {
      return const LoadingView(message: 'Loading users…');
    }
    if (usersAsync.hasError) {
      return ErrorView(
        title: 'Could not load users',
        subtitle: '${usersAsync.error}',
        onHome: widget.onBack,
      );
    }

    final pending = _pendingFrom(usersAsync.requireValue);
    if (pending.isEmpty) {
      return NotPendingState(onBack: widget.onBack);
    }

    if (_controller == null) {
      _currentIndex = _initialIndexFor(pending);
      _controller = PageController(initialPage: _currentIndex);
    } else if (_currentIndex >= pending.length) {
      // The list shrank past our cursor (e.g. last pending user acted on
      // while we were on the last page). Clamp to the new last index and
      // jump the controller after the frame so PageView and our index
      // stay in sync.
      _currentIndex = pending.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller!.hasClients) {
          _controller!.jumpToPage(_currentIndex);
        }
      });
    }

    final isMobile = isMobileWidth(context);
    // Issue 507: on mobile the title row and search input share a single
    // row of vertical real estate. Default state shows the title with a
    // trailing search icon; tapping the icon swaps the row for the
    // search input. Desktop keeps title and input on separate rows.
    final Widget topBar;
    if (!isMobile) {
      topBar = Column(
        children: [
          TitleRow(title: 'New Registrations', onBack: widget.onBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ShadInput(
              controller: _searchController,
              focusNode: _searchFocus,
              placeholder: const Text('Search users…'),
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) {
                ref.read(reviewSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ],
      );
    } else if (_searchExpanded) {
      topBar = MobileSearchBar(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (value) {
          ref.read(reviewSearchQueryProvider.notifier).state = value;
        },
        onClose: _clearSearch,
      );
    } else {
      // Mobile collapsed: reuse the shared TitleRow and just append a
      // trailing search icon on the same row so no extra vertical space
      // is consumed below the title.
      topBar = Row(
        children: [
          Expanded(
            child: TitleRow(
              title: 'New Registrations',
              onBack: widget.onBack,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.search, size: 20),
              tooltip: 'Search users',
              onPressed: _expandSearch,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        topBar,
        const Divider(height: 1),
        Expanded(
          // Body swaps between the pager and the search results based on
          // the query. The input above does not rebuild because nothing
          // here watches it directly — only this Consumer subtree does.
          child: Consumer(
            builder: (context, ref, _) {
              final query = ref.watch(reviewSearchQueryProvider).trim();
              // While the mobile search bar is expanded the body always
              // hosts the search-results surface (guidance / list / empty
              // state) so the underlying pager isn't visible behind the
              // keyboard — and so the admin sees real-time matches as
              // they type. Issue #507.
              if (query.isNotEmpty || _searchExpanded) {
                return SearchResultsBody(
                  query: query,
                  pending: pending,
                  onSelect: (username) {
                    _clearSearch();
                    // The PageView is unmounted while search results are
                    // showing, so its PageController is detached. Wait for
                    // the Consumer to rebuild the pager, then jump.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _jumpToUsername(username, pending);
                    });
                  },
                  onCancel: _clearSearch,
                );
              }
              return PagerBody(
                controller: _controller!,
                pending: pending,
                currentIndex: _currentIndex,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                onAfterAction: () => _onAfterAction(pending.length),
                onBack: widget.onBack,
                onPrevious: _currentIndex > 0 ? _goPrevious : null,
                onNext: _currentIndex < pending.length - 1 ? _goNext : null,
              );
            },
          ),
        ),
      ],
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(reviewSearchQueryProvider.notifier).state = '';
    _searchFocus.unfocus();
    if (_searchExpanded) {
      setState(() => _searchExpanded = false);
    }
  }

  void _expandSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _jumpToUsername(String username, List<UserInfo> pending) {
    final idx = pending.indexWhere((u) => u.username == username);
    if (idx < 0 || idx == _currentIndex) return;
    final c = _controller;
    if (c == null) return;
    c.animateToPage(
      idx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goPrevious() => _controller?.previousPage(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  void _goNext() => _controller?.nextPage(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  /// Called by a page after a successful Approve/Reject/Block. The acted
  /// user has just fallen off the pending list, so:
  /// - If the list was a single user, fire `widget.onBack`.
  /// - Otherwise stay put — the next pending user slides into this slot
  ///   naturally when the master notifier rebuilds.
  void _onAfterAction(int sizeBeforeMutation) {
    if (sizeBeforeMutation <= 1) {
      widget.onBack();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _controller?.dispose();
    super.dispose();
  }
}

class PagerBody extends StatelessWidget {
  const PagerBody({
    required this.controller,
    required this.pending,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onAfterAction,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final PageController controller;
  final List<UserInfo> pending;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAfterAction;
  final VoidCallback onBack;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: pending.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, i) {
              final username = pending[i].username;
              return KeyedSubtree(
                key: ValueKey('admin-review-$username'),
                child: AdminReviewPage(
                  username: username,
                  onBack: onBack,
                  onAfterAction: onAfterAction,
                ),
              );
            },
          ),
        ),
        PagerNav(
          currentIndex: currentIndex,
          total: pending.length,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      ],
    );
  }
}

class SearchResultsBody extends StatelessWidget {
  const SearchResultsBody({
    required this.query,
    required this.pending,
    required this.onSelect,
    required this.onCancel,
    super.key,
  });

  final String query;
  final List<UserInfo> pending;
  final void Function(String username) onSelect;
  final VoidCallback onCancel;

  List<UserInfo> _matches() {
    final q = query.toLowerCase();
    return pending
        .where(
          (u) =>
              u.username.toLowerCase().contains(q) ||
              u.displayName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasQuery = query.isNotEmpty;
    final matches = hasQuery ? _matches() : const <UserInfo>[];

    // Header band reflects three states:
    //  - empty query: nudge the admin to start typing
    //  - query + matches: count
    //  - query + no matches: "No matches…"
    final String headerText;
    if (!hasQuery) {
      headerText = 'Type to search by name or @handle';
    } else if (matches.isEmpty) {
      headerText = 'No matches for "$query"';
    } else {
      headerText = '${matches.length} match${matches.length == 1 ? '' : 'es'}';
    }

    // Body fills the remaining height so the surface stays put when the
    // keyboard slides up — no underlying pager peeks through. Issue #507.
    final Widget body;
    if (!hasQuery) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Start typing a name or @handle to find a pending user.',
            textAlign: TextAlign.center,
            style: theme.textTheme.muted,
          ),
        ),
      );
    } else if (matches.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No pending users match "$query".',
            textAlign: TextAlign.center,
            style: theme.textTheme.muted,
          ),
        ),
      );
    } else {
      body = ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, i) {
          final u = matches[i];
          return InkWell(
            onTap: () => onSelect(u.username),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.displayName,
                    style: theme.textTheme.p,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${u.username}',
                    style: theme.textTheme.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  headerText,
                  style: theme.textTheme.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ShadButton.ghost(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}

/// One page in the PageView — loads the per-user identity documents and
/// private profile, then renders [AdminUserReviewForm].
///
/// Stateful so `initState` can force a refetch of the per-user identity
/// documents on every mount (issue #684). Without this, the long-lived
/// `clIdentityDocsMasterProvider(username)` cache served stale images
/// to the admin after the user resubmitted, causing repeated false
/// rejections of legitimate uploads.
class AdminReviewPage extends ConsumerStatefulWidget {
  const AdminReviewPage({
    required this.username,
    required this.onBack,
    required this.onAfterAction,
    super.key,
  });

  final String username;
  final VoidCallback onBack;
  final VoidCallback onAfterAction;

  @override
  ConsumerState<AdminReviewPage> createState() => AdminReviewPageState();
}

class AdminReviewPageState extends ConsumerState<AdminReviewPage> {
  /// Runs an approve / send-back / block [decide]; on success calls
  /// [onDone], on failure shows a fixed toast (club_core#138).
  Future<void> runDecision(
    Future<void> Function() decide,
    VoidCallback onDone,
  ) async {
    try {
      await decide();
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.reviewDecisionFailed,
            ),
          ),
        ),
      );
      return;
    }
    onDone();
  }

  @override
  void initState() {
    super.initState();
    // Drop cached identity-document links so the admin sees the user's
    // latest gallery — not whatever was cached from a previous review
    // session before the user resubmitted. Issue #684.
    //
    // The KeyedSubtree(key: ValueKey('admin-review-$username')) wrapper
    // in PagerBody guarantees a fresh AdminReviewPage State per
    // username, so this invalidation fires on initial mount AND every
    // PageView swipe to a new user.
    //
    // Deferred via post-frame callback because `ref.invalidate` needs
    // the InheritedWidget container, which isn't wired during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(clIdentityDocsMasterProvider(widget.username));
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.username;
    final onBack = widget.onBack;
    final onAfterAction = widget.onAfterAction;
    final privateAsync = ref.watch(clUserPrivateProvider(username));
    final capsAsync = ref.watch(capabilitiesProvider);
    // Where the server does not verify identity there are no documents to
    // review, so none are fetched or shown (#84). Documents are fetched only
    // once the server has said it verifies identity.
    final showDocuments = capsAsync.valueOrNull?.identityVerification ?? false;
    final docsAsync = showDocuments
        ? ref.watch(clIdentityDocsMasterProvider(username))
        : const AsyncValue<List<MediaLink>>.data([]);
    final usersAsync = ref.watch(clUsersMasterProvider);

    if (privateAsync.isLoading ||
        capsAsync.isLoading ||
        docsAsync.isLoading ||
        usersAsync.isLoading) {
      return const LoadingView(message: 'Loading user…');
    }
    final error =
        privateAsync.error ??
        capsAsync.error ??
        docsAsync.error ??
        usersAsync.error;
    if (error != null) {
      return ErrorView(
        title: 'Could not load user',
        subtitle: '$error',
        onHome: onBack,
      );
    }

    final info = usersAsync.requireValue[username];
    if (info == null) {
      return NotPendingState(onBack: onBack);
    }

    final data = toFormData(
      info: info,
      private: privateAsync.requireValue,
      documents: [
        for (final link in docsAsync.requireValue)
          IdentityDocumentSlot(
            id: link.mediaUuid,
            uri: ref.read(
              mediaDownloadUrlProvider(
                (uuid: link.mediaUuid, variant: 'original'),
              ),
            ),
            mimeType: link.media.mimeType,
            fileName: link.media.filename,
            sizeBytes: 0,
          ),
      ],
    );

    return AdminUserReviewForm(
      data: data,
      httpHeaders: ref.watch(imageAuthHeadersProvider).value ?? const {},
      showDocuments: showDocuments,
      onApprove: (d, reason) async {
        await runDecision(
          () => ref
              .read(clUsersMasterProvider.notifier)
              .approveUser(d.userKey, resolutionReason: reason),
          onAfterAction,
        );
      },
      onReject: (d, reason) async {
        final trimmed = reason?.trim();
        final effective = (trimmed == null || trimmed.isEmpty)
            ? 'No Comment Provided'
            : trimmed;
        await runDecision(
          () => ref
              .read(clUsersMasterProvider.notifier)
              .reconsiderUser(d.userKey, effective),
          onAfterAction,
        );
      },
      onBlock: (d, reason) async {
        await runDecision(
          () => ref
              .read(clUsersMasterProvider.notifier)
              .blockUser(d.userKey, resolutionReason: reason),
          onAfterAction,
        );
      },
    );
  }
}

String genderLabel(Gender? gender) {
  switch (gender) {
    case Gender.male:
      return 'Boy';
    case Gender.female:
      return 'Girl';
    case Gender.other:
      return 'Other';
    case Gender.preferNotToSay:
    case null:
      return 'Unspecified';
  }
}

AdminUserReviewFormData toFormData({
  required UserInfo info,
  required UserPrivate private,
  required List<IdentityDocumentSlot> documents,
}) {
  return AdminUserReviewFormData(
    userKey: info.username,
    fullName: info.displayName,
    userName: info.username,
    dateOfBirth: private.dateOfBirthUtc ?? DateTime.utc(1900),
    gender: genderLabel(private.gender),
    documents: documents,
    adminReviewNote: private.adminReviewNote,
  );
}

class PagerNav extends StatelessWidget {
  const PagerNav({
    required this.currentIndex,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int currentIndex;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ShadButton.ghost(
            onPressed: onPrevious,
            leading: const Icon(Icons.chevron_left),
            child: const Text('Previous'),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${currentIndex + 1} / $total',
                style: theme.textTheme.muted,
              ),
            ),
          ),
          ShadButton.ghost(
            onPressed: onNext,
            trailing: const Icon(Icons.chevron_right),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class NotPendingState extends StatelessWidget {
  const NotPendingState({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 8),
            Text('Nothing to review', style: theme.textTheme.large),
            const SizedBox(height: 4),
            Text(
              'There are no pending users.',
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: 16),
            ShadButton.outline(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

/// Mobile-only search bar: replaces the title row entirely when the
/// admin taps the search icon. Closing it returns to the title row.
/// Issue #507.
class MobileSearchBar extends StatelessWidget {
  const MobileSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Close search',
            onPressed: onClose,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ShadInput(
              controller: controller,
              focusNode: focusNode,
              placeholder: const Text('Search users…'),
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
