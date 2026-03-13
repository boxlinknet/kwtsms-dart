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
      expect(
          normalizePhone(
              '\u0669\u0666\u0665\u0669\u0668\u0667\u0666\u0665\u0664\u0663\u0662'),
          '96598765432');
    });

    test('converts Extended Arabic-Indic (Persian) digits', () {
      expect(
          normalizePhone(
              '\u06F9\u06F6\u06F5\u06F9\u06F8\u06F7\u06F6\u06F5\u06F4\u06F3\u06F2'),
          '96598765432');
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

    // Trunk prefix stripping tests
    test('strips Saudi trunk prefix: 9660559... -> 966559...', () {
      expect(normalizePhone('9660559876543'), '966559876543');
    });

    test('strips Saudi trunk prefix with + prefix', () {
      expect(normalizePhone('+9660559876543'), '966559876543');
    });

    test('strips Saudi trunk prefix with 00 prefix', () {
      expect(normalizePhone('009660559876543'), '966559876543');
    });

    test('strips UAE trunk prefix: 97105x -> 9715x', () {
      expect(normalizePhone('9710501234567'), '971501234567');
    });

    test('strips Egypt trunk prefix: 20010x -> 2010x', () {
      expect(normalizePhone('20010123456789'), '2010123456789');
    });

    test('strips Kuwait trunk prefix: 96509876 -> 9659876', () {
      // Kuwait numbers don't normally have trunk prefix, but handle it
      expect(normalizePhone('965098765432'), '96598765432');
    });

    test('does not strip when no trunk prefix', () {
      expect(normalizePhone('966559876543'), '966559876543');
    });

    test('strips multiple leading zeros in trunk prefix', () {
      expect(normalizePhone('966009876543'), '9669876543');
    });
  });

  group('findCountryCode', () {
    test('finds 3-digit code (Kuwait 965)', () {
      expect(findCountryCode('96598765432'), '965');
    });

    test('finds 2-digit code (Egypt 20)', () {
      expect(findCountryCode('201012345678'), '20');
    });

    test('finds 1-digit code (USA 1)', () {
      expect(findCountryCode('12025551234'), '1');
    });

    test('prefers longer code: 965 over 9 (no 9 rule)', () {
      expect(findCountryCode('96598765432'), '965');
    });

    test('prefers 3-digit over 2-digit when both exist', () {
      // 420 (Czech) should match before 42 (not a code)
      expect(findCountryCode('420612345678'), '420');
    });

    test('returns null for unknown prefix', () {
      expect(findCountryCode('999123456'), isNull);
    });

    test('returns null for empty string', () {
      expect(findCountryCode(''), isNull);
    });
  });

  group('validatePhoneFormat', () {
    test('valid Kuwait number', () {
      final (valid, error) = validatePhoneFormat('96598765432');
      expect(valid, true);
      expect(error, isNull);
    });

    test('invalid Kuwait number: wrong length', () {
      final (valid, error) = validatePhoneFormat('9651234567'); // 7 local
      expect(valid, false);
      expect(error, contains('Kuwait'));
      expect(error, contains('8 digits'));
    });

    test('invalid Kuwait number: wrong mobile prefix', () {
      final (valid, error) =
          validatePhoneFormat('96512345678'); // starts with 1
      expect(valid, false);
      expect(error, contains('Kuwait'));
      expect(error, contains('must start with'));
    });

    test('valid Saudi number', () {
      final (valid, error) = validatePhoneFormat('966559876543');
      expect(valid, true);
      expect(error, isNull);
    });

    test('invalid Saudi number: wrong mobile prefix', () {
      final (valid, error) =
          validatePhoneFormat('966359876543'); // starts with 3
      expect(valid, false);
      expect(error, contains('Saudi Arabia'));
    });

    test('valid UAE number', () {
      final (valid, error) = validatePhoneFormat('971501234567');
      expect(valid, true);
      expect(error, isNull);
    });

    test('valid Egypt number', () {
      final (valid, error) = validatePhoneFormat('201012345678');
      expect(valid, true);
      expect(error, isNull);
    });

    test('valid USA number', () {
      final (valid, error) = validatePhoneFormat('12025551234');
      expect(valid, true);
      expect(error, isNull);
    });

    test('unknown country code passes through', () {
      final (valid, error) = validatePhoneFormat('9991234567');
      expect(valid, true);
      expect(error, isNull);
    });

    test('Belgium: no mobile prefix check (length only)', () {
      final (valid, error) = validatePhoneFormat('32412345678');
      expect(valid, true);
      expect(error, isNull);
    });

    test('Lebanon: accepts 7-digit local', () {
      final (valid, error) = validatePhoneFormat('9613123456');
      expect(valid, true);
      expect(error, isNull);
    });

    test('Lebanon: accepts 8-digit local', () {
      final (valid, error) = validatePhoneFormat('96171234567');
      expect(valid, true);
      expect(error, isNull);
    });

    test('Indonesia: accepts variable length (9-12)', () {
      final (valid, _) = validatePhoneFormat('62812345678'); // 9 local
      expect(valid, true);
      final (valid2, _) = validatePhoneFormat('62812345678901'); // 12 local
      expect(valid2, true);
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

    test('minimum valid (7 digits, unknown country)', () {
      // Use a number whose prefix doesn't match any country rule
      final (valid, error, normalized) = validatePhoneInput('9991234');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '9991234');
    });

    test('maximum valid (15 digits, unknown country)', () {
      final (valid, error, normalized) = validatePhoneInput('999123456789012');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '999123456789012');
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

    // Country-specific validation via validatePhoneInput
    test('rejects invalid Kuwait mobile prefix', () {
      final (valid, error, _) = validatePhoneInput('96512345678');
      expect(valid, false);
      expect(error, contains('Kuwait'));
      expect(error, contains('must start with'));
    });

    test('rejects wrong-length Kuwait number', () {
      final (valid, error, _) = validatePhoneInput('9651234567'); // 7 local
      expect(valid, false);
      expect(error, contains('Kuwait'));
      expect(error, contains('8 digits'));
    });

    test('Saudi trunk prefix stripped and validated', () {
      final (valid, error, normalized) = validatePhoneInput('+9660559876543');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '966559876543');
    });

    test('Saudi with 00 and trunk prefix', () {
      final (valid, error, normalized) = validatePhoneInput('009660559876543');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '966559876543');
    });

    test('rejects Saudi with wrong mobile prefix after trunk strip', () {
      // 9660359... -> trunk strip -> 966359... -> 3 is not valid Saudi mobile
      final (valid, error, _) = validatePhoneInput('9660359876543');
      expect(valid, false);
      expect(error, contains('Saudi Arabia'));
    });

    test('UAE trunk prefix stripped', () {
      final (valid, error, normalized) = validatePhoneInput('9710501234567');
      expect(valid, true);
      expect(error, isNull);
      expect(normalized, '971501234567');
    });

    test('valid India number', () {
      final (valid, error, _) = validatePhoneInput('919876543210');
      expect(valid, true);
      expect(error, isNull);
    });

    test('valid UK number', () {
      final (valid, error, _) = validatePhoneInput('447911123456');
      expect(valid, true);
      expect(error, isNull);
    });

    test('unknown country code passes generic validation', () {
      final (valid, error, _) = validatePhoneInput('9991234567');
      expect(valid, true);
      expect(error, isNull);
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
