// Phone number normalization and validation utilities.

/// Structured type for numbers that failed local pre-validation.
class InvalidEntry {
  final String input;
  final String error;

  const InvalidEntry({required this.input, required this.error});

  Map<String, dynamic> toJson() => {'input': input, 'error': error};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvalidEntry && input == other.input && error == other.error;

  @override
  int get hashCode => Object.hash(input, error);

  @override
  String toString() => 'InvalidEntry(input: $input, error: $error)';
}

/// Normalize a phone number to kwtSMS-accepted format (digits only).
///
/// 1. Converts Arabic-Indic and Extended Arabic-Indic/Persian digits to Latin
/// 2. Strips all non-digit characters
/// 3. Strips leading zeros
String normalizePhone(dynamic phone) {
  var s = '$phone'.trim();

  // Convert Arabic-Indic digits (U+0660-U+0669)
  const arabicDigits =
      '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
  // Convert Extended Arabic-Indic / Persian digits (U+06F0-U+06F9)
  const persianDigits =
      '\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9';

  final buf = StringBuffer();
  for (final rune in s.runes) {
    final char = String.fromCharCode(rune);
    final arabicIdx = arabicDigits.indexOf(char);
    if (arabicIdx >= 0) {
      buf.write(arabicIdx);
      continue;
    }
    final persianIdx = persianDigits.indexOf(char);
    if (persianIdx >= 0) {
      buf.write(persianIdx);
      continue;
    }
    buf.write(char);
  }
  s = buf.toString();

  // Strip all non-digit characters
  s = s.replaceAll(RegExp(r'\D'), '');

  // Strip leading zeros
  s = s.replaceFirst(RegExp(r'^0+'), '');

  return s;
}

/// Validate a phone number input.
///
/// Returns a record with:
/// - `valid`: whether the input is a valid phone number
/// - `error`: error message if invalid, null if valid
/// - `normalized`: the normalized phone number
(bool valid, String? error, String normalized) validatePhoneInput(
    dynamic phone) {
  final raw = '$phone'.trim();

  if (raw.isEmpty) {
    return (false, 'Phone number is required', '');
  }

  if (raw.contains('@')) {
    return (false, "'$raw' is an email address, not a phone number", '');
  }

  final normalized = normalizePhone(raw);

  if (normalized.isEmpty) {
    return (false, "'$raw' is not a valid phone number, no digits found", '');
  }

  if (normalized.length < 7) {
    return (
      false,
      "'$raw' is too short (${normalized.length} digits, minimum is 7)",
      normalized,
    );
  }

  if (normalized.length > 15) {
    return (
      false,
      "'$raw' is too long (${normalized.length} digits, maximum is 15)",
      normalized,
    );
  }

  return (true, null, normalized);
}

/// Remove duplicate phone numbers while preserving order.
List<String> deduplicatePhones(List<String> phones) {
  final seen = <String>{};
  final result = <String>[];
  for (final phone in phones) {
    if (seen.add(phone)) {
      result.add(phone);
    }
  }
  return result;
}
