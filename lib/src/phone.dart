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

/// Country-specific phone validation rule.
class PhoneRule {
  /// Valid local number lengths (digits after country code).
  final List<int> localLengths;

  /// Valid first digit(s) of local number for mobile.
  /// If empty, any starting digit is accepted.
  final List<String> mobileStartDigits;

  const PhoneRule({
    required this.localLengths,
    this.mobileStartDigits = const [],
  });
}

/// Phone number validation rules by country code.
/// Validates local number length and mobile starting digits.
///
/// Sources (verified across 3+ per country):
/// [1] ITU-T E.164 / National Numbering Plans (itu.int)
/// [2] Wikipedia "Telephone numbers in [Country]" articles
/// [3] HowToCallAbroad.com country dialing guides
/// [4] CountryCode.com country format pages
///
/// localLengths: valid digit count(s) AFTER country code
/// mobileStartDigits: valid first character(s) of the local number
///
/// Countries not listed pass through with generic E.164 validation (7-15 digits).
const Map<String, PhoneRule> phoneRules = {
  // === GCC ===
  '965': PhoneRule(
      localLengths: [8], mobileStartDigits: ['4', '5', '6', '9']), // Kuwait
  '966': PhoneRule(localLengths: [9], mobileStartDigits: ['5']), // Saudi Arabia
  '971': PhoneRule(localLengths: [9], mobileStartDigits: ['5']), // UAE
  '973': PhoneRule(localLengths: [8], mobileStartDigits: ['3', '6']), // Bahrain
  '974': PhoneRule(
      localLengths: [8], mobileStartDigits: ['3', '5', '6', '7']), // Qatar
  '968': PhoneRule(localLengths: [8], mobileStartDigits: ['7', '9']), // Oman
  // === Levant ===
  '962': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Jordan
  '961': PhoneRule(
      localLengths: [7, 8], mobileStartDigits: ['3', '7', '8']), // Lebanon
  '970': PhoneRule(localLengths: [9], mobileStartDigits: ['5']), // Palestine
  '964': PhoneRule(localLengths: [10], mobileStartDigits: ['7']), // Iraq
  '963': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Syria
  // === Other Arab ===
  '967': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Yemen
  '20': PhoneRule(localLengths: [10], mobileStartDigits: ['1']), // Egypt
  '218': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Libya
  '216': PhoneRule(
      localLengths: [8], mobileStartDigits: ['2', '4', '5', '9']), // Tunisia
  '212': PhoneRule(localLengths: [9], mobileStartDigits: ['6', '7']), // Morocco
  '213': PhoneRule(
      localLengths: [9], mobileStartDigits: ['5', '6', '7']), // Algeria
  '249': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Sudan
  // === Non-Arab Middle East ===
  '98': PhoneRule(localLengths: [10], mobileStartDigits: ['9']), // Iran
  '90': PhoneRule(localLengths: [10], mobileStartDigits: ['5']), // Turkey
  '972': PhoneRule(localLengths: [9], mobileStartDigits: ['5']), // Israel
  // === South Asia ===
  '91': PhoneRule(
      localLengths: [10], mobileStartDigits: ['6', '7', '8', '9']), // India
  '92': PhoneRule(localLengths: [10], mobileStartDigits: ['3']), // Pakistan
  '880': PhoneRule(localLengths: [10], mobileStartDigits: ['1']), // Bangladesh
  '94': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Sri Lanka
  '960':
      PhoneRule(localLengths: [7], mobileStartDigits: ['7', '9']), // Maldives
  // === East Asia ===
  '86': PhoneRule(localLengths: [11], mobileStartDigits: ['1']), // China
  '81': PhoneRule(
      localLengths: [10], mobileStartDigits: ['7', '8', '9']), // Japan
  '82': PhoneRule(localLengths: [10], mobileStartDigits: ['1']), // South Korea
  '886': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Taiwan
  // === Southeast Asia ===
  '65':
      PhoneRule(localLengths: [8], mobileStartDigits: ['8', '9']), // Singapore
  '60': PhoneRule(localLengths: [9, 10], mobileStartDigits: ['1']), // Malaysia
  '62': PhoneRule(
      localLengths: [9, 10, 11, 12], mobileStartDigits: ['8']), // Indonesia
  '63': PhoneRule(localLengths: [10], mobileStartDigits: ['9']), // Philippines
  '66': PhoneRule(
      localLengths: [9], mobileStartDigits: ['6', '8', '9']), // Thailand
  '84': PhoneRule(
      localLengths: [9],
      mobileStartDigits: ['3', '5', '7', '8', '9']), // Vietnam
  '95': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Myanmar
  '855': PhoneRule(
      localLengths: [8, 9],
      mobileStartDigits: ['1', '6', '7', '8', '9']), // Cambodia
  '976': PhoneRule(
      localLengths: [8], mobileStartDigits: ['6', '8', '9']), // Mongolia
  // === Europe ===
  '44': PhoneRule(localLengths: [10], mobileStartDigits: ['7']), // UK
  '33': PhoneRule(localLengths: [9], mobileStartDigits: ['6', '7']), // France
  '49': PhoneRule(localLengths: [10, 11], mobileStartDigits: ['1']), // Germany
  '39': PhoneRule(localLengths: [10], mobileStartDigits: ['3']), // Italy
  '34': PhoneRule(localLengths: [9], mobileStartDigits: ['6', '7']), // Spain
  '31': PhoneRule(localLengths: [9], mobileStartDigits: ['6']), // Netherlands
  '32': PhoneRule(localLengths: [9]), // Belgium
  '41': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Switzerland
  '43': PhoneRule(localLengths: [10], mobileStartDigits: ['6']), // Austria
  '47': PhoneRule(localLengths: [8], mobileStartDigits: ['4', '9']), // Norway
  '48': PhoneRule(localLengths: [9]), // Poland
  '30': PhoneRule(localLengths: [10], mobileStartDigits: ['6']), // Greece
  '420': PhoneRule(
      localLengths: [9], mobileStartDigits: ['6', '7']), // Czech Republic
  '46': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Sweden
  '45': PhoneRule(localLengths: [8]), // Denmark
  '40': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Romania
  '36': PhoneRule(localLengths: [9]), // Hungary
  '380': PhoneRule(localLengths: [9]), // Ukraine
  // === Americas ===
  '1': PhoneRule(localLengths: [10]), // USA/Canada
  '52': PhoneRule(localLengths: [10]), // Mexico
  '55': PhoneRule(localLengths: [11]), // Brazil
  '57': PhoneRule(localLengths: [10], mobileStartDigits: ['3']), // Colombia
  '54': PhoneRule(localLengths: [10], mobileStartDigits: ['9']), // Argentina
  '56': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Chile
  '58': PhoneRule(localLengths: [10], mobileStartDigits: ['4']), // Venezuela
  '51': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Peru
  '593': PhoneRule(localLengths: [9], mobileStartDigits: ['9']), // Ecuador
  '53': PhoneRule(localLengths: [8], mobileStartDigits: ['5', '6']), // Cuba
  // === Africa ===
  '27': PhoneRule(
      localLengths: [9], mobileStartDigits: ['6', '7', '8']), // South Africa
  '234': PhoneRule(
      localLengths: [10], mobileStartDigits: ['7', '8', '9']), // Nigeria
  '254': PhoneRule(localLengths: [9], mobileStartDigits: ['1', '7']), // Kenya
  '233': PhoneRule(localLengths: [9], mobileStartDigits: ['2', '5']), // Ghana
  '251':
      PhoneRule(localLengths: [9], mobileStartDigits: ['7', '9']), // Ethiopia
  '255':
      PhoneRule(localLengths: [9], mobileStartDigits: ['6', '7']), // Tanzania
  '256': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Uganda
  '237': PhoneRule(localLengths: [9], mobileStartDigits: ['6']), // Cameroon
  '225': PhoneRule(localLengths: [10]), // Ivory Coast
  '221': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Senegal
  '252': PhoneRule(localLengths: [9], mobileStartDigits: ['6', '7']), // Somalia
  '250': PhoneRule(localLengths: [9], mobileStartDigits: ['7']), // Rwanda
  // === Oceania ===
  '61': PhoneRule(localLengths: [9], mobileStartDigits: ['4']), // Australia
  '64': PhoneRule(
      localLengths: [8, 9, 10], mobileStartDigits: ['2']), // New Zealand
};

