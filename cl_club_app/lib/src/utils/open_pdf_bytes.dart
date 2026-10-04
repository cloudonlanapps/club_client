/// Opens a PDF held in memory in the platform's viewer (club_core#174): an
/// evaluation's member-copy preview, which the server generates on request,
/// and its private PDFs — the stored member copy and evidence — which are
/// downloaded with the session since their URLs refuse an anonymous fetch.
library;

export 'open_pdf_bytes_io.dart'
    if (dart.library.js_interop) 'open_pdf_bytes_web.dart';
