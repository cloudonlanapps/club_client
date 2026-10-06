import 'dart:async';

import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, TitleRow, isMobileWidth;

import '../models/event_filter.dart';
import '../models/event_list_filter.dart';
import '../providers/event_list.dart';
import '../widgets/cards/event_card.dart';
import '../widgets/event_filter_popover.dart';

/// Event list content view filtered by event type.
///
/// Does not include a Scaffold — the host provides the shell and routing.
/// Navigation is delegated via [onEventTap] and [onEnrollments] callbacks.
class EventListView extends ConsumerStatefulWidget {
  const EventListView({
    required this.eventType,
    required this.onEventTap,
    this.onEnrollments,
    this.onCreateNew,
    this.onBack,
    super.key,
  });

  final EventType eventType;
  final void Function(Event event) onEventTap;
  final void Function(Event event)? onEnrollments;

  /// Navigate to the create flow for this event type. The affordance is shown
  /// only to coaches/admins; the host controls where it goes, not whether it
  /// appears.
  final VoidCallback? onCreateNew;
  final VoidCallback? onBack;

  @override
  ConsumerState<EventListView> createState() => EventListViewState();
}

class EventListViewState extends ConsumerState<EventListView> {
  final searchController = TextEditingController();
  Timer? debounceTimer;
  String searchTerm = '';
  EventFilter filter = const EventFilter();

  String get typeLabel => switch (widget.eventType) {
    EventType.programme => 'Programs',
    EventType.camp => 'Camps',
    EventType.oneOff => 'One-Off Events',
  };

  String get createLabel => switch (widget.eventType) {
    EventType.programme => '+ New Program',
    EventType.camp => '+ New Camp',
    EventType.oneOff => '+ New Event',
  };

  String get searchPlaceholder => 'Search ${typeLabel.toLowerCase()}...';

  String get emptyMessage => switch (widget.eventType) {
    EventType.camp => 'Camps are yet to be announced.',
    EventType.programme => 'No programs found.',
    EventType.oneOff => 'No one-off events found.',
  };

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

  bool get hasActiveFilters =>
      searchTerm.isNotEmpty ||
      !filter.includePast ||
      filter.visibility != null ||
      filter.showArchived;

  EventListFilter buildFilter() => EventListFilter(
    eventType: widget.eventType,
    visibility: filter.visibility,
    includePast: filter.includePast,
    showArchived: filter.showArchived,
    searchTerm: searchTerm.isEmpty ? null : searchTerm,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = isMobileWidth(context);

    final listFilter = buildFilter();
    final eventList = ref.watch(eventListProvider(listFilter));
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final canCreate = viewer?.isCoachOrAdmin ?? false;
    final showCreate = canCreate && widget.onCreateNew != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(title: typeLabel, onBack: widget.onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: searchController,
                      placeholder: Text(searchPlaceholder),
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: updateSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  EventFilterPopover(
                    initial: filter,
                    filterByVisibility: true,
                    showArchivedToggle: viewer?.isAdmin ?? false,
                    onChanged: (next) => setState(() => filter = next),
                  ),
                  if (showCreate) ...[
                    const SizedBox(width: 8),
                    if (isMobile)
                      ActionIcon(
                        icon: Icons.add,
                        onPressed: widget.onCreateNew,
                      )
                    else
                      ActionButton(
                        label: createLabel,
                        onPressed: widget.onCreateNew,
                      ),
                  ],
                ],
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
                    emptyMessage,
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        '${events.length} match'
                        '${events.length == 1 ? '' : 'es'}',
                        style: theme.textTheme.muted,
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref
                          .read(eventListProvider(listFilter).notifier)
                          .refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: EventCard(
                              key: ValueKey(event.id),
                              eventId: event.id,
                              onTap: () => widget.onEventTap(event),
                              onEnrollments: widget.onEnrollments != null
                                  ? () => widget.onEnrollments!(event)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
