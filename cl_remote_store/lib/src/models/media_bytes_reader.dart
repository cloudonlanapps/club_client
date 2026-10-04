import 'dart:typed_data';

import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;

/// Downloads the original of [media] with the signed-in client and resolves
/// to its bytes; a refusal is thrown as the SDK raised it.
typedef MediaBytesReader = Future<Uint8List> Function(MediaRef media);
