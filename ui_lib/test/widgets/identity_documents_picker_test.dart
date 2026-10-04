import 'package:flutter_test/flutter_test.dart';
// Direct import of the dart:io backend — these helpers are pure and run on the
// test VM. Not exported from the barrel (Linux-internal).
import 'package:ui_lib/src/widgets/identity_documents/identity_documents_picker_io.dart';
import 'package:ui_lib/src/widgets/identity_documents/picked_image.dart'
    show kPickerImageExtensions, mimeTypeForExtension;

void main() {
  group('Issue 709: buildZenityArguments', () {
    final args = buildZenityArguments(
      title: 'Select image',
      extensions: kPickerImageExtensions,
    );

    test('opens a file-selection dialog with the modal hint (#709 fix)', () {
      expect(args, contains('--file-selection'));
      // --modal is the fix: without it zenity opens behind the app window.
      expect(args, contains('--modal'));
    });

    test('carries the supplied title', () {
      final i = args.indexOf('--title');
      expect(i, isNonNegative);
      expect(args[i + 1], 'Select image');
    });

    test('builds a case-insensitive image filter for every extension', () {
      final filter = args.firstWhere((a) => a.startsWith('--file-filter='));
      for (final ext in kPickerImageExtensions) {
        expect(filter, contains('*.$ext'));
        expect(filter, contains('*.${ext.toUpperCase()}'));
      }
    });
  });

  group('Issue 709: mimeTypeForExtension', () {
    test('maps known image extensions, case-insensitively', () {
      expect(mimeTypeForExtension('png'), 'image/png');
      expect(mimeTypeForExtension('.PNG'), 'image/png');
      expect(mimeTypeForExtension('webp'), 'image/webp');
      expect(mimeTypeForExtension('WEBP'), 'image/webp');
      expect(mimeTypeForExtension('jpg'), 'image/jpeg');
      expect(mimeTypeForExtension('jpeg'), 'image/jpeg');
    });

    test('falls back to jpeg for unknown / missing extensions', () {
      expect(mimeTypeForExtension('gif'), 'image/jpeg');
      expect(mimeTypeForExtension(null), 'image/jpeg');
      expect(mimeTypeForExtension(''), 'image/jpeg');
    });
  });
}
