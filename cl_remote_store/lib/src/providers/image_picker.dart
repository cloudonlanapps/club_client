import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart'
    show IdentityDocumentsPicker, defaultIdentityDocumentsPicker;

/// The image picker every upload affordance (avatar, group hero, venue image,
/// event cover/gallery) uses to obtain a `PickedImage`.
///
/// Defaults to the native file dialog ([defaultIdentityDocumentsPicker]). It is
/// a provider so integration tests can override it with a stub that returns a
/// fixed in-memory image — driving the full upload path without opening a real
/// OS file dialog, which an integration test can't interact with.
final Provider<IdentityDocumentsPicker> imagePickerProvider =
    Provider<IdentityDocumentsPicker>((ref) => defaultIdentityDocumentsPicker);
