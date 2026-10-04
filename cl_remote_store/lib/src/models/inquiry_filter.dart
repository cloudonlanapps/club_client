import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry, InquiryKind;
import 'package:meta/meta.dart';

/// Which slice of the admin inquiry inbox to list (club_core#21).
///
/// Both fields are server-side filters; `null` means "any". The inbox opens
/// on [InquiryFilter.open] — every kind, not yet handled.
@immutable
class InquiryFilter {
  const InquiryFilter({this.kind, this.handled});

  /// The inbox's starting view: every kind, not yet handled.
  static const InquiryFilter open = InquiryFilter(handled: false);

  /// Only this kind; `null` for contact and interest alike.
  final InquiryKind? kind;

  /// Only handled (`true`) or open (`false`) rows; `null` for both.
  final bool? handled;

  /// Whether [inquiry] belongs in this slice.
  bool matches(Inquiry inquiry) =>
      (kind == null || inquiry.kind == kind) &&
      (handled == null || inquiry.isHandled == handled);

  InquiryFilter copyWith({
    InquiryKind? Function()? kind,
    bool? Function()? handled,
  }) {
    return InquiryFilter(
      kind: kind != null ? kind() : this.kind,
      handled: handled != null ? handled() : this.handled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InquiryFilter && other.kind == kind && other.handled == handled;

  @override
  int get hashCode => Object.hash(kind, handled);

  @override
  String toString() => 'InquiryFilter(kind: $kind, handled: $handled)';
}
