import 'package:meta/meta.dart';

@immutable
class EventDetailFeeStructureLabels {
  const EventDetailFeeStructureLabels({
    required this.title,
    required this.feeTypeHeader,
    required this.periodHeader,
    required this.amountHeader,
    required this.totalLabel,
  });

  final String title;
  final String feeTypeHeader;
  final String periodHeader;
  final String amountHeader;
  final String totalLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailFeeStructureLabels &&
        other.title == title &&
        other.feeTypeHeader == feeTypeHeader &&
        other.periodHeader == periodHeader &&
        other.amountHeader == amountHeader &&
        other.totalLabel == totalLabel;
  }

  @override
  int get hashCode =>
      Object.hash(title, feeTypeHeader, periodHeader, amountHeader, totalLabel);
}
