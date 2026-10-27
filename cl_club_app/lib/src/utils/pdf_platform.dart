/// The platform's ways of handing on a PDF held in memory
/// (club_client#324): whether the browser can share a file, the share
/// sheet, a download to the browser's folder, and the PDF viewer.
library;

export 'pdf_platform_io.dart'
    if (dart.library.js_interop) 'pdf_platform_web.dart';
