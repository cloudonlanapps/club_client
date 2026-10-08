// A profile photo for integration tests.
//
// Owns:
//   * pixelPng   — the bytes of a small valid PNG.
//   * stubPicker — an `imagePickerProvider` value that picks it: the picker
//     cannot open a native file dialog under test.

import 'dart:convert' show base64Decode;

import 'package:ui_lib/ui_lib.dart' show PickedImage;

/// A tiny VALID 8x8 PNG (the one workflow_imgupload uses): the server
/// converts it to webp, which rejects malformed input.
final List<int> pixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAAIGNIUk0AAHomAACAhAAA+gAA'
  'AIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGUExURSJmqv///9sZQGwAAAABYktHRAH/Ai3e'
  'AAAAB3RJTUUH6gUfDggupQDwMAAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNi0wNS0zMVQxNDow'
  'ODo0NiswMDowMBTuiwkAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjYtMDUtMzFUMTQ6MDg6NDYr'
  'MDA6MDBlszO1AAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI2LTA1LTMxVDE0OjA4OjQ2KzAw'
  'OjAwMqYSagAAAAtJREFUCNdjYEAFAAAQAAGhxSHBAAAAAElFTkSuQmCC',
);

/// A picker that returns [pixelPng] under [filename].
Future<PickedImage?> Function() stubPicker(String filename) =>
    () async => PickedImage(
      bytes: pixelPng,
      filename: filename,
      mimeType: 'image/png',
    );
