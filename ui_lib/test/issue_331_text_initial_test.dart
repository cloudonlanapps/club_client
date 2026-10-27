import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show textInitial;

void main() {
  group('Issue 331: textInitial', () {
    test('Issue 331: an emoji-first text gives the whole emoji', () {
      expect(textInitial('🏒 Hockey'), '🏒');
      expect(textInitial('👨‍👩‍👧 Family'), '👨‍👩‍👧');
    });

    test('Issue 331: a Devanagari text gives its first character', () {
      // 'क्ष' is one grapheme cluster of three code points.
      expect(textInitial('क्षमा'), 'क्ष');
      expect(textInitial('नमस्ते'), 'न');
    });

    test('Issue 331: blank text gives an empty string', () {
      expect(textInitial(''), '');
      expect(textInitial('   '), '');
    });

    test('Issue 331: lower case is upper-cased, after trimming', () {
      expect(textInitial('hockey'), 'H');
      expect(textInitial('  ice'), 'I');
    });
  });
}
