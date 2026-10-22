import '../providers/network_status.dart';

/// The words the network failure banner and screen show for a
/// [NetworkStatus].
abstract final class NetworkFailureCopy {
  /// The label of the button that asks for a network check.
  static const String retryLabel = 'Try Again';

  /// The heading for [status].
  static String title(NetworkStatus status) => status == NetworkStatus.offline
      ? 'No Internet Connection'
      : 'Server Unavailable';

  /// The explanation for [status].
  static String message(NetworkStatus status) => status == NetworkStatus.offline
      ? 'Please check your internet connection and try again.'
      : 'Our servers are temporarily unavailable. '
            'Please try again in a moment.';
}
