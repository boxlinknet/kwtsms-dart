import 'dart:io';
import 'package:kwtsms/kwtsms.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = args[0];

  switch (command) {
    case 'setup':
      await _setup();
    case 'verify':
      await _runWithAutoSetup(() => _verify());
    case 'balance':
      await _runWithAutoSetup(() => _balance());
    case 'senderid':
      await _runWithAutoSetup(() => _senderIds());
    case 'coverage':
      await _runWithAutoSetup(() => _coverage());
    case 'send':
      await _runWithAutoSetup(() => _send(args.sublist(1)));
    case 'validate':
      await _runWithAutoSetup(() => _validate(args.sublist(1)));
    case 'status':
      await _runWithAutoSetup(() => _status(args.sublist(1)));
    case 'dlr':
      await _runWithAutoSetup(() => _dlr(args.sublist(1)));
    case 'help':
    case '--help':
    case '-h':
      _printUsage();
    case 'version':
    case '--version':
    case '-v':
      print('kwtsms 0.1.10');
    default:
      stderr.writeln('Unknown command: $command');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('''
kwtsms - kwtSMS SMS gateway CLI

Usage:
  kwtsms <command> [arguments]

Commands:
  setup                                  Interactive setup wizard
  verify                                 Test credentials and show balance
  balance                                Show available and purchased credits
  senderid                               List sender IDs
  coverage                               List active country prefixes
  send <mobile> <message> [--sender ID]  Send SMS
  validate <number> [number2 ...]        Validate phone numbers
  status <msg-id>                        Check message delivery status
  dlr <msg-id>                           Get delivery report (international only)
  help                                   Show this help
  version                                Show version

Environment:
  KWTSMS_USERNAME   API username
  KWTSMS_PASSWORD   API password
  KWTSMS_SENDER_ID  Sender ID (default: KWT-SMS)
  KWTSMS_TEST_MODE  Set to 1 for test mode
  KWTSMS_LOG_FILE   Log file path (default: kwtsms.log)

  Or create a .env file with these variables.
''');
}

/// Auto-trigger setup if no .env file exists and credentials are missing.
Future<void> _runWithAutoSetup(Future<void> Function() action) async {
  try {
    _createClient();
  } on ArgumentError {
    if (!File('.env').existsSync()) {
      print('No .env file found. Starting first-time setup...\n');
      await _setup();
      print('');
    } else {
      stderr.writeln('Error: credentials missing or incomplete in .env');
      stderr.writeln("Run 'kwtsms setup' to fix.");
      exit(1);
    }
  }
  await action();
}

KwtSMS _createClient() {
  final sms = KwtSMS.fromEnv();
  return sms;
}

