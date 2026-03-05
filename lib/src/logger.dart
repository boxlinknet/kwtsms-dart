// JSONL logging for kwtSMS API calls.
import 'dart:convert';
import 'dart:io';

/// Mask credentials in a request payload for logging.
///
/// Replaces the `password` field with `***`.
Map<String, dynamic> maskCredentials(Map<String, dynamic> payload) {
  final masked = Map<String, dynamic>.from(payload);
  if (masked.containsKey('password')) {
    masked['password'] = '***';
  }
  return masked;
}

/// Write a JSONL log entry for an API call.
///
/// Never throws. Logging failures are silently ignored to avoid
/// disrupting the main API flow.
void writeLog({
  required String logFile,
  required String endpoint,
  required Map<String, dynamic> request,
  required String response,
  required bool ok,
  String? error,
}) {
  if (logFile.isEmpty) return;

  try {
    final entry = {
      'ts': DateTime.now().toUtc().toIso8601String(),
      'endpoint': endpoint,
      'request': maskCredentials(request),
      'response': response,
      'ok': ok,
      'error': error,
    };

    final file = File(logFile);
    file.writeAsStringSync(
      '${jsonEncode(entry)}\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // Never crash on logging failures
  }
}
