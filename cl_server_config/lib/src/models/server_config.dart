import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Configuration for connecting to the club API server.
///
/// The host app must override `serverConfigProvider` in its `ProviderScope`
/// with the API base URL:
///
/// ```dart
/// runApp(ProviderScope(
///   overrides: [
///     serverConfigProvider.overrideWithValue(
///       const ServerConfig(baseUrl: 'https://api.example.com/v1'),
///     ),
///   ],
///   child: const MyApp(),
/// ));
/// ```
@immutable
class ServerConfig {
  const ServerConfig({required this.baseUrl});

  factory ServerConfig.fromMap(Map<String, dynamic> map) {
    return ServerConfig(
      baseUrl: map['baseUrl'] as String? ?? '',
    );
  }

  factory ServerConfig.fromJson(String source) =>
      ServerConfig.fromMap(json.decode(source) as Map<String, dynamic>);

  /// API base URL **without** trailing slash, e.g.
  /// `https://api.example.org/v1`.
  final String baseUrl;

  ServerConfig copyWith({String? baseUrl}) {
    return ServerConfig(baseUrl: baseUrl ?? this.baseUrl);
  }

  Map<String, dynamic> toMap() {
    return {'baseUrl': baseUrl};
  }

  String toJson() => json.encode(toMap());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerConfig && other.baseUrl == baseUrl);

  @override
  int get hashCode => baseUrl.hashCode;

  @override
  String toString() => 'ServerConfig(baseUrl: $baseUrl)';
}
