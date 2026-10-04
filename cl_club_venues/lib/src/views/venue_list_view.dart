import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, TitleRow, isMobileWidth;

import '../widgets/cards/venue_card.dart';

/// Venue list content view.
///
/// Does not include a Scaffold — the host provides the shell and routing.
/// Navigation is delegated via [onVenueTap] and [onCreateVenue] callbacks.
class VenueListView extends ConsumerStatefulWidget {
  const VenueListView({
    required this.onVenueTap,
    required this.onCreateVenue,
    this.onBack,
    super.key,
  });

  final void Function(Venue venue) onVenueTap;
  final VoidCallback onCreateVenue;
  final VoidCallback? onBack;

  @override
  ConsumerState<VenueListView> createState() => VenueListViewState();
}

class VenueListViewState extends ConsumerState<VenueListView> {
  final searchController = TextEditingController();
  Timer? debounceTimer;
  String searchTerm = '';

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

  List<Venue> applySearch(List<Venue> venues) {
    if (searchTerm.isEmpty) return venues;
    return venues.where((v) {
      return v.name.toLowerCase().contains(searchTerm) ||
          (v.address?.toLowerCase().contains(searchTerm) ?? false) ||
          (v.description?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = isMobileWidth(context);
    final venueList = ref.watch(
      clVenuesProvider((includeDeleted: false, searchTerm: null)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(title: 'Venues', onBack: widget.onBack),
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
                      placeholder: const Text('Search venues...'),
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: updateSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isMobile)
                    ActionIcon(
                      icon: Icons.add,
                      onPressed: widget.onCreateVenue,
                    )
                  else
                    ActionButton(
                      label: '+ New Venue',
                      onPressed: widget.onCreateVenue,
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: venueList.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Could not load venues: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (venues) {
              final filtered = applySearch(venues);

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No venues found.',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (searchTerm.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'Showing ${filtered.length} of ${venues.length}',
                        style: theme.textTheme.muted,
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          Future(() => ref.invalidate(clVenuesMasterProvider)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final venue = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: VenueCard(
                              key: ValueKey(venue.id),
                              venueId: venue.id,
                              onTap: () => widget.onVenueTap(venue),
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
