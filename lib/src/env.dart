// .env file parser for kwtSMS credentials.
import 'dart:io';

/// Load environment variables from a .env file.
///
/// Parsing rules:
/// - Ignores blank lines and lines starting with #
/// - Strips inline # comments from unquoted values
/// - Supports single and double quoted values (preserves # inside quotes)
/// - Returns empty map for missing files (never throws)
/// - Does NOT modify the process environment (read-only)
Map<String, String> loadEnvFile([String filePath = '.env']) {
  final result = <String, String>{};

  try {
    final file = File(filePath);
    if (!file.existsSync()) return result;

    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();

      // Skip blank lines and comments
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Find the first = sign
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx < 0) continue;

      final key = trimmed.substring(0, eqIdx).trim();
      if (key.isEmpty) continue;

      var value = trimmed.substring(eqIdx + 1).trim();

      // Handle quoted values
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      } else {
        // Strip inline comments for unquoted values
        final commentIdx = value.indexOf('#');
        if (commentIdx >= 0) {
          value = value.substring(0, commentIdx).trim();
        }
      }

      result[key] = value;
    }
  } catch (_) {
    // Never throw on file read errors
  }

  return result;
}
