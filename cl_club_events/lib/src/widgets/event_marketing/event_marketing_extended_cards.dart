import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventMarketingColumns,
        EventMarketingDetailsForm,
        EventMarketingFeesForm,
        EventMarketingLimits,
        EventMarketingMembershipForm,
        EventMarketingRowsForm,
        MarketingListColumn;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventMarketingMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EventMarketing;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../../extensions/facility_icon.dart' show kFacilityIcons;
import '../../models/event_marketing_form_helpers.dart';
import '../../models/event_marketing_form_submit.dart';
import '../../models/event_marketing_sections.dart';
import '../../models/marketing_read_entries.dart';
import '../../models/marketing_read_entry.dart';
import '../../models/marketing_section.dart';
import 'event_marketing_section_card.dart';

/// The cards of an event's extended marketing block (club_client#1):
/// details, fees, packages, offers, club membership and facilities. Each
/// saves the whole block with its section replaced.
class EventMarketingExtendedCards extends ConsumerWidget {
  const EventMarketingExtendedCards({
    required this.eventId,
    required this.marketing,
    required this.onDraft,
    super.key,
  });

  /// Gap between two cards.
  static const double cardGap = 16;

  /// The event the block belongs to.
  final int eventId;

  /// The block, as stored.
  final EventMarketing marketing;

  /// Given a section and what is being typed in it, or null when its
  /// editor closes.
  final void Function(MarketingSection section, Map<String, dynamic>? values)
  onDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> save(
      Map<String, dynamic> values,
      EventMarketing Function(EventMarketing, Map<String, dynamic>) apply,
    ) => EventMarketingFormSubmit.updateSection(
      stored: marketing,
      values: values,
      apply: apply,
      notifier: ref.read(clEventMarketingMasterProvider(eventId).notifier),
    );

    EventMarketingSectionCard rows({
      required MarketingSection section,
      required String title,
      required IconData icon,
      required List<Map<String, Object?>> initialRows,
      required List<MarketingListColumn> columns,
      required Set<String> required,
      required String addLabel,
      required EventMarketing Function(EventMarketing, Map<String, dynamic>)
      apply,
      required List<MarketingReadEntry> entries,
    }) => EventMarketingSectionCard(
      title: title,
      icon: icon,
      savedMessage: '$title updated.',
      entries: entries,
      onDraft: (values) => onDraft(section, values),
      formBuilder: ({required key, required enabled, required onChanged}) =>
          EventMarketingRowsForm(
            key: key,
            columns: columns,
            addLabel: addLabel,
            initialRows: initialRows,
            required: required,
            maxLengths: const {
              EventMarketingColumns.nameId: EventMarketingLimits.name,
              EventMarketingColumns.titleId: EventMarketingLimits.name,
              EventMarketingColumns.descriptionId: EventMarketingLimits.text,
              EventMarketingColumns.iconId: EventMarketingLimits.iconName,
            },
            enabled: enabled,
            onChanged: onChanged,
          ),
      onSave: (values) => save(values, apply),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: cardGap,
      children: [
        EventMarketingSectionCard(
          title: 'Details',
          icon: LucideIcons.info,
          savedMessage: 'Details updated.',
          entries: MarketingReadEntries.details(marketing),
          onDraft: (values) => onDraft(MarketingSection.details, values),
          formBuilder: ({required key, required enabled, required onChanged}) =>
              EventMarketingDetailsForm(
                key: key,
                initialValues: buildEventMarketingDetailsFormInitialValues(
                  marketing,
                ),
                enabled: enabled,
                onChanged: onChanged,
              ),
          onSave: (values) => save(values, EventMarketingSections.withDetails),
        ),
        EventMarketingSectionCard(
          title: 'Fees',
          icon: LucideIcons.indianRupee,
          savedMessage: 'Fees updated.',
          entries: MarketingReadEntries.fees(marketing),
          onDraft: (values) => onDraft(MarketingSection.fees, values),
          formBuilder: ({required key, required enabled, required onChanged}) =>
              EventMarketingFeesForm(
                key: key,
                initialValues: buildEventMarketingFeesFormInitialValues(
                  marketing,
                ),
                enabled: enabled,
                onChanged: onChanged,
              ),
          onSave: (values) => save(values, EventMarketingSections.withFees),
        ),
        rows(
          section: MarketingSection.packages,
          title: 'Packages',
          icon: LucideIcons.package,
          initialRows: eventMarketingPackageRows(marketing),
          columns: EventMarketingColumns.packages,
          required: const {
            EventMarketingColumns.nameId,
            EventMarketingColumns.amountId,
          },
          addLabel: 'Add package',
          apply: EventMarketingSections.withPackages,
          entries: MarketingReadEntries.packages(marketing),
        ),
        rows(
          section: MarketingSection.offers,
          title: 'Offers',
          icon: LucideIcons.tag,
          initialRows: eventMarketingOfferRows(marketing),
          columns: EventMarketingColumns.offers,
          required: const {EventMarketingColumns.titleId},
          addLabel: 'Add offer',
          apply: EventMarketingSections.withOffers,
          entries: MarketingReadEntries.offers(marketing),
        ),
        EventMarketingSectionCard(
          title: 'Club membership',
          icon: LucideIcons.idCard,
          savedMessage: 'Club membership updated.',
          entries: MarketingReadEntries.membership(marketing),
          onDraft: (values) => onDraft(MarketingSection.membership, values),
          formBuilder: ({required key, required enabled, required onChanged}) =>
              EventMarketingMembershipForm(
                key: key,
                initialValues: buildEventMarketingMembershipFormInitialValues(
                  marketing,
                ),
                enabled: enabled,
                onChanged: onChanged,
              ),
          onSave: (values) =>
              save(values, EventMarketingSections.withMembership),
        ),
        rows(
          section: MarketingSection.facilities,
          title: 'Facilities',
          icon: LucideIcons.building,
          initialRows: eventMarketingFacilityRows(marketing),
          columns: EventMarketingColumns.facilities(
            kFacilityIcons.keys.toList(),
          ),
          required: const {EventMarketingColumns.nameId},
          addLabel: 'Add facility',
          apply: EventMarketingSections.withFacilities,
          entries: MarketingReadEntries.facilities(marketing),
        ),
      ],
    );
  }
}
