import 'package:test/test.dart';
import 'package:kwtsms/kwtsms.dart';

void main() {
  group('normalizePhone', () {
    test('strips + prefix', () {
      expect(normalizePhone('+96598765432'), '96598765432');
    });

    test('strips 00 prefix', () {
      expect(normalizePhone('0096598765432'), '96598765432');
    });

    test('strips spaces', () {
      expect(normalizePhone('965 9876 5432'), '96598765432');
    });

    test('strips dashes', () {
      expect(normalizePhone('965-9876-5432'), '96598765432');
    });

    test('strips dots', () {
      expect(normalizePhone('965.9876.5432'), '96598765432');
    });

    test('strips parentheses', () {
      expect(normalizePhone('(965) 98765432'), '96598765432');
    });

    test('strips slashes', () {
      expect(normalizePhone('965/9876/5432'), '96598765432');
    });

    test('converts Arabic-Indic digits', () {
      expect(normalizePhone('\u0669\u0666\u0665\u0669\u0668\u0667\u0666\u0665\u0664\u0663\u0662'), '96598765432');
    });

    test('converts Extended Arabic-Indic (Persian) digits', () {
      expect(normalizePhone('\u06F9\u06F6\u06F5\u06F9\u06F8\u06F7\u06F6\u06F5\u06F4\u06F3\u06F2'), '96598765432');
    });

    test('strips leading zeros after normalization', () {
      expect(normalizePhone('00096598765432'), '96598765432');
    });

    test('returns empty string for empty input', () {
      expect(normalizePhone(''), '');
    });

    test('returns empty string for non-digit input', () {
      expect(normalizePhone('abcdef'), '');
    });

    test('handles mixed Arabic digits and Latin', () {
      expect(normalizePhone('\u0669\u0666\u0665123'), '965123');
    });

    test('coerces non-string input to string', () {
      expect(normalizePhone(12345678), '12345678');
    });

    test('trims whitespace', () {
      expect(normalizePhone('  96598765432  '), '96598765432');
    });

    test('handles complex format', () {
      expect(normalizePhone('+00 (965) 9876-5432'), '96598765432');
    });
  });

  group('validatePhoneInput', () {
    test('valid Kuwait number', () {
      final (valid, error, normalized) = validatePhoneInput('96598765432');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '96598765432');
    });

    test('empty string', () {
      final (valid, error, normalized) = validatePhoneInput('');
      expect(valid, false);
      expect(error, 'Phone number is required');
      expect(normalized, '');
    });

    test('blank string (spaces only)', () {
      final (valid, error, normalized) = validatePhoneInput('   ');
      expect(valid, false);
      expect(error, 'Phone number is required');
      expect(normalized, '');
    });

    test('email address', () {
      final (valid, error, _) = validatePhoneInput('user@example.com');
      expect(valid, false);
      expect(error, contains('email address'));
    });

    test('no digits after normalization', () {
      final (valid, error, _) = validatePhoneInput('abcdef');
      expect(valid, false);
      expect(error, contains('no digits found'));
    });

    test('too short (less than 7 digits)', () {
      final (valid, error, normalized) = validatePhoneInput('12345');
      expect(valid, false);
      expect(error, contains('too short'));
      expect(error, contains('5 digits'));
      expect(normalized, '12345');
    });

    test('too long (more than 15 digits)', () {
      final (valid, error, normalized) = validatePhoneInput('1234567890123456');
      expect(valid, false);
      expect(error, contains('too long'));
      expect(error, contains('16 digits'));
      expect(normalized, '1234567890123456');
    });

    test('minimum valid (7 digits)', () {
      final (valid, error, normalized) = validatePhoneInput('1234567');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '1234567');
    });

    test('maximum valid (15 digits)', () {
      final (valid, error, normalized) = validatePhoneInput('123456789012345');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '123456789012345');
    });

    test('valid with + prefix', () {
      final (valid, error, normalized) = validatePhoneInput('+96598765432');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '96598765432');
    });

    test('valid with 00 prefix', () {
      final (valid, error, normalized) = validatePhoneInput('0096598765432');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '96598765432');
    });

    test('valid Arabic digits', () {
      final (valid, error, normalized) = validatePhoneInput(
          '\u0669\u0666\u0665\u0669\u0668\u0667\u0666\u0665\u0664\u0663\u0662');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '96598765432');
    });

    test('coerces non-string input', () {
      final (valid, error, normalized) = validatePhoneInput(96598765432);
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '96598765432');
    });
  });

  group('deduplicatePhones', () {
    test('removes duplicates preserving order', () {
      expect(
        deduplicatePhones(['111', '222', '111', '333', '222']),
        ['111', '222', '333'],
      );
    });

    test('empty list', () {
      expect(deduplicatePhones([]), isEmpty);
    });

    test('no duplicates', () {
      expect(deduplicatePhones(['111', '222', '333']), ['111', '222', '333']);
    });

    test('all same', () {
      expect(deduplicatePhones(['111', '111', '111']), ['111']);
    });
  });

  group('InvalidEntry', () {
    test('equality', () {
      const a = InvalidEntry(input: '123', error: 'too short');
      const b = InvalidEntry(input: '123', error: 'too short');
      expect(a, b);
    });

    test('toJson', () {
      const entry = InvalidEntry(input: 'abc', error: 'no digits');
      expect(entry.toJson(), {'input': 'abc', 'error': 'no digits'});
    });
  });
}
