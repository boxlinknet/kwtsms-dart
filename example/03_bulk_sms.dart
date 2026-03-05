// 03_bulk_sms.dart -- Sending SMS to more than 200 numbers.
//
// Demonstrates: bulk send with automatic batching, result tracking,
// and msg-id collection.
//
// The library automatically splits lists of >200 numbers into batches
// of 200, with a 0.5s delay between each batch. ERR013 (queue full)
// is retried automatically with exponential backoff.
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/03_bulk_sms.dart

import 'package:kwtsms/kwtsms.dart';

Future<void> main() async {
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  // Build a list of 450 numbers for demonstration.
  // In production these would come from a database or CSV.
  final numbers = <String>[];
  for (var i = 0; i < 450; i++) {
    // Generate sample Kuwait numbers (these are not real).
    final suffix = (50000000 + i).toString();
    numbers.add('965$suffix');
  }
  print('Prepared ${numbers.length} numbers for bulk send.');

  // -- Send using sendBulk --
  print('\n--- Bulk send ---');
  final result = await sms.sendBulk(
    numbers,
    'Scheduled maintenance: our service will be offline tonight 11 PM - 1 AM.',
  );

  // -- Overall result --
  print('Result: ${result.result}');
  print('Batches: ${result.batches}');
  print('Numbers sent: ${result.numbers}');
  print('Points charged: ${result.pointsCharged}');
  print('Balance after: ${result.balanceAfter}');

  // -- Collect msg-ids for tracking --
  if (result.msgIds.isNotEmpty) {
    print('\n--- Message IDs ---');
    for (var i = 0; i < result.msgIds.length; i++) {
      print('  Batch ${i + 1}: ${result.msgIds[i]}');
    }

    // Check status of first batch.
    print('\n--- Status of first batch ---');
    final status = await sms.status(result.msgIds.first);
    print('Status: ${status.status ?? "pending"}');
  }

  // -- Batch errors --
  if (result.errors.isNotEmpty) {
    print('\n--- Batch errors ---');
    for (final err in result.errors) {
      print('  Batch ${err.batch}: ${err.code} -- ${err.description}');
      if (err.action != null) print('    Action: ${err.action}');
    }
  }

  // -- Invalid numbers --
  if (result.invalid.isNotEmpty) {
    print('\n--- Invalid numbers (${result.invalid.length}) ---');
    for (final inv in result.invalid.take(5)) {
      print('  ${inv.input}: ${inv.error}');
    }
    if (result.invalid.length > 5) {
      print('  ... and ${result.invalid.length - 5} more.');
    }
  }

  // -- Partial results --
  if (result.result == 'PARTIAL') {
    print('\nSome batches failed. Successfully sent batches:');
    print('  msg-ids: ${result.msgIds.join(", ")}');
    print('Failed batches: ${result.errors.length}');
  }

  print('\nDone.');
}
