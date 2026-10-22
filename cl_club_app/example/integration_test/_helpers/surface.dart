// The size a test draws the app at.
//
// Owns:
//   * useTestSurface — a large desktop surface for the test (so nothing
//                      needs scrolling on the Linux desktop), unless the run
//                      asks for the device's own viewport (#264).
//
// A phone run passes --dart-define=REAL_VIEWPORT=true, so the app is laid
// out at the phone's size, as a member sees it, instead of a desktop layout
// shrunk to fit the screen.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _kRealViewport = bool.fromEnvironment('REAL_VIEWPORT');

/// Draws the app at [size] for the rest of the test, unless the run keeps
/// the device's own viewport (`REAL_VIEWPORT=true`).
Future<void> useTestSurface(WidgetTester tester, Size size) async {
  if (_kRealViewport) return;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
