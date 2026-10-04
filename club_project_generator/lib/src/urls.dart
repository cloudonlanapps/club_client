import 'target.dart';

/// Checks that [value] is a whole http(s) URL and returns it unchanged.
///
/// The host may be an IP or any domain, with or without a subdomain: nothing
/// here assumes a prefix such as `api.` or `member.`. Only the shape is
/// checked, never the name.
String checkUrl(String name, String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    throw GeneratorException(
      '$name must be a whole http:// or https:// URL, got "$value"',
    );
  }
  return value;
}
