import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart';

/// A [RemoteStore] that notices when the server refuses the session itself.
///
/// The SDK refreshes the token on a 401 only when a refresh could help. A
/// member who has left, been blocked or been deleted gets a 401 with
/// `ACCOUNT_LEFT`, `ACCOUNT_BLOCKED` or `USER_NOT_FOUND` on every call, and
/// no refresh is tried, so nothing would end the session (club_core#157).
/// This store calls [onSessionRefused] for each such answer and rethrows it
/// unchanged; the owner decides whether a session is live to end.
class SessionGuardStore extends RemoteStore {
  SessionGuardStore({
    required super.baseUrl,
    required this.onSessionRefused,
    super.client,
    super.onTokenExpired,
    super.onServerReachable,
    super.onServerUnreachable,
  });

  /// 401 codes that refuse the session outright: no refresh can fix them.
  static const Set<String> refusalCodes = {
    SdkErrorCode.accountLeft,
    SdkErrorCode.accountBlocked,
    SdkErrorCode.userNotFound,
  };

  /// HTTP status of a refused session.
  static const unauthorizedStatus = 401;

  /// Called when a request is refused with one of [refusalCodes].
  final void Function() onSessionRefused;

  /// Runs [request], reporting a refused session before rethrowing.
  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ServerException catch (e) {
      if (e.statusCode == unauthorizedStatus && refusalCodes.contains(e.code)) {
        onSessionRefused();
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) => guard(() => super.get(path, queryParams: queryParams));

  @override
  Future<Map<String, dynamic>?> getOrNull(
    String path, {
    Map<String, String>? queryParams,
  }) => guard(() => super.getOrNull(path, queryParams: queryParams));

  @override
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) => guard(() => super.getList(path, queryParams: queryParams));

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => guard(() => super.post(path, body: body));

  @override
  Future<void> postVoid(String path, {Map<String, dynamic>? body}) =>
      guard(() => super.postVoid(path, body: body));

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) => guard(() => super.patch(path, body: body));

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) => guard(() => super.put(path, body: body));

  @override
  Future<void> putVoid(String path, {Map<String, dynamic>? body}) =>
      guard(() => super.putVoid(path, body: body));

  @override
  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String? contentType,
    Map<String, String>? fields,
  }) => guard(
    () => super.uploadMultipart(
      path,
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
      fields: fields,
    ),
  );

  @override
  Future<List<int>> downloadBytes(
    String path, {
    Map<String, String>? queryParams,
  }) => guard(() => super.downloadBytes(path, queryParams: queryParams));

  @override
  Future<Map<String, String>> head(
    String path, {
    Map<String, String>? queryParams,
  }) => guard(() => super.head(path, queryParams: queryParams));

  @override
  Future<Map<String, dynamic>?> delete(String path) =>
      guard(() => super.delete(path));
}
