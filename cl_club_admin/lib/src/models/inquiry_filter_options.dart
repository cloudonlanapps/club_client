import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind;

/// What an admin reads for an [InquiryKind].
String inquiryKindLabel(InquiryKind kind) => switch (kind) {
  InquiryKind.contact => 'Contact',
  InquiryKind.interest => 'Interest',
};

/// The kind choices of the inbox filter.
enum InquiryKindOption {
  all('All kinds', null),
  contact('Contact', InquiryKind.contact),
  interest('Interest', InquiryKind.interest);

  const InquiryKindOption(this.label, this.kind);

  final String label;

  /// The server filter; `null` for every kind.
  final InquiryKind? kind;

  static InquiryKindOption of(InquiryKind? kind) =>
      values.firstWhere((o) => o.kind == kind);
}

/// The handled-state choices of the inbox filter.
enum InquiryStateOption {
  open('Open', handledFilter: false),
  handled('Handled', handledFilter: true),
  all('All', handledFilter: null);

  const InquiryStateOption(this.label, {required this.handledFilter});

  final String label;

  /// The server filter; `null` for both states.
  final bool? handledFilter;

  static InquiryStateOption of({required bool? handled}) =>
      values.firstWhere((o) => o.handledFilter == handled);
}
