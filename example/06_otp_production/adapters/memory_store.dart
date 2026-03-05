// memory_store.dart -- In-memory OTP store for development and testing.
//
// WARNING: This store is not persistent. All data is lost on restart.
// For production, implement OtpStore backed by Redis, PostgreSQL, etc.

import '../otp_service.dart';

/// In-memory implementation of [OtpStore].
///
/// Suitable for development, testing, and single-server deployments
/// where losing OTP state on restart is acceptable.
class MemoryOtpStore implements OtpStore {
  /// Active OTP records, keyed by normalized phone number.
  final _records = <String, OtpRecord>{};

  /// Send timestamps per phone, for rate limiting.
  final _sends = <String, List<DateTime>>{};

  @override
  Future<void> save(OtpRecord record) async {
    _records[record.phone] = record;
  }

  @override
  Future<OtpRecord?> find(String phone) async {
    final record = _records[phone];
    if (record == null) return null;

    // Auto-expire stale records on read.
    if (DateTime.now().isAfter(record.expiresAt)) {
      _records.remove(phone);
      return null;
    }

    return record;
  }

  @override
  Future<void> delete(String phone) async {
    _records.remove(phone);
  }

  @override
  Future<void> recordSend(String phone, DateTime timestamp) async {
    _sends.putIfAbsent(phone, () => []).add(timestamp);
  }

  @override
  Future<int> countSends(String phone, Duration window) async {
    final timestamps = _sends[phone];
    if (timestamps == null) return 0;

    final cutoff = DateTime.now().subtract(window);

    // Prune old entries while counting.
    timestamps.removeWhere((t) => t.isBefore(cutoff));
    return timestamps.length;
  }

  /// Number of active (non-expired) records. Useful for monitoring.
  int get activeRecords {
    final now = DateTime.now();
    _records.removeWhere((_, r) => now.isAfter(r.expiresAt));
    return _records.length;
  }

  /// Clear all data. Useful in tests.
  void clear() {
    _records.clear();
    _sends.clear();
  }
}
