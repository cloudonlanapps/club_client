/// What `secureClientProvider` throws when the host has not overridden it.
///
/// A club app always overrides it; the website, which holds no session,
/// does not. A provider that also serves the website catches this to tell
/// the two hosts apart (`capabilitiesProvider`); everywhere else it is the
/// host's wiring mistake and is left to surface.
class SecureClientNotProvided implements Exception {
  /// Creates the exception.
  const SecureClientNotProvided();

  @override
  String toString() =>
      'secureClientProvider must be overridden in ProviderScope. '
      'See its doc comment for an example.';
}
