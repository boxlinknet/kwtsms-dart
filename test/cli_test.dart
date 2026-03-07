import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';

/// Run the CLI as a subprocess and capture output.
Future<ProcessResult> runCli(List<String> args) async {
  return Process.run('dart', ['run', 'bin/kwtsms.dart', ...args],
      workingDirectory: Directory.current.path);
}

/// Run the CLI with explicit environment variables for credentials.
Future<ProcessResult> runCliWithCreds(
  List<String> args, {
  required String username,
  required String password,
}) async {
  return Process.run('dart', ['run', 'bin/kwtsms.dart', ...args],
      workingDirectory: Directory.current.path,
      environment: {
        'KWTSMS_USERNAME': username,
        'KWTSMS_PASSWORD': password,
        'KWTSMS_TEST_MODE': '1',
        'KWTSMS_LOG_FILE': '',
      });
}

/// Generate 250 unique Kuwait phone numbers: 9659922XXXX with random XXXX.
List<String> _generateBulkNumbers(int count) {
  final rng = Random(42); // seeded for reproducibility
  final suffixes = <int>{};
  while (suffixes.length < count) {
    suffixes.add(rng.nextInt(10000));
  }
  return suffixes
      .map((s) => '9659922${s.toString().padLeft(4, '0')}')
      .toList();
}

