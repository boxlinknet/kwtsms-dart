import 'package:test/test.dart';
import 'package:kwtsms/kwtsms.dart';

void main() {
  group('cleanMessage', () {
    // Preservation tests
    test('preserves plain English text', () {
      expect(cleanMessage('Hello World'), 'Hello World');
    });

    test('preserves Arabic text', () {
      expect(cleanMessage('مرحبا بالعالم'), 'مرحبا بالعالم');
    });

    test('preserves newlines', () {
      expect(cleanMessage('Line 1\nLine 2'), 'Line 1\nLine 2');
    });

    test('preserves tabs', () {
      expect(cleanMessage('Col1\tCol2'), 'Col1\tCol2');
    });

    test('preserves regular spaces', () {
      expect(cleanMessage('a b c'), 'a b c');
    });

    test('preserves numbers', () {
      expect(cleanMessage('Order #12345'), 'Order #12345');
    });

    test('preserves punctuation', () {
      expect(cleanMessage('Hello, world! How are you?'), 'Hello, world! How are you?');
    });

    // Arabic digit conversion
    test('converts Arabic-Indic digits to Latin', () {
      expect(cleanMessage('Code: \u0661\u0662\u0663\u0664\u0665\u0666'),
          'Code: 123456');
    });

    test('converts Persian/Extended Arabic-Indic digits to Latin', () {
      expect(cleanMessage('Code: \u06F1\u06F2\u06F3\u06F4\u06F5\u06F6'),
          'Code: 123456');
    });

    test('converts mixed Arabic and Persian digits', () {
      expect(cleanMessage('\u0661\u06F2\u0663'), '123');
    });

    // Emoji removal
    test('strips smiley emoji', () {
      expect(cleanMessage('Hello \u{1F600}'), 'Hello ');
    });

    test('strips heart emoji', () {
      expect(cleanMessage('Love \u2764'), 'Love ');
    });

    test('strips flag emoji components', () {
      expect(cleanMessage('Flag \u{1F1F0}\u{1F1FC}'), 'Flag ');
    });

    test('strips transport emoji', () {
      expect(cleanMessage('Go \u{1F680}'), 'Go ');
    });

    test('strips food emoji', () {
      expect(cleanMessage('Eat \u{1F355}'), 'Eat ');
    });

    test('strips multiple emojis', () {
      expect(cleanMessage('\u{1F600}\u{1F601}\u{1F602}'), '');
    });

    test('strips variation selectors', () {
      // U+2764 (heart) + U+FE0F (variation selector)
      expect(cleanMessage('Star \u2764\uFE0F'), 'Star ');
    });

    test('strips combining enclosing keycap', () {
      expect(cleanMessage('1\u20E3'), '1');
    });

    // Hidden invisible characters
    test('strips zero-width space', () {
      expect(cleanMessage('Hello\u200BWorld'), 'HelloWorld');
    });

    test('strips zero-width non-joiner', () {
      expect(cleanMessage('Hello\u200CWorld'), 'HelloWorld');
    });

    test('strips zero-width joiner', () {
      expect(cleanMessage('Hello\u200DWorld'), 'HelloWorld');
    });

    test('strips word joiner', () {
      expect(cleanMessage('Hello\u2060World'), 'HelloWorld');
    });

    test('strips soft hyphen', () {
      expect(cleanMessage('Hello\u00ADWorld'), 'HelloWorld');
    });

    test('strips BOM', () {
      expect(cleanMessage('\uFEFFHello'), 'Hello');
    });

    test('strips object replacement character', () {
      expect(cleanMessage('Hello\uFFFCWorld'), 'HelloWorld');
    });

    // Directional formatting
    test('strips left-to-right mark', () {
      expect(cleanMessage('Hello\u200EWorld'), 'HelloWorld');
    });

    test('strips right-to-left mark', () {
      expect(cleanMessage('Hello\u200FWorld'), 'HelloWorld');
    });

    test('strips LRE/RLE/PDF/LRO/RLO', () {
      expect(cleanMessage('A\u202AB\u202BC\u202CD\u202DE\u202EF'), 'ABCDEF');
    });

    test('strips directional isolates', () {
      expect(cleanMessage('A\u2066B\u2067C\u2068D\u2069E'), 'ABCDE');
    });

    // C0/C1 control characters
    test('strips null byte', () {
      expect(cleanMessage('Hello\x00World'), 'HelloWorld');
    });

    test('strips bell character', () {
      expect(cleanMessage('Hello\x07World'), 'HelloWorld');
    });

    test('strips DEL character', () {
      expect(cleanMessage('Hello\x7FWorld'), 'HelloWorld');
    });

    test('strips C1 control characters', () {
      expect(cleanMessage('Hello\x80\x81\x9FWorld'), 'HelloWorld');
    });

    // HTML tags
    test('strips simple HTML tags', () {
      expect(cleanMessage('<b>Hello</b>'), 'Hello');
    });

    test('strips complex HTML', () {
      expect(
          cleanMessage('<div class="msg">Hello <span>World</span></div>'),
          'Hello World');
    });

    test('strips self-closing tags', () {
      expect(cleanMessage('Hello<br/>World'), 'HelloWorld');
    });

    // Combined scenarios
    test('handles Arabic text with emoji and HTML', () {
      expect(
          cleanMessage('<b>مرحبا</b> \u{1F600}'),
          'مرحبا ');
    });

    test('handles BOM + Arabic digits + emoji', () {
      expect(
          cleanMessage('\uFEFF\u0661\u0662\u0663 \u{1F600}'),
          '123 ');
    });

    test('emoji-only message becomes empty', () {
      expect(cleanMessage('\u{1F600}\u{1F601}\u{1F602}'), '');
    });

    test('preserves Arabic letters while converting Arabic digits', () {
      expect(cleanMessage('رمز التحقق: \u0661\u0662\u0663\u0664\u0665\u0666'),
          'رمز التحقق: 123456');
    });
  });
}
