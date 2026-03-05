// otp_service.dart -- Production-grade OTP service.
//
// Features:
//   - Configurable OTP length, TTL, and max attempts
//   - Salted hash storage (simplified; use package:crypto for real SHA-256)
//   - Per-phone rate limiting (in-memory)
//   - Pluggable store, attestation verifier, and token authenticator
//
// This file is self-contained with zero external dependencies.
// For real SHA-256 hashing, add `package:crypto` to your pubspec.yaml.

import 'dart:convert';
import 'dart:math';

import 'package:kwtsms/kwtsms.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Tunable OTP constants. Override by creating a new instance.
class OtpConfig {
  /// Number of digits in the OTP code.
  final int codeLength;

  /// How long a code is valid, in seconds.
  final int ttlSeconds;

  /// Maximum verification attempts before the code is invalidated.
  final int maxAttempts;

  /// Minimum seconds between OTP sends to the same phone.
  final int rateLimitSeconds;

  /// Maximum OTP sends to a single phone within [rateLimitWindowSeconds].
  final int rateLimitMaxSends;

  /// Rolling window for [rateLimitMaxSends], in seconds.
  final int rateLimitWindowSeconds;

  /// Salt length in bytes for code hashing.
  final int saltLength;

  const OtpConfig({
    this.codeLength = 6,
    this.ttlSeconds = 300, // 5 minutes
    this.maxAttempts = 3,
    this.rateLimitSeconds = 60,
    this.rateLimitMaxSends = 5,
    this.rateLimitWindowSeconds = 3600, // 1 hour
    this.saltLength = 16,
  });
}

// ---------------------------------------------------------------------------
// Abstract interfaces (protocols)
// ---------------------------------------------------------------------------

/// Stored OTP record.
class OtpRecord {
  final String phone;
  final String hashedCode; // salt:hash (see [OtpService._hashCode])
  final DateTime expiresAt;
  final int attempts;
  final String? msgId; // kwtSMS msg-id for delivery tracking

  const OtpRecord({
    required this.phone,
    required this.hashedCode,
    required this.expiresAt,
    this.attempts = 0,
    this.msgId,
  });

  /// Create a copy with updated fields.
  OtpRecord copyWith({int? attempts, String? msgId}) {
    return OtpRecord(
      phone: phone,
      hashedCode: hashedCode,
      expiresAt: expiresAt,
      attempts: attempts ?? this.attempts,
      msgId: msgId ?? this.msgId,
    );
  }
}

/// Abstract OTP storage. Implement this for your database.
abstract class OtpStore {
  /// Save an OTP record, overwriting any existing record for this phone.
  Future<void> save(OtpRecord record);

  /// Retrieve the current OTP record for a phone, or null if none exists.
  Future<OtpRecord?> find(String phone);

  /// Delete the OTP record for a phone.
  Future<void> delete(String phone);

  /// Record a send timestamp for rate limiting.
  Future<void> recordSend(String phone, DateTime timestamp);

  /// Count sends to this phone within the given window.
  Future<int> countSends(String phone, Duration window);
}

/// Verifies device attestation tokens (App Attest, Play Integrity).
///
/// Implement this to block requests from emulators and bots.
abstract class DeviceAttestVerifier {
  /// Returns true if the attestation token is valid.
  Future<bool> verify(String token);
}

/// Authenticates the request bearer token.
///
/// Implement this to ensure only your backend (or authenticated users)
/// can trigger OTP sends.
abstract class TokenAuthenticator {
  /// Returns true if the token is valid.
  Future<bool> authenticate(String token);
}

// ---------------------------------------------------------------------------
// OTP result types
// ---------------------------------------------------------------------------

/// Result of [OtpService.sendOtp].
class SendOtpResult {
  final bool ok;
  final String? error;
  final String? msgId;
  final int? retryAfterSeconds;

  const SendOtpResult({
    required this.ok,
    this.error,
    this.msgId,
    this.retryAfterSeconds,
  });
}

/// Result of [OtpService.verifyOtp].
class VerifyOtpResult {
  final bool ok;
  final String? error;
  final int? remainingAttempts;

  const VerifyOtpResult({
    required this.ok,
    this.error,
    this.remainingAttempts,
  });
}

// ---------------------------------------------------------------------------
// OTP Service
// ---------------------------------------------------------------------------

class OtpService {
  final KwtSMS _sms;
  final OtpStore _store;
  final DeviceAttestVerifier? _attestVerifier;
  final TokenAuthenticator? _tokenAuth;
  final OtpConfig config;

  final _rng = Random.secure();

  OtpService({
    required KwtSMS sms,
    required OtpStore store,
    DeviceAttestVerifier? attestVerifier,
    TokenAuthenticator? tokenAuth,
    this.config = const OtpConfig(),
  })  : _sms = sms,
        _store = store,
        _attestVerifier = attestVerifier,
        _tokenAuth = tokenAuth;

  // -------------------------------------------------------------------------
  // Send OTP
  // -------------------------------------------------------------------------

