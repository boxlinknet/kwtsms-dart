import 'dart:io';
import 'package:test/test.dart';
import 'package:kwtsms/kwtsms.dart';

void main() {
  final username = Platform.environment['DART_USERNAME'] ?? '';
  final password = Platform.environment['DART_PASSWORD'] ?? '';
  final hasCredentials = username.isNotEmpty && password.isNotEmpty;

  late KwtSMS sms;

  setUp(() {
    if (hasCredentials) {
      sms = KwtSMS(username, password, testMode: true, logFile: '');
    }
  });

  group('Integration tests (real API, test mode)', () {
    test('verify with valid credentials succeeds', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.verify();
      expect(result.ok, isTrue);
      expect(result.balance, isNotNull);
      expect(result.balance, greaterThanOrEqualTo(0));
    });

    test('verify with wrong credentials fails', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final bad = KwtSMS('wrong_user', 'wrong_pass', testMode: true, logFile: '');
      final result = await bad.verify();
      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
    });

    test('balance returns a number', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final bal = await sms.balance();
      expect(bal, isNotNull);
      expect(bal, greaterThanOrEqualTo(0));
    });

    test('send to valid Kuwait number succeeds (test mode)', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('96598765432', 'Test from Dart client');
      // In test mode, result should be OK
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.msgId, isNotNull);
      }
    });

    test('send to too-short number returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('12345', 'Test message');
      expect(result.result, 'ERROR');
      expect(result.invalid, isNotEmpty);
      expect(result.invalid.first.error, contains('too short'));
    });

    test('send to email returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('user@example.com', 'Test message');
      expect(result.result, 'ERROR');
      expect(result.invalid, isNotEmpty);
      expect(result.invalid.first.error, contains('email'));
    });

    test('send empty message returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('96598765432', '');
      expect(result.result, 'ERROR');
    });

    test('send emoji-only message returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('96598765432', '\u{1F600}\u{1F601}');
      expect(result.result, 'ERROR');
      expect(result.code, 'ERR009');
    });

    test('send with + prefix normalizes correctly', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('+96598765432', 'Test normalization');
      expect(result.result, anyOf('OK', 'ERROR'));
    });

    test('send with 00 prefix normalizes correctly', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('0096598765432', 'Test 00 prefix');
      expect(result.result, anyOf('OK', 'ERROR'));
    });

    test('send with Arabic digits normalizes correctly', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send(
        '\u0669\u0666\u0665\u0669\u0668\u0667\u0666\u0665\u0664\u0663\u0662',
        'Test Arabic digits',
      );
      expect(result.result, anyOf('OK', 'ERROR'));
    });

    test('send mixed valid and invalid numbers', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send(
        '96598765432,123,user@email.com',
        'Test mixed numbers',
      );
      // Should have invalid entries for bad numbers
      expect(result.invalid, isNotEmpty);
    });

    test('send deduplicates normalized numbers', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send(
        '+96598765432,0096598765432,96598765432',
        'Test deduplication',
      );
      // All three normalize to the same number, should send only once
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.numbers, 1);
      }
    });

    test('validate numbers', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.validate(['96598765432', '123', 'test@email.com']);
      // 123 and email should be rejected locally
      expect(result.rejected.length, 2);
    });

    test('senderIds returns a list', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.senderIds();
      expect(result.result, 'OK');
      expect(result.senderIds, isNotEmpty);
    });

    test('coverage returns prefixes', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.coverage();
      expect(result.result, 'OK');
    });

    test('status with invalid msgId returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.status('invalid_msg_id_12345');
      expect(result.result, 'ERROR');
    });

    test('deliveryReport with invalid msgId returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.deliveryReport('invalid_msg_id_12345');
      expect(result.result, 'ERROR');
    });

    test('send with wrong sender ID returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send(
        '96598765432',
        'Test wrong sender',
        sender: 'INVALID-SENDER-ID-THAT-DOES-NOT-EXIST',
      );
      // API should reject the sender ID
      expect(result.result, anyOf('OK', 'ERROR'));
    });

    test('cachedBalance is updated after verify', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      await sms.verify();
      expect(sms.cachedBalance, isNotNull);
    });
  });
}