void main() {
  group('CLI help', () {
    test('no args prints usage and exits with code 1', () async {
      final result = await runCli([]);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('kwtsms - kwtSMS SMS gateway CLI'));
      expect(result.stdout, contains('Commands:'));
    });

    test('help command prints usage and exits with code 0', () async {
      final result = await runCli(['help']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('kwtsms - kwtSMS SMS gateway CLI'));
    });

    test('--help prints usage and exits with code 0', () async {
      final result = await runCli(['--help']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('kwtsms - kwtSMS SMS gateway CLI'));
    });

    test('-h prints usage and exits with code 0', () async {
      final result = await runCli(['-h']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('kwtsms - kwtSMS SMS gateway CLI'));
    });

    test('usage includes all commands', () async {
      final result = await runCli(['help']);
      final output = result.stdout as String;
      expect(output, contains('setup'));
      expect(output, contains('verify'));
      expect(output, contains('balance'));
      expect(output, contains('senderid'));
      expect(output, contains('coverage'));
      expect(output, contains('send'));
      expect(output, contains('validate'));
      expect(output, contains('status'));
      expect(output, contains('dlr'));
      expect(output, contains('version'));
    });

    test('usage includes environment variables', () async {
      final result = await runCli(['help']);
      final output = result.stdout as String;
      expect(output, contains('KWTSMS_USERNAME'));
      expect(output, contains('KWTSMS_PASSWORD'));
      expect(output, contains('KWTSMS_SENDER_ID'));
      expect(output, contains('KWTSMS_TEST_MODE'));
      expect(output, contains('KWTSMS_LOG_FILE'));
    });
  });

  group('CLI version', () {
    test('version command prints version', () async {
      final result = await runCli(['version']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('kwtsms'));
      expect((result.stdout as String).trim(), matches(RegExp(r'^kwtsms \d+\.\d+\.\d+$')));
    });

    test('--version prints version', () async {
      final result = await runCli(['--version']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('kwtsms'));
    });

    test('-v prints version', () async {
      final result = await runCli(['-v']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('kwtsms'));
    });
  });

  group('CLI unknown command', () {
    test('unknown command prints error and usage', () async {
      final result = await runCli(['foobar']);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Unknown command: foobar'));
    });
  });

  group('CLI argument validation', () {
    test('send without args prints usage error', () async {
      final result = await runCli(['send']);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Usage: kwtsms send'));
    });

    test('send with only mobile (no message) prints error', () async {
      final result = await runCli(['send', '96598765432']);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Usage: kwtsms send'));
    });

    test('validate without args prints usage error', () async {
      final result = await runCli(['validate']);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Usage: kwtsms validate'));
    });

    test('status without args prints usage error', () async {
      final result = await runCli(['status']);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Usage: kwtsms status'));
    });

    test('dlr without args prints usage error', () async {
      final result = await runCli(['dlr']);
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Usage: kwtsms dlr'));
    });
  });

  group('CLI no credentials', () {
    test('verify without credentials shows setup prompt or error', () async {
      // Run in a temp dir with no .env and no env vars
      final tempDir = Directory.systemTemp.createTempSync('kwtsms_cli_test_');
      try {
        final result = await Process.run(
          'dart',
          ['run', '${Directory.current.path}/bin/kwtsms.dart', 'verify'],
          workingDirectory: tempDir.path,
          environment: {
            // Clear credentials
            'KWTSMS_USERNAME': '',
            'KWTSMS_PASSWORD': '',
          },
        );
        // Should either trigger auto-setup (waiting for stdin) or error out
        // Since stdin is closed in subprocess, it should fail
        expect(result.exitCode, isNot(0));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('CLI bulk send 250 numbers (live API, test mode) [250 credits]', () {
    final username = Platform.environment['DART_USERNAME'] ?? '';
    final password = Platform.environment['DART_PASSWORD'] ?? '';
    final hasCredentials = username.isNotEmpty && password.isNotEmpty;

    test('send 250 numbers triggers bulk send via CLI', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }

      // 1. Call balance via CLI to know exact credits before starting.
      //    This test will consume exactly 250 credits (1 per number).
      final balOut = await runCliWithCreds(
        ['balance'],
        username: username,
        password: password,
      );
      expect(balOut.exitCode, 0,
          reason: 'balance must succeed: ${balOut.stderr}');
      final availMatch =
          RegExp(r'Available:\s+([\d.]+)').firstMatch(balOut.stdout as String);
      expect(availMatch, isNotNull, reason: 'balance output must show credits');
      final balanceBefore = double.parse(availMatch!.group(1)!);

      // Abort early if insufficient credits
      expect(balanceBefore, greaterThanOrEqualTo(250),
          reason: 'Need at least 250 credits for CLI bulk send. '
              'Current: $balanceBefore');

      // 2. Generate 250 unique numbers: 9659922XXXX
      final numbers = _generateBulkNumbers(250);
      final mobileArg = numbers.join(',');

      // 3. Send via CLI — triggers internal bulk send (200 + 50)
      final sendOut = await runCliWithCreds(
        ['send', mobileArg, 'Dart CLI bulk test 250 numbers'],
        username: username,
        password: password,
      );
      final stdout = sendOut.stdout as String;
      final stderr = sendOut.stderr as String;
      expect(sendOut.exitCode, 0,
          reason: 'bulk send should succeed: $stderr');
      expect(stdout, contains('Result: OK'));

      // 4. Parse msg-id, numbers, points, balance from output
      final msgIdMatch =
          RegExp(r'Message ID:\s+(\S+)').firstMatch(stdout);
      expect(msgIdMatch, isNotNull, reason: 'output must show Message ID');
      final msgId = msgIdMatch!.group(1)!;

      final numbersMatch =
          RegExp(r'Numbers:\s+(\d+)').firstMatch(stdout);
      expect(numbersMatch, isNotNull);
      expect(int.parse(numbersMatch!.group(1)!), 250,
          reason: '250 unique numbers should all be sent');

      final pointsMatch =
          RegExp(r'Points charged:\s+(\d+)').firstMatch(stdout);
      expect(pointsMatch, isNotNull);
      expect(int.parse(pointsMatch!.group(1)!), 250,
          reason: '1 point per number = 250 points');

      final balAfterMatch =
          RegExp(r'Balance after:\s+([\d.]+)').firstMatch(stdout);
      expect(balAfterMatch, isNotNull);
      final balanceAfter = double.parse(balAfterMatch!.group(1)!);
      expect(balanceAfter, balanceBefore - 250,
          reason: 'balance should decrease by exactly 250 '
              '(before: $balanceBefore, after: $balanceAfter)');

      // 5. Verify balance via a separate CLI balance call after send
      final balAfterOut = await runCliWithCreds(
        ['balance'],
        username: username,
        password: password,
      );
      expect(balAfterOut.exitCode, 0);
      final finalMatch =
          RegExp(r'Available:\s+([\d.]+)')
              .firstMatch(balAfterOut.stdout as String);
      expect(finalMatch, isNotNull);
      final confirmedBalance = double.parse(finalMatch!.group(1)!);
      expect(confirmedBalance, balanceAfter,
          reason: 'balance from separate call should match send response');

      // 6. Check status of msg-id via CLI.
      //    Test-mode messages are stuck in queue → ERR030 is expected.
      //    CLI prints the action message (not the code) to stderr.
      final statusOut = await runCliWithCreds(
        ['status', msgId],
        username: username,
        password: password,
      );
      // ERR030 causes exit code 1 (error path in CLI)
      expect(statusOut.exitCode, 1);
      final statusStderr = statusOut.stderr as String;
      expect(statusStderr.toLowerCase(),
          anyOf(contains('queue'), contains('err030')),
          reason: 'test-mode messages show ERR030 (stuck in queue)');
    }, timeout: Timeout(Duration(seconds: 120)));
  });
}
