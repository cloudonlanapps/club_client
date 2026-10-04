import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'client.dart';

/// What the server reports it can do (`GET /v1/capabilities`).
///
/// The server answers it before login too (club_server#443), so the signup
/// screens can read it. It is deploy configuration and does not change while
/// the app runs; it is re-read only when the client is rebuilt (login,
/// logout). A failed read is an error to retry, never a guess (#84).
final capabilitiesProvider = FutureProvider<Capabilities>((ref) async {
  final client = await ref.watch(secureClientProvider.future);
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
