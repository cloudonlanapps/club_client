import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

void main() {
  group('Issue 324: PdfAction.fileNameFor', () {
    test('Issue 324: names the file after the title', () {
      expect(PdfAction.fileNameFor('Membership form'), 'Membership form.pdf');
    });

    test('Issue 324: keeps an extension the title already has', () {
      expect(PdfAction.fileNameFor('Consent.PDF'), 'Consent.PDF');
    });

    test('Issue 324: replaces what a file name may not hold', () {
      expect(PdfAction.fileNameFor('U/12: form?'), 'U_12_ form_.pdf');
    });

    test('Issue 324: a blank title is a document', () {
      expect(PdfAction.fileNameFor('  '), 'document.pdf');
    });
  });
}