Future<void> _setup() async {
  print('\n── kwtSMS Setup ──────────────────────────────────────────────────');
  print('Verifies your API credentials and creates a .env file.');
  print('Press Enter to keep the value shown in brackets.\n');

  final existing = loadEnvFile('.env');

  // Username
  final defaultUser = existing['KWTSMS_USERNAME'] ?? '';
  final promptUser =
      defaultUser.isNotEmpty ? 'API Username [$defaultUser]: ' : 'API Username: ';
  stdout.write(promptUser);
  final rawUser = stdin.readLineSync()?.trim() ?? '';
  final username = rawUser.isNotEmpty ? rawUser : defaultUser;

  // Password (hidden input)
  final defaultPass = existing['KWTSMS_PASSWORD'] ?? '';
  if (defaultPass.isNotEmpty) {
    stdout.write('API Password [keep existing]: ');
  } else {
    stdout.write('API Password: ');
  }
  String password;
  try {
    stdin.echoMode = false;
    final rawPass = stdin.readLineSync()?.trim() ?? '';
    stdin.echoMode = true;
    print(''); // newline after hidden input
    password = rawPass.isNotEmpty ? rawPass : defaultPass;
  } catch (_) {
    // echoMode not supported (e.g., piped input), fall back to visible input
    final rawPass = stdin.readLineSync()?.trim() ?? '';
    password = rawPass.isNotEmpty ? rawPass : defaultPass;
  }

  if (username.isEmpty || password.isEmpty) {
    print('\nError: username and password are required.');
    exit(1);
  }

  // Verify credentials
  stdout.write('\nVerifying credentials... ');
  try {
    final data = await apiRequest(
      endpoint: 'balance',
      payload: {'username': username, 'password': password},
      logFile: '',
    );
    if (data['result'] != 'OK') {
      final err = data['description'] ?? data['code'] ?? 'Unknown error';
      print('FAILED\nError: $err');
      exit(1);
    }
    print('OK  (Balance: ${data['available'] ?? '?'})');
  } catch (e) {
    print('FAILED\nError: $e');
    exit(1);
  }

  // Fetch Sender IDs
  stdout.write('Fetching Sender IDs... ');
  var senderIds = <String>[];
  try {
    final sidData = await apiRequest(
      endpoint: 'senderid',
      payload: {'username': username, 'password': password},
      logFile: '',
    );
    if (sidData['result'] == 'OK') {
      final raw = sidData['senderid'];
      if (raw is List) {
        senderIds = raw.map((e) => '$e').toList();
      }
    }
  } catch (_) {}

  String senderId;
  if (senderIds.isNotEmpty) {
    print('OK');
    print('\nAvailable Sender IDs:');
    for (var i = 0; i < senderIds.length; i++) {
      print('  ${i + 1}. ${senderIds[i]}');
    }
    final defaultSid = existing['KWTSMS_SENDER_ID'] ?? senderIds[0];
    stdout.write('\nSelect Sender ID (number or name) [$defaultSid]: ');
    final choice = stdin.readLineSync()?.trim() ?? '';
    final choiceNum = int.tryParse(choice);
    if (choiceNum != null && choiceNum >= 1 && choiceNum <= senderIds.length) {
      senderId = senderIds[choiceNum - 1];
    } else {
      senderId = choice.isNotEmpty ? choice : defaultSid;
    }
  } else {
    print('(none returned)');
    final defaultSid = existing['KWTSMS_SENDER_ID'] ?? 'KWT-SMS';
    stdout.write('Sender ID [$defaultSid]: ');
    final rawSid = stdin.readLineSync()?.trim() ?? '';
    senderId = rawSid.isNotEmpty ? rawSid : defaultSid;
  }

  // Send mode
  final currentMode = existing['KWTSMS_TEST_MODE'] ?? '1';
  print('\nSend mode:');
  print('  1. Test mode: messages queued but NOT delivered, no credits consumed  [default]');
  print('  2. Live mode: messages delivered to handsets, credits consumed');
  final modeDefault = currentMode != '0' ? '1' : '2';
  stdout.write('\nChoose [$modeDefault]: ');
  final rawMode = stdin.readLineSync()?.trim() ?? '';
  final modeChoice = rawMode.isNotEmpty ? rawMode : modeDefault;
  final testMode = modeChoice == '2' ? '0' : '1';

  if (testMode == '1') {
    print('  → Test mode selected.');
  } else {
    print('  → Live mode selected. Real messages will be sent and credits consumed.');
  }

  // Log file
  final defaultLog = existing['KWTSMS_LOG_FILE'] ?? 'kwtsms.log';
  print('\nAPI logging (every API call is logged to a file, passwords are always masked):');
  if (defaultLog.isNotEmpty) {
    print('  Current: $defaultLog');
  }
  print('  Type "off" to disable logging.');
  stdout.write('  Log file path [${defaultLog.isNotEmpty ? defaultLog : 'off'}]: ');
  final logInput = stdin.readLineSync()?.trim() ?? '';
  String logFilePath;
  if (logInput.toLowerCase() == 'off') {
    logFilePath = '';
    print('  → Logging disabled.');
  } else if (logInput.isNotEmpty) {
    logFilePath = logInput;
  } else {
    logFilePath = defaultLog;
  }

  // Sanitize: strip newlines to prevent credential values from breaking .env
  final safeUsername = username.replaceAll(RegExp(r'[\r\n]'), '');
  final safePassword = password.replaceAll(RegExp(r'[\r\n]'), '');
  final safeSenderId = senderId.replaceAll(RegExp(r'[\r\n]'), '');
  final safeLogPath = logFilePath.replaceAll(RegExp(r'[\r\n]'), '');

  // Write .env
  final content = '# kwtSMS credentials, generated by kwtsms setup\n'
      'KWTSMS_USERNAME=$safeUsername\n'
      'KWTSMS_PASSWORD=$safePassword\n'
      'KWTSMS_SENDER_ID=$safeSenderId\n'
      'KWTSMS_TEST_MODE=$testMode\n'
      'KWTSMS_LOG_FILE=$safeLogPath\n';

  try {
    File('.env').writeAsStringSync(content);
    // Set file permissions to owner read/write only (Unix)
    try {
      Process.runSync('chmod', ['600', '.env']);
    } catch (_) {
      // chmod not available on Windows, skip silently
    }
  } catch (e) {
    stderr.writeln('\nError writing .env: $e');
    exit(1);
  }

  print('\n  Saved to .env');
  if (testMode == '1') {
    print('  Mode: TEST: messages queued but not delivered (no credits consumed)');
  } else {
    print('  Mode: LIVE: messages will be delivered and credits consumed');
  }
  print("  Run 'kwtsms setup' at any time to change settings.");
  print('─────────────────────────────────────────────────────────────────\n');
}