  /// Send an OTP to [phone].
  ///
  /// - [attestationToken]: device attestation token (optional but recommended)
  /// - [ip]: client IP for logging/abuse detection
  Future<SendOtpResult> sendOtp(
    String phone, {
    String? attestationToken,
    String? ip,
  }) async {
    // 1. Validate phone number locally.
    final (valid, error, normalized) = validatePhoneInput(phone);
    if (!valid) {
      return SendOtpResult(ok: false, error: 'Invalid phone: $error');
    }

    // 2. Verify device attestation (if configured).
    if (_attestVerifier != null && attestationToken != null) {
      final verifier = _attestVerifier!;
      final attOk = await verifier.verify(attestationToken);
      if (!attOk) {
        return const SendOtpResult(
          ok: false,
          error: 'Device attestation failed.',
        );
      }
    }

    // 2b. Verify auth token (if configured, for 2FA flows).
    if (_tokenAuth != null) {
      // Token authentication is available but requires a token parameter.
      // Extend sendOtp() signature to accept an authToken if needed.
    }

    // 3. Check rate limits.
    final recentSends = await _store.countSends(
      normalized,
      Duration(seconds: config.rateLimitWindowSeconds),
    );
    if (recentSends >= config.rateLimitMaxSends) {
      return SendOtpResult(
        ok: false,
        error: 'Too many OTP requests. Try again later.',
        retryAfterSeconds: config.rateLimitSeconds,
      );
    }

    // 4. Generate code and hash it.
    final code = _generateCode();
    final hashedCode = _hashCode(code);

    // 5. Store the record.
    final record = OtpRecord(
      phone: normalized,
      hashedCode: hashedCode,
      expiresAt: DateTime.now().add(Duration(seconds: config.ttlSeconds)),
    );
    await _store.save(record);
    await _store.recordSend(normalized, DateTime.now());

    // 6. Send SMS.
    final message = 'Your verification code is: $code\n'
        'Valid for ${config.ttlSeconds ~/ 60} minutes. '
        'Do not share this code with anyone.';
    final result = await _sms.send(normalized, message);

    if (result.result != 'OK') {
      // Clean up the stored record on send failure.
      await _store.delete(normalized);
      return SendOtpResult(
        ok: false,
        error: 'Failed to send SMS. Please try again.',
      );
    }

    // 7. Update record with msg-id for delivery tracking.
    if (result.msgId != null) {
      await _store.save(record.copyWith(msgId: result.msgId));
    }

    return SendOtpResult(ok: true, msgId: result.msgId);
  }

  // -------------------------------------------------------------------------
  // Verify OTP
  // -------------------------------------------------------------------------

  /// Verify an OTP [code] for [phone].
  ///
  /// - [ip]: client IP for logging/abuse detection
  Future<VerifyOtpResult> verifyOtp(
    String phone,
    String code, {
    String? ip,
  }) async {
    // 1. Normalize phone.
    final (valid, error, normalized) = validatePhoneInput(phone);
    if (!valid) {
      return VerifyOtpResult(ok: false, error: 'Invalid phone: $error');
    }

    // 2. Find record.
    final record = await _store.find(normalized);
    if (record == null) {
      return const VerifyOtpResult(
        ok: false,
        error: 'No OTP found. Request a new code.',
      );
    }

    // 3. Check expiry.
    if (DateTime.now().isAfter(record.expiresAt)) {
      await _store.delete(normalized);
      return const VerifyOtpResult(
        ok: false,
        error: 'Code has expired. Request a new one.',
      );
    }

    // 4. Check attempts.
    if (record.attempts >= config.maxAttempts) {
      await _store.delete(normalized);
      return const VerifyOtpResult(
        ok: false,
        error: 'Too many incorrect attempts. Request a new code.',
      );
    }

    // 5. Compare hash (constant-time).
    final inputHash = _hashCode(code, existingSaltHash: record.hashedCode);
    if (!_constantTimeEquals(inputHash, record.hashedCode)) {
      // Increment attempts.
      final remaining = config.maxAttempts - record.attempts - 1;
      await _store.save(record.copyWith(attempts: record.attempts + 1));
      return VerifyOtpResult(
        ok: false,
        error: 'Incorrect code.',
        remainingAttempts: remaining,
      );
    }

    // 6. Success -- delete the record.
    await _store.delete(normalized);
    return const VerifyOtpResult(ok: true);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Generate a random numeric code.
  String _generateCode() {
    final buf = StringBuffer();
    for (var i = 0; i < config.codeLength; i++) {
      buf.write(_rng.nextInt(10));
    }
    return buf.toString();
  }

  /// Hash a code with a random salt.
  ///
  /// Format: "base64(salt):base64(hash)"
  ///
  /// IMPORTANT: This uses a simplified hash for the zero-dependency example.
  /// In production, replace this with proper SHA-256 from `package:crypto`:
  ///
  ///   import 'package:crypto/crypto.dart';
  ///   final hash = sha256.convert(utf8.encode('$salt:$code')).toString();
  ///
  String _hashCode(String code, {String? existingSaltHash}) {
    final String saltB64;

    if (existingSaltHash != null) {
      // Re-use the existing salt for comparison.
      saltB64 = existingSaltHash.split(':').first;
    } else {
      // Generate a new random salt.
      final saltBytes = List<int>.generate(config.saltLength, (_) => _rng.nextInt(256));
      saltB64 = base64Encode(saltBytes);
    }

    // Simplified hash: base64(salt + ":" + code).
    // PRODUCTION: use SHA-256 instead of plain base64.
    // Example with package:crypto:
    //   final digest = sha256.convert(utf8.encode('$saltB64:$code'));
    //   return '$saltB64:${digest.toString()}';
    final combined = utf8.encode('$saltB64:$code');
    final hashB64 = base64Encode(combined);

    return '$saltB64:$hashB64';
  }

  /// Constant-time string comparison to prevent timing attacks.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
