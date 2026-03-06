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
      await _verify();
    case 'balance':
      await _balance();
    case 'senderid':
      await _senderIds();
    case 'coverage':
      await _coverage();
    case 'send':
      await _send(args.sublist(1));
    case 'validate':
      await _validate(args.sublist(1));
    case 'status':
      await _status(args.sublist(1));
    case 'dlr':
      await _dlr(args.sublist(1));
    case 'help':
    case '--help':
    case '-h':
      _printUsage();
    case 'version':
    case '--version':
    case '-v':
      print('kwtsms 0.1.7');
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

KwtSMS _createClient() {
  final sms = KwtSMS.fromEnv();
  return sms;
}

Future<void> _setup() async {
  print('kwtSMS Setup Wizard');
  print('==================\n');

  stdout.write('API Username: ');
  final username = stdin.readLineSync()?.trim() ?? '';

  stdout.write('API Password: ');
  final password = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Sender ID (press Enter for KWT-SMS): ');
  final senderId = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Enable test mode? (y/N): ');
  final testModeInput = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  final testMode = testModeInput == 'y' || testModeInput == 'yes';

  final envContent = StringBuffer();
  envContent.writeln('KWTSMS_USERNAME=$username');
  envContent.writeln('KWTSMS_PASSWORD=$password');
  if (senderId.isNotEmpty) {
    envContent.writeln('KWTSMS_SENDER_ID=$senderId');
  }
  if (testMode) {
    envContent.writeln('KWTSMS_TEST_MODE=1');
  }
  envContent.writeln('KWTSMS_LOG_FILE=kwtsms.log');

  File('.env').writeAsStringSync(envContent.toString());
  print('\n.env file created successfully.');

  // Verify credentials
  print('\nVerifying credentials...');
  final sms = KwtSMS(
    username,
    password,
    senderId: senderId.isNotEmpty ? senderId : 'KWT-SMS',
    testMode: testMode,
  );
  final result = await sms.verify();
  if (result.ok) {
    print('Credentials verified. Balance: ${result.balance} credits.');
  } else {
    stderr.writeln('Verification failed: ${result.error}');
  }
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
