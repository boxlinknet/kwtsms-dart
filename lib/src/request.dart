// HTTP request utility for kwtSMS API.
import 'dart:convert';
import 'dart:io';

import 'logger.dart';

/// Base URL for the kwtSMS API.
const String apiBaseUrl = 'https://www.kwtsms.com/API/';

/// Make a POST request to a kwtSMS API endpoint.
///
/// Returns the parsed JSON response as a Map.
/// Throws [HttpException] on network errors.
/// Throws [FormatException] on invalid JSON responses.
Future<Map<String, dynamic>> apiRequest({
  required String endpoint,
  required Map<String, dynamic> payload,
  String logFile = '',
}) async {
  final url = Uri.parse('$apiBaseUrl$endpoint/');
  String responseBody = '';
  bool success = false;
  String? errorMsg;

  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');

    final body = utf8.encode(jsonEncode(payload));
    request.contentLength = body.length;
    request.add(body);

    final response = await request.close().timeout(
          const Duration(seconds: 15),
        );

    responseBody = await response.transform(utf8.decoder).join();
    client.close(force: false);

    // Parse JSON response (read body even on 4xx/5xx)
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      errorMsg = 'Invalid JSON response: $responseBody';
      throw FormatException(errorMsg);
    }

    success = data['result'] == 'OK';
    if (!success) {
      errorMsg = data['description'] as String? ?? 'Unknown error';
    }

    return data;
  } on SocketException catch (e) {
    errorMsg = 'Network error: ${e.message}';
    rethrow;
  } on HttpException catch (e) {
    errorMsg = 'HTTP error: ${e.message}';
    rethrow;
  } catch (e) {
    errorMsg ??= 'Request failed: $e';
    if (e is FormatException || e is SocketException || e is HttpException) {
      rethrow;
    }
    throw HttpException(errorMsg);
  } finally {
    writeLog(
      logFile: logFile,
      endpoint: endpoint,
      request: payload,
      response: responseBody,
      ok: success,
      error: errorMsg,
    );
  }
}
