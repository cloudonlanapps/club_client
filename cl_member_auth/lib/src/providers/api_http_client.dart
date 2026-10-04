import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// The HTTP client `clientProvider` talks to the API with.
///
/// `null` (the default) lets the SDK use its own client, which drops idle
/// connections before the server does (club_sdk 0.6.2). Tests override it
/// with a fake server; that client serves the token refresh too.
final apiHttpClientProvider = Provider<http.Client?>((ref) => null);
