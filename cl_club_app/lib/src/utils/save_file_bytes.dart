/// Saves a file held in memory where the person chooses (club_client#27:
/// an exported template): a download in the browser, a save dialog
/// elsewhere.
library;

export 'save_file_bytes_io.dart'
    if (dart.library.js_interop) 'save_file_bytes_web.dart';
