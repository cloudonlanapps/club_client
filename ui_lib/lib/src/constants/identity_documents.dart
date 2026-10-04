/// UI-layer constants for the identity-document submission flow.
///
/// These are product/UI decisions, not server/SDK contracts. They are
/// referenced by the form widget's default config and by the wiring layer
/// that drops the form into the auth shell.
library;

/// Maximum number of identity-document slots a user can fill.
const int kIdentityDocumentMaxCount = 2;

/// Credit-card aspect ratio (1.586:1, ISO/IEC 7810 ID-1) used for every
/// identity-document thumbnail. Shared by the submit form's upload tiles
/// and the admin review form's read-only thumbnails so the geometry stays
/// identical end-to-end.
const double kIdentityDocCardAspect = 1.586;

/// Allowed media types for identity-document uploads. Images only — PDFs are
/// not accepted; if a user has a PDF, they should screenshot the relevant
/// page(s) and upload those instead.
const Set<String> kIdentityDocumentAllowedMediaTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

/// Maximum allowed file size, in bytes, per identity-document slot (5 MiB).
const int kIdentityDocumentMaxBytes = 5 * 1024 * 1024;