Future<void> _verify() async {
  final sms = _createClient();
  if (sms.testMode) {
    print('WARNING: Test mode is enabled. Messages will not be delivered.\n');
  }
  final result = await sms.verify();
  if (result.ok) {
    print('Credentials: OK');
    print('Balance: ${result.balance} credits');
    if (sms.cachedPurchased != null) {
      print('Purchased: ${sms.cachedPurchased} credits');
    }
  } else {
    stderr.writeln('Error: ${result.error}');
    exit(1);
  }
}

Future<void> _balance() async {
  final sms = _createClient();
  final bal = await sms.balance();
  if (bal != null) {
    print('Available: $bal credits');
    if (sms.cachedPurchased != null) {
      print('Purchased: ${sms.cachedPurchased} credits');
    }
  } else {
    stderr.writeln('Error: could not retrieve balance');
    exit(1);
  }
}

Future<void> _senderIds() async {
  final sms = _createClient();
  final result = await sms.senderIds();
  if (result.result == 'OK') {
    print('Sender IDs:');
    for (final id in result.senderIds) {
      print('  - $id');
    }
  } else {
    stderr.writeln('Error: ${result.action ?? result.description}');
    exit(1);
  }
}

Future<void> _coverage() async {
  final sms = _createClient();
  final result = await sms.coverage();
  if (result.result == 'OK') {
    print('Active country prefixes:');
    for (final prefix in result.prefixes) {
      print('  - $prefix');
    }
  } else {
    stderr.writeln('Error: ${result.action ?? result.description}');
    exit(1);
  }
}

Future<void> _send(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: kwtsms send <mobile> <message> [--sender ID]');
    exit(1);
  }

  final mobile = args[0];
  String? sender;
  final messageParts = <String>[];

  var i = 1;
  while (i < args.length) {
    if (args[i] == '--sender' && i + 1 < args.length) {
      sender = args[i + 1];
      i += 2;
    } else {
      messageParts.add(args[i]);
      i++;
    }
  }

  final message = messageParts.join(' ');
  if (message.isEmpty) {
    stderr.writeln('Error: message is required');
    exit(1);
  }

  final sms = _createClient();
  if (sms.testMode) {
    print('WARNING: Test mode is enabled. Message will NOT be delivered.\n');
  }

  final result = await sms.send(mobile, message, sender: sender);
  if (result.result == 'OK') {
    print('Result: OK');
    print('Message ID: ${result.msgId}');
    print('Numbers: ${result.numbers}');
    print('Points charged: ${result.pointsCharged}');
    print('Balance after: ${result.balanceAfter}');
  } else {
    stderr.writeln('Error: ${result.result}');
    if (result.code != null) stderr.writeln('Code: ${result.code}');
    if (result.description != null) {
      stderr.writeln('Description: ${result.description}');
    }
    if (result.action != null) stderr.writeln('Action: ${result.action}');
    exit(1);
  }

  if (result.invalid.isNotEmpty) {
    print('\nInvalid numbers:');
    for (final entry in result.invalid) {
      print('  ${entry.input}: ${entry.error}');
    }
  }
}

Future<void> _validate(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: kwtsms validate <number> [number2 ...]');
    exit(1);
  }

  final sms = _createClient();
  final result = await sms.validate(args);

  if (result.ok.isNotEmpty) {
    print('Valid (OK):');
    for (final n in result.ok) {
      print('  $n');
    }
  }
  if (result.er.isNotEmpty) {
    print('Format error (ER):');
    for (final n in result.er) {
      print('  $n');
    }
  }
  if (result.nr.isNotEmpty) {
    print('No route (NR):');
    for (final n in result.nr) {
      print('  $n');
    }
  }
  if (result.rejected.isNotEmpty) {
    print('Rejected locally:');
    for (final entry in result.rejected) {
      print('  ${entry.input}: ${entry.error}');
    }
  }
  if (result.error != null) {
    stderr.writeln('Error: ${result.error}');
    exit(1);
  }
}

Future<void> _status(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: kwtsms status <msg-id>');
    exit(1);
  }

  final sms = _createClient();
  final result = await sms.status(args[0]);
  if (result.result == 'OK') {
    print('Status: ${result.status}');
    if (result.statusDescription != null) {
      print('Description: ${result.statusDescription}');
    }
  } else {
    stderr.writeln('Error: ${result.action ?? result.description}');
    exit(1);
  }
}

Future<void> _dlr(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: kwtsms dlr <msg-id>');
    exit(1);
  }

  final sms = _createClient();
  final result = await sms.deliveryReport(args[0]);
  if (result.result == 'OK') {
    print('Delivery Report:');
    for (final entry in result.report) {
      print('  ${entry.number}: ${entry.status}');
    }
  } else {
    stderr.writeln('Error: ${result.action ?? result.description}');
    exit(1);
  }
}