/// Country names by country code for error messages.
const Map<String, String> countryNames = {
  // Middle East & North Africa
  '965': 'Kuwait', '966': 'Saudi Arabia', '971': 'UAE',
  '973': 'Bahrain', '974': 'Qatar', '968': 'Oman',
  '962': 'Jordan', '961': 'Lebanon', '970': 'Palestine',
  '964': 'Iraq', '963': 'Syria', '967': 'Yemen',
  '98': 'Iran', '90': 'Turkey', '972': 'Israel',
  '20': 'Egypt', '218': 'Libya', '216': 'Tunisia',
  '212': 'Morocco', '213': 'Algeria', '249': 'Sudan',
  // Africa
  '27': 'South Africa', '234': 'Nigeria', '254': 'Kenya',
  '233': 'Ghana', '251': 'Ethiopia', '255': 'Tanzania',
  '256': 'Uganda', '237': 'Cameroon', '225': 'Ivory Coast',
  '221': 'Senegal', '252': 'Somalia', '250': 'Rwanda',
  // Europe
  '44': 'UK', '33': 'France', '49': 'Germany',
  '39': 'Italy', '34': 'Spain', '31': 'Netherlands',
  '32': 'Belgium', '41': 'Switzerland', '43': 'Austria',
  '47': 'Norway', '48': 'Poland', '30': 'Greece',
  '420': 'Czech Republic', '46': 'Sweden', '45': 'Denmark',
  '40': 'Romania', '36': 'Hungary', '380': 'Ukraine',
  // Americas
  '1': 'USA/Canada', '52': 'Mexico', '55': 'Brazil',
  '57': 'Colombia', '54': 'Argentina', '56': 'Chile',
  '58': 'Venezuela', '51': 'Peru', '593': 'Ecuador', '53': 'Cuba',
  // Asia
  '91': 'India', '92': 'Pakistan', '86': 'China',
  '81': 'Japan', '82': 'South Korea', '886': 'Taiwan',
  '65': 'Singapore', '60': 'Malaysia', '62': 'Indonesia',
  '63': 'Philippines', '66': 'Thailand', '84': 'Vietnam',
  '95': 'Myanmar', '855': 'Cambodia', '976': 'Mongolia',
  '880': 'Bangladesh', '94': 'Sri Lanka', '960': 'Maldives',
  // Oceania
  '61': 'Australia', '64': 'New Zealand',
};

