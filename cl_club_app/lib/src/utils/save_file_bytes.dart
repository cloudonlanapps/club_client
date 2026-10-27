/// Saves a file held in memory where the person chooses (club_client#27:
/// an exported template): a download in the browser, a save dialog
/// elsewhere.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'save_file_bytes_io.dart'
    if (dart.library.js_interop) 'save_file_bytes_web.dart'
    as platform;

/// Saves [bytes] as a file named [fileName]; resolves to whether they were
/// saved.
typedef FileBytesSaver =
    Future<bool> Function(String fileName, Uint8List bytes);

/// What [saveFileBytes] hands a file to in place of the platform, when set:
/// the UI integration suite's stand-in, so a run on the desktop never opens
/// a save dialog and can check the bytes (club_client#400). Null in the
/// app, which then saves through the platform.
@visibleForTesting
FileBytesSaver? debugSaveFileBytes;

/// Asks where to save [bytes] as [fileName] and saves them there, or hands
/// them to [debugSaveFileBytes] while one is set.
Future<bool> saveFileBytes(String fileName, Uint8List bytes) =>
    (debugSaveFileBytes ?? platform.saveFileBytes)(fileName, bytes);
