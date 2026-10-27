/// How a share sheet handed a PDF on (club_client#324).
enum ShareOutcome {
  /// The sheet took the file; whether the person then chose something is
  /// not always known.
  shared,

  /// The person closed the sheet without choosing anything.
  cancelled,

  /// The platform refused to show the sheet: in a browser, a tap that is
  /// no longer recent enough to count, or files it will not share.
  refused,
}

/// The PDF media type.
const String pdfMediaType = 'application/pdf';