/// Find the country code prefix from a normalized phone number.
/// Tries 3-digit codes first, then 2-digit, then 1-digit (longest match wins).
String? findCountryCode(String normalized) {
  if (normalized.length >= 3) {
    final cc3 = normalized.substring(0, 3);
    if (phoneRules.containsKey(cc3)) return cc3;
  }
  if (normalized.length >= 2) {
    final cc2 = normalized.substring(0, 2);
    if (phoneRules.containsKey(cc2)) return cc2;
  }
  if (normalized.isNotEmpty) {
    final cc1 = normalized.substring(0, 1);
    if (phoneRules.containsKey(cc1)) return cc1;
  }
  return null;
}

/// Validate a normalized phone number against country-specific format rules.
/// Checks local number length and mobile starting digits.
/// Numbers with no matching country rules pass through (generic E.164 only).
(bool valid, String? error) validatePhoneFormat(String normalized) {
  final cc = findCountryCode(normalized);
  if (cc == null) return (true, null);

  final rule = phoneRules[cc]!;
  final local = normalized.substring(cc.length);
  final country = countryNames[cc] ?? '+$cc';

  // Check local number length
  if (!rule.localLengths.contains(local.length)) {
    final expected = rule.localLengths.join(' or ');
    return (
      false,
      'Invalid $country number: expected $expected digits after +$cc, got ${local.length}',
    );
  }

  // Check mobile starting digits (if rules exist for this country)
  if (rule.mobileStartDigits.isNotEmpty) {
    final hasValidPrefix =
        rule.mobileStartDigits.any((prefix) => local.startsWith(prefix));
    if (!hasValidPrefix) {
      return (
        false,
        'Invalid $country mobile number: after +$cc must start with ${rule.mobileStartDigits.join(', ')}',
      );
    }
  }

  return (true, null);
}

/// Normalize a phone number to kwtSMS-accepted format (digits only).
///
/// 1. Converts Arabic-Indic and Extended Arabic-Indic/Persian digits to Latin
/// 2. Strips all non-digit characters
/// 3. Strips leading zeros
/// 4. Strips domestic trunk prefix (leading 0 after country code),
///    e.g. 9660559... becomes 966559..., 97105x becomes 9715x
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

  // Strip leading zeros (handles 00 country prefix)
  s = s.replaceFirst(RegExp(r'^0+'), '');

  // Strip domestic trunk prefix (leading 0 after country code)
  // e.g. 9660559... -> 966559..., 97105x -> 9715x, 20010x -> 2010x
  final cc = findCountryCode(s);
  if (cc != null) {
    final local = s.substring(cc.length);
    if (local.startsWith('0')) {
      s = cc + local.replaceFirst(RegExp(r'^0+'), '');
    }
  }

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

  // Validate against country-specific format rules (length + mobile prefix)
  final (formatValid, formatError) = validatePhoneFormat(normalized);
  if (!formatValid) {
    return (false, formatError, normalized);
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
