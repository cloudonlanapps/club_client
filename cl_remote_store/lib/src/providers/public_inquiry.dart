import 'package:cl_remote_store/src/providers/public_source.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The public inquiry form's two calls (club_core#53): its fill-time token
/// and the submission. Holds no state; a form keeps its own.
final NotifierProvider<ClPublicInquiryNotifier, void> clPublicInquiryProvider =
    NotifierProvider<ClPublicInquiryNotifier, void>(
      ClPublicInquiryNotifier.new,
    );

class ClPublicInquiryNotifier extends Notifier<void> {
  @override
  void build() {}

  /// A fill-time token for one form.
  ///
  /// Fetch it when the form appears, not when it is submitted: the server
  /// drops a submission returned in under three seconds of its token.
  Future<String> formToken() =>
      ref.read(clPublicSourceProvider).getInquiryFormToken();

  /// Submit an inquiry with the [token] from [formToken].
  ///
  /// [website] is the honeypot a person cannot fill. The server answers 202
  /// whether it kept the submission or dropped it, so this returns normally
  /// in both cases; a refusal (`ServerException`, e.g. 429) or a transport
  /// failure is rethrown for the form to report.
  Future<void> submit({
    required InquiryKind kind,
    required String name,
    required String email,
    required String message,
    required String token,
    String? phone,
    Map<String, dynamic>? extra,
    String? website,
  }) {
    return ref
        .read(clPublicSourceProvider)
        .submitInquiry(
          kind: kind,
          name: name,
          email: email,
          message: message,
          token: token,
          phone: phone,
          extra: extra,
          website: website,
        );
  }
}
