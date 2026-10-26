import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_free_client.dart';

/// What the server reports it can do (`GET /v1/capabilities`).
///
/// The server answers it before login too (club_server#443), so the signup
/// screens can read it: it goes through [tokenFreeClientProvider], which
/// serves a signed-out member and the website alike (#31, club_client#272).
/// It is deploy configuration and does not change while the app runs; it is
/// re-read only when that client is rebuilt (login, logout). A failed read
/// is an error to retry, never a guess (#84).
final capabilitiesProvider = FutureProvider<Capabilities>((ref) async {
  final client = await ref.watch(tokenFreeClientProvider.future);
  return client.capabilities.getCapabilities();
});

/// Whether new members upload an identity document before review, or null
/// while [capabilitiesProvider] has no answer. Callers treat null as
/// unknown: neutral wording, and no route opened or closed on its account.
final identityVerificationProvider = Provider<bool?>(
  (ref) => ref.watch(capabilitiesProvider).valueOrNull?.identityVerification,
);

/// Whether this deployment runs the credit system, or null while
/// [capabilitiesProvider] has no answer (club_core#102).
///
/// Credit UI renders, and credit providers call the server, only when this
/// is `true`: the credit routes answer 503 where the module is off, and an
/// unknown answer is never guessed either way.
final creditSystemProvider = Provider<bool?>(
  (ref) => ref.watch(capabilitiesProvider).valueOrNull?.creditSystem,
);

/// Whether this deployment runs evaluations, or null while
/// [capabilitiesProvider] has no answer (club_core#173).
///
/// Evaluation UI renders, and evaluation providers call the server, only
/// when this is `true`: the evaluation routes answer 503 where the module is
/// off, and an unknown answer is never guessed either way.
final evaluationsProvider = Provider<bool?>(
  (ref) => ref.watch(capabilitiesProvider).valueOrNull?.evaluations,
);

/// Whether this deployment runs the Event Marketing module, or null while
/// [capabilitiesProvider] has no answer (club_client#1).
///
/// The extended marketing block is read and written, and its editor shown,
/// only when this is `true`: the module's routes answer 503 where it is
/// off, and an unknown answer is never guessed either way.
final eventMarketingProvider = Provider<bool?>(
  (ref) => ref.watch(capabilitiesProvider).valueOrNull?.eventMarketing,
);

/// Whether this deployment shows the extended profile — sports details,
/// background, guardian, membership date — and the club's profile options,
/// or null while [capabilitiesProvider] has no answer (club_client#320).
///
/// The fields are stored either way; their sections render only when this
/// is `true`, and an unknown answer is never guessed either way.
final extendedProfileProvider = Provider<bool?>(
  (ref) => ref.watch(capabilitiesProvider).valueOrNull?.extendedProfile,
);

/// The country calling code used when the server reports none (#31).
const String fallbackCountryCode = '91';

/// The club's country calling code, digits only (`91`), which completes a
/// phone number typed without one (#31).
///
/// It is the server's `default_country_code` deploy setting. A server that
/// reports none, and one that has not answered yet, both give
/// [fallbackCountryCode]: a caller that saves with it starts the read when
/// its form appears, not when it is submitted. It works on the website too
/// (see [capabilitiesProvider]).
final defaultCountryCodeProvider = Provider<String>(
  (ref) =>
      ref.watch(capabilitiesProvider).valueOrNull?.defaultCountryCode ??
      fallbackCountryCode,
);
