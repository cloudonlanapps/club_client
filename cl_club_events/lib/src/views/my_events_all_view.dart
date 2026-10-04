import 'dart:async';

import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../models/event_filter.dart';
import '../models/my_events_list_filter.dart';
import '../providers/my_events_list.dart';
import '../widgets/cards/event_card.dart';
import '../widgets/event_filter_popover.dart';

/// My Events list view showing the events for a single user.
///
/// Takes a [targetUsername] — the user whose events should be displayed,
/// which may differ from [currentUser] when an admin or coach is viewing
/// another user's list. The screen layer enforces who is allowed to view
/// this list.
///
/// Does not include a Scaffold — the host provides the shell and routing.
class MyEventsAllView extends ConsumerStatefulWidget {
  const MyEventsAllView({
    required this.currentUser,
    required this.targetUsername,
    this.onEventTap,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final String targetUsername;
  final void Function(int eventId)? onEventTap;
  final VoidCallback? onBack;

  @override
  ConsumerState<MyEventsAllView> createState() => MyEventsAllViewState();
}

class MyEventsAllViewState extends ConsumerState<MyEventsAllView> {
  final searchController = TextEditingController();
  Timer? debounceTimer;
  String searchTerm = '';
  EventFilter filter = const EventFilter();
  late Set<String> selectedUsernames = {widget.targetUsername};

  @override
  void didUpdateWidget(covariant MyEventsAllView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetUsername != widget.targetUsername) {
      selectedUsernames = {widget.targetUsername};
    }
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void updateSearch(String value) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() => searchTerm = value.trim().toLowerCase());
    });
  }

  MyEventsListFilter buildFilter() => MyEventsListFilter(
    selectedUsernames: selectedUsernames,
    searchTerm: searchTerm.isEmpty ? null : searchTerm,
    includePast: filter.includePast,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final listFilter = buildFilter();
    final eventList = ref.watch(myEventsListProvider(listFilter));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(title: 'My Events', onBack: widget.onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: searchController,
                  placeholder: const Text('Search events...'),
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: updateSearch,
                ),
              ),
              const SizedBox(width: 8),
              EventFilterPopover(
                initial: filter,
                onChanged: (next) => setState(() => filter = next),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: eventList.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Could not load events: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    'No events found.',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(myEventsListProvider(listFilter).notifier)
                    .refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index].event;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventCard(
                        key: ValueKey(event.id),
                        eventId: event.id,
                        username: widget.targetUsername,
                        onTap: widget.onEventTap == null
                            ? null
                            : () => widget.onEventTap!(event.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
