/// Resolves a URL a build may override: a non-empty [override] (a
/// `--dart-define`) wins over the [configured] value from `club.json`, and
/// neither means none.
Uri? configuredUri({required String override, required String? configured}) {
  final url = override.isNotEmpty ? override : configured;
  return url == null ? null : Uri.parse(url);
}
