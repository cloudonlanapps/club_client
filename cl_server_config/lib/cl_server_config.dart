/// Centralized server configuration, network status detection, and failure
/// widgets for the club app ecosystem.
///
/// The host app must override `serverConfigProvider` in its `ProviderScope`
/// with the API base URL.
library;

// Extensions
export 'src/extensions/date_time_format.dart' show DateTimeFormat;

// Models
export 'src/models/server_config.dart' show ServerConfig;

// Providers
export 'src/providers/config.dart'
    show apiBaseUrlProvider, serverConfigProvider;
export 'src/providers/network_status.dart'
    show NetworkStatus, NetworkStatusNotifier, networkStatusProvider;

// Widgets
export 'src/widgets/network_failure_screen.dart' show NetworkFailureScreen;
export 'src/widgets/network_status_wrapper.dart' show NetworkStatusWrapper;
