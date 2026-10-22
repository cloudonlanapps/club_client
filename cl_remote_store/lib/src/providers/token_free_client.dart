import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/secure_client_not_provided.dart';
import 'client.dart';
import 'sessionless_client.dart';

/// The SDK client for the reads the server answers without a session:
/// `GET /capabilities`, which the signup screens need before anyone has
/// signed in (club_server#443).
///
/// By default it is [secureClientProvider]'s client or, when the host gave
/// none (the website, which holds no session), [clSessionlessClientProvider]
/// (club_core#31). A session client that fails is an error, never replaced
/// by the sessionless one.
///
/// The app overrides it with its own client, which serves a signed-out
/// member too: the app's [secureClientProvider] waits while no one is
/// signed in, so nothing that needs a session is sent then
/// (club_client#272).
final FutureProvider<SecureClient> tokenFreeClientProvider =
    FutureProvider<SecureClient>((ref) async {
      try {
        return await ref.watch(secureClientProvider.future);
      } on SecureClientNotProvided {
        return ref.watch(clSessionlessClientProvider.future);
      }
    });
