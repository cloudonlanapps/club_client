import '../../models/marketing_list_column.dart';
import '../../models/marketing_list_column_kind.dart';

/// The columns of each list in an event's marketing, and the ids their
/// values are held under in a row.
abstract final class EventMarketingColumns {
  /// The text of a highlight or included item.
  static const String textId = 'text';

  /// A name (fee item, package, facility).
  static const String nameId = 'name';

  /// An amount in rupees (fee item) or a price (package).
  static const String amountId = 'amount';

  /// A fee's period (`per month`).
  static const String periodId = 'period';

  /// A title (offer).
  static const String titleId = 'title';

  /// A description (package, offer, facility).
  static const String descriptionId = 'description';

  /// A package's features, one per line.
  static const String featuresId = 'features';

  /// The last day an offer holds.
  static const String validUntilId = 'validUntil';

  /// A facility's icon name.
  static const String iconId = 'icon';

  /// A highlight or included item: one line of text.
  static const List<MarketingListColumn> bullets = [
    MarketingListColumn(id: textId, label: 'Text'),
  ];

  /// A fee item: name, amount and period.
  static const List<MarketingListColumn> feeItems = [
    MarketingListColumn(id: nameId, label: 'Name', flex: 2),
    MarketingListColumn(
      id: amountId,
      label: 'Amount',
      kind: MarketingListColumnKind.number,
    ),
    MarketingListColumn(
      id: periodId,
      label: 'Period',
      placeholder: 'per month',
    ),
  ];

  /// A package: name, price, description and features.
  static const List<MarketingListColumn> packages = [
    MarketingListColumn(id: nameId, label: 'Name'),
    MarketingListColumn(
      id: amountId,
      label: 'Price',
      kind: MarketingListColumnKind.number,
    ),
    MarketingListColumn(
      id: descriptionId,
      label: 'Description',
      kind: MarketingListColumnKind.multiline,
      flex: 2,
    ),
    MarketingListColumn(
      id: featuresId,
      label: 'Features',
      kind: MarketingListColumnKind.multiline,
      placeholder: 'One per line',
      flex: 2,
    ),
  ];

  /// An offer: title, description and the last day it holds.
  static const List<MarketingListColumn> offers = [
    MarketingListColumn(id: titleId, label: 'Title'),
    MarketingListColumn(
      id: descriptionId,
      label: 'Description',
      kind: MarketingListColumnKind.multiline,
      flex: 2,
    ),
    MarketingListColumn(
      id: validUntilId,
      label: 'Valid until',
      kind: MarketingListColumnKind.date,
      placeholder: 'No end',
    ),
  ];

  /// A facility: name, description and an icon among [iconNames].
  static List<MarketingListColumn> facilities(List<String> iconNames) => [
    const MarketingListColumn(id: nameId, label: 'Name'),
    const MarketingListColumn(
      id: descriptionId,
      label: 'Description',
      kind: MarketingListColumnKind.multiline,
      flex: 2,
    ),
    MarketingListColumn(
      id: iconId,
      label: 'Icon',
      kind: MarketingListColumnKind.choice,
      options: iconNames,
      placeholder: 'None',
    ),
  ];
}
