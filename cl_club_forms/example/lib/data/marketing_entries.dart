import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';

/// The forms of an event's marketing page.
abstract final class MarketingEntries {
  /// The icons a facility may take in the demo.
  static const List<String> iconNames = ['wifi', 'local_parking', 'shower'];

  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'event-basic-marketing',
      title: 'Event basic marketing form',
      group: FormDemoGroup.marketing,
      formType: EventBasicMarketingForm,
      builder: (key) => EventBasicMarketingForm(
        key: key,
        initialValues: const {
          EventBasicMarketingFormFields.shortDescriptionId:
              'Five mornings on the ice for beginners.',
          EventBasicMarketingFormFields.stampId: 'New',
          EventBasicMarketingFormFields.highlightsId: [
            {EventMarketingColumns.textId: 'Skating basics'},
            {EventMarketingColumns.textId: 'Stick handling'},
          ],
          EventBasicMarketingFormFields.includesId: [
            {EventMarketingColumns.textId: 'Helmet on loan'},
          ],
        },
      ),
    ),
    FormDemoEntry(
      id: 'event-marketing-details',
      title: 'Event marketing details form',
      group: FormDemoGroup.marketing,
      formType: EventMarketingDetailsForm,
      builder: (key) => EventMarketingDetailsForm(
        key: key,
        initialValues: {
          EventMarketingDetailsFormFields.durationTextId: '5 days',
          EventMarketingDetailsFormFields.scheduleTextId: '6 to 8 am',
          EventMarketingDetailsFormFields.registrationDeadlineId: DateTime(
            2026,
            11,
            30,
          ),
          EventMarketingDetailsFormFields.openSlotsId:
              EventMarketingDetailsFormFields.openSlotsOpen,
        },
      ),
    ),
    FormDemoEntry(
      id: 'event-marketing-fees',
      title: 'Event marketing fees form',
      group: FormDemoGroup.marketing,
      formType: EventMarketingFeesForm,
      builder: (key) => EventMarketingFeesForm(
        key: key,
        initialValues: const {
          EventMarketingFeesFormFields.feeId: '4500',
          EventMarketingFeesFormFields.feeStructureId: [
            {
              EventMarketingColumns.nameId: 'Coaching',
              EventMarketingColumns.amountId: '4000',
              EventMarketingColumns.periodId: 'per camp',
            },
          ],
        },
      ),
    ),
    FormDemoEntry(
      id: 'event-marketing-rows',
      title: 'Event marketing rows form, facilities',
      group: FormDemoGroup.marketing,
      formType: EventMarketingRowsForm,
      builder: (key) => EventMarketingRowsForm(
        key: key,
        columns: EventMarketingColumns.facilities(iconNames),
        addLabel: 'Add facility',
        required: const {EventMarketingColumns.nameId},
        initialRows: const [
          {
            EventMarketingColumns.nameId: 'Parking',
            EventMarketingColumns.iconId: 'local_parking',
          },
        ],
      ),
    ),
    FormDemoEntry(
      id: 'event-marketing-membership',
      title: 'Event marketing membership form',
      group: FormDemoGroup.marketing,
      formType: EventMarketingMembershipForm,
      builder: (key) => EventMarketingMembershipForm(
        key: key,
        initialValues: const {
          EventMarketingMembershipFormFields.titleId: 'Club membership',
          EventMarketingMembershipFormFields.benefitsId: [
            {EventMarketingColumns.textId: 'Free ice time on Sundays'},
          ],
        },
      ),
    ),
  ];
}
