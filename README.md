# kwtSMS for Dart

[![pub package](https://img.shields.io/pub/v/kwtsms.svg)](https://pub.dev/packages/kwtsms)
[![CI](https://github.com/boxlinknet/kwtsms-dart/actions/workflows/test.yml/badge.svg)](https://github.com/boxlinknet/kwtsms-dart/actions/workflows/test.yml)
[![Static Analysis](https://github.com/boxlinknet/kwtsms-dart/actions/workflows/codeql.yml/badge.svg)](https://github.com/boxlinknet/kwtsms-dart/actions/workflows/codeql.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/dart-%3E%3D3.0-blue.svg)](https://dart.dev)
[![pub points](https://img.shields.io/pub/points/kwtsms)](https://pub.dev/packages/kwtsms/score)

Official Dart/Flutter client for the [kwtSMS](https://www.kwtsms.com) SMS gateway API. Zero dependencies. Send SMS, check balance, validate numbers, and more.

## About kwtSMS

kwtSMS is a Kuwaiti SMS gateway trusted by top businesses to deliver messages anywhere in the world, with private Sender ID, free API testing, non-expiring credits, and competitive flat-rate pricing. Secure, simple to integrate, built to last. Open a free account in under 1 minute, no paperwork or payment required. [Click here to get started](https://www.kwtsms.com/signup/)

## Prerequisites

You need **Dart** (3.0 or newer) installed. If you use Flutter, Dart is included.

### Option A: Dart only (server-side / CLI)

```bash
dart --version
```

If you see a version number (e.g., `Dart SDK version: 3.x.x`), Dart is installed. If not:

- **macOS:** `brew tap dart-lang/dart && brew install dart`
- **Ubuntu/Debian:** Follow instructions at https://dart.dev/get-dart#install
- **Windows:** Download from https://dart.dev/get-dart#install

### Option B: Flutter (mobile / cross-platform apps)

```bash
flutter --version
```

If you see a version number, Flutter (with Dart) is installed. If not, follow https://docs.flutter.dev/get-started/install

### Install kwtsms

For a Dart project:
```bash
dart pub add kwtsms
```

For a Flutter project:
```bash
flutter pub add kwtsms
```

## Quick Start

```dart
import 'package:kwtsms/kwtsms.dart';

void main() async {
  final sms = KwtSMS('your_api_user', 'your_api_pass');

  // Verify credentials
  final verify = await sms.verify();
  print('Balance: ${verify.balance}');

  // Send SMS
  final result = await sms.send('96598765432', 'Hello from Dart!');
  print('Result: ${result.result}, Message ID: ${result.msgId}');
}
```

## Setup / Configuration

### Option 1: Environment variables

```bash
export KWTSMS_USERNAME=your_api_user
export KWTSMS_PASSWORD=your_api_pass
export KWTSMS_SENDER_ID=YOUR-SENDERID
export KWTSMS_TEST_MODE=0
export KWTSMS_LOG_FILE=kwtsms.log
```

```dart
final sms = KwtSMS.fromEnv();
```

### Option 2: .env file

Create a `.env` file in your project root:

```ini
KWTSMS_USERNAME=your_api_user
KWTSMS_PASSWORD=your_api_pass
KWTSMS_SENDER_ID=YOUR-SENDERID
KWTSMS_TEST_MODE=1
KWTSMS_LOG_FILE=kwtsms.log
```

```dart
final sms = KwtSMS.fromEnv(); // reads .env automatically
```

### Option 3: Direct constructor

```dart
final sms = KwtSMS(
  'your_api_user',
  'your_api_pass',
  senderId: 'YOUR-SENDERID',
  testMode: true,
  logFile: 'kwtsms.log',
);
```

## All Methods

### verify()

Test credentials and get the current balance.

```dart
final result = await sms.verify();
// VerifyResult(ok: true, balance: 150.0, error: null)

if (result.ok) {
  print('Balance: ${result.balance}');
} else {
  print('Error: ${result.error}');
}
```

### balance()

Get the current SMS credit balance. Returns cached value if the API call fails.

```dart
final bal = await sms.balance();
print('Balance: $bal');

// Cached values (updated after verify/send):
print('Cached balance: ${sms.cachedBalance}');
print('Purchased: ${sms.cachedPurchased}');
```

### send(mobile, message, {sender})

Send SMS to one or more phone numbers. Auto-batches when >200 numbers.

```dart
// Single number
final result = await sms.send('96598765432', 'Your OTP is: 123456');

if (result.result == 'OK') {
  print('Message ID: ${result.msgId}');         // save this!
  print('Points charged: ${result.pointsCharged}');
  print('Balance after: ${result.balanceAfter}'); // save this too!
}

// Multiple numbers (comma-separated)
final result2 = await sms.send(
  '96598765432,96512345678',
  'Hello everyone!',
);

// Override sender ID
final result3 = await sms.send(
  '96598765432',
  'Alert!',
  sender: 'MY-APP',
);
```

**What happens automatically:**
- Phone numbers are normalized (strips +, 00, spaces, dashes, converts Arabic digits)
- Numbers are deduplicated after normalization
- Invalid numbers are collected in `result.invalid` without crashing
- Message text is cleaned (emojis stripped, HTML removed, control chars removed)
- For >200 numbers, splits into batches of 200 with 0.5s delay

### sendBulk(mobiles, message, {sender})

Explicitly send to a list of numbers in batches.

```dart
final numbers = ['96598765432', '96512345678', /* ... hundreds more */];
final result = await sms.sendBulk(numbers, 'Campaign message');

// BulkSendResult
print('Result: ${result.result}');     // OK, PARTIAL, or ERROR
print('Batches: ${result.batches}');
print('Numbers sent: ${result.numbers}');
print('Points charged: ${result.pointsCharged}');
print('Message IDs: ${result.msgIds}');

if (result.errors.isNotEmpty) {
  for (final err in result.errors) {
    print('Batch ${err.batch}: ${err.code} - ${err.description}');
  }
}
```

### validate(phones)

Validate phone numbers with the kwtSMS API.

```dart
final result = await sms.validate(['96598765432', '123', 'test@email.com']);

print('Valid (OK): ${result.ok}');        // routable numbers
print('Format error (ER): ${result.er}'); // format issues
print('No route (NR): ${result.nr}');     // country not activated

// Numbers that failed local validation (never sent to API):
for (final entry in result.rejected) {
  print('${entry.input}: ${entry.error}');
}
```

### senderIds()

List available sender IDs on this account.

```dart
final result = await sms.senderIds();
if (result.result == 'OK') {
  for (final id in result.senderIds) {
    print('Sender ID: $id');
  }
}
```

### coverage()

List active country prefixes for SMS delivery.

```dart
final result = await sms.coverage();
if (result.result == 'OK') {
  for (final prefix in result.prefixes) {
    print('Active prefix: $prefix');
  }
}
```

### status(msgId)

Check delivery status of a sent message.

```dart
final result = await sms.status('f4c841adee210f31307633ceaebff2ec');
if (result.result == 'OK') {
  print('Status: ${result.status}');
  print('Description: ${result.statusDescription}');
}
```

### deliveryReport(msgId)

Get per-number delivery reports (international numbers only, Kuwait numbers do not support DLR).

```dart
final result = await sms.deliveryReport('f4c841adee210f31307633ceaebff2ec');
if (result.result == 'OK') {
  for (final entry in result.report) {
    print('${entry.number}: ${entry.status}');
  }
}
```

## Utility Functions

These are exported publicly and can be used independently.

### normalizePhone(phone)

```dart
normalizePhone('+96598765432');     // '96598765432'
normalizePhone('0096598765432');    // '96598765432'
normalizePhone('965 9876 5432');    // '96598765432'
normalizePhone('965-9876-5432');    // '96598765432'
normalizePhone('\u0669\u0666\u0665...');  // Arabic digits converted
```

### validatePhoneInput(phone)

```dart
final (valid, error, normalized) = validatePhoneInput('96598765432');
// (true, null, '96598765432')

final (v2, e2, n2) = validatePhoneInput('123');
// (false, "'123' is too short (3 digits, minimum is 7)", '123')

final (v3, e3, n3) = validatePhoneInput('user@example.com');
// (false, "'user@example.com' is an email address, not a phone number", '')
```

### cleanMessage(text)

```dart
cleanMessage('Hello \u{1F600}');  // 'Hello ' (emoji stripped)
cleanMessage('<b>Bold</b>');      // 'Bold' (HTML stripped)
cleanMessage('\uFEFFHello');      // 'Hello' (BOM stripped)
cleanMessage('\u0661\u0662\u0663'); // '123' (Arabic digits converted)
```

### enrichError(response)

```dart
final enriched = enrichError({
  'result': 'ERROR',
  'code': 'ERR003',
  'description': 'Authentication error',
});
print(enriched['action']); // Developer-friendly guidance
```

### apiErrors

Read-only map of all 33 error codes to action messages. Useful for building custom error UIs.

```dart
print(apiErrors['ERR003']); // 'Wrong API username or password...'
```

### loadEnvFile([path])

```dart
final vars = loadEnvFile('.env');
print(vars['KWTSMS_USERNAME']);
```

## CLI Usage

Install globally:

```bash
dart pub global activate kwtsms
```

Commands:

```bash
kwtsms setup                                          # interactive wizard
kwtsms verify                                         # test credentials, show balance
kwtsms balance                                        # show available + purchased credits
kwtsms senderid                                       # list sender IDs
kwtsms coverage                                       # list active country prefixes
kwtsms send 96598765432 "Hello from CLI"              # send SMS
kwtsms send 96598765432,96512345678 "Hello everyone"  # multi-number
kwtsms send 96598765432 "Test" --sender MY-APP        # custom sender
kwtsms validate 96598765432 123 test@email.com        # validate numbers
kwtsms status f4c841adee210f31307633ceaebff2ec        # check delivery status
kwtsms dlr f4c841adee210f31307633ceaebff2ec           # delivery report
kwtsms help                                           # show help
kwtsms version                                        # show version
```

## Error Handling

Every API method returns a typed result object. Errors never crash your application.

```dart
final result = await sms.send('96598765432', 'Hello');

if (result.result == 'OK') {
  // Save msg-id and balance-after
  db.save('sms_balance', result.balanceAfter);
  db.save('msg_id', result.msgId);
} else {
  // Error handling
  print('Code: ${result.code}');
  print('Description: ${result.description}');
  print('Action: ${result.action}'); // developer-friendly guidance
}

// Invalid numbers are collected, never crash the call
for (final entry in result.invalid) {
  print('${entry.input}: ${entry.error}');
}
```

### Common Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| ERR003 | Wrong credentials | Check KWTSMS_USERNAME and KWTSMS_PASSWORD |
| ERR006 | No valid phone numbers | Include country code (e.g., 96598765432) |
| ERR008 | Sender ID banned | Use a different sender ID |
| ERR009 | Empty message | Provide a non-empty message |
| ERR010 | Zero balance | Recharge at kwtsms.com |
| ERR011 | Insufficient balance | Buy more credits |
| ERR013 | Queue full | Retried automatically (3x with backoff) |
| ERR024 | IP not whitelisted | Add IP at kwtsms.com > API > IP Lockdown |
| ERR025 | Invalid phone number | Include the country code |
| ERR026 | Country not activated | Contact kwtSMS support |
| ERR028 | 15-second rate limit | Wait before resending to same number |

## Phone Number Formats

| Input | Normalized | Valid? |
|-------|-----------|--------|
| `96598765432` | `96598765432` | Yes |
| `+96598765432` | `96598765432` | Yes (+ stripped) |
| `0096598765432` | `96598765432` | Yes (00 stripped) |
| `965 9876 5432` | `96598765432` | Yes (spaces stripped) |
| `965-9876-5432` | `96598765432` | Yes (dashes stripped) |
| Arabic digits | `96598765432` | Yes (converted to Latin) |
| `123456` | `123456` | No (too short, min 7 digits) |
| `user@example.com` | -- | No (email address) |
| `abcdef` | -- | No (no digits) |

## Test Mode

Set `testMode: true` or `KWTSMS_TEST_MODE=1` to queue messages without delivering them.

```dart
final sms = KwtSMS('user', 'pass', testMode: true);
final result = await sms.send('96598765432', 'Test message');
// Message is queued but NOT delivered. No credits consumed.
```

Test messages appear in the Sending Queue at kwtsms.com. Delete them from the queue to recover any tentatively held credits. Remember to set `testMode: false` before going live.

## Sender ID

`KWT-SMS` is a shared test sender ID. It may cause delays, is blocked on Virgin Kuwait numbers, and must never be used in production.

Register a private sender ID on your kwtSMS account before going live:

| Type | Use for | DND delivery | Cost |
|------|---------|-------------|------|
| **Promotional** | Bulk SMS, marketing, offers | Blocked on DND numbers | 10 KD |
| **Transactional** | OTP, alerts, notifications | Bypasses DND (whitelisted) | 15 KD |

**For OTP/authentication, you MUST use a Transactional Sender ID.** Using Promotional means messages to DND numbers are silently blocked and credits are still deducted.

Sender ID is **case sensitive**: `Kuwait` is not the same as `KUWAIT`.

## For Mobile Apps (Flutter)

### Credential Management

**Backend proxy (strongly recommended):** The mobile app calls YOUR backend server, which holds the kwtSMS credentials and makes the API call. The app never touches the SMS API directly. This is the only pattern that fully protects credentials.

**If calling the API directly (not recommended):** Store credentials using `flutter_secure_storage` and provide a settings screen for entering/updating them. NEVER store credentials in assets, hardcoded strings, or environment files bundled with the app.

### Bot Protection

Mobile apps do not need CAPTCHA. Use device attestation instead:

- **iOS:** Apple App Attest via `DCAppAttestService`
- **Android:** Google Play Integrity API

### Thread Safety

Dart is single-threaded (event loop). No mutex is needed for cached balance in standard use. If using Isolates, create a separate `KwtSMS` instance per Isolate.

## What's Handled Automatically

- Phone number normalization (strips +, 00, spaces, dashes, converts Arabic digits)
- Phone number deduplication after normalization
- Message cleaning (emojis, HTML tags, control characters, Arabic digit conversion)
- Bulk batching (>200 numbers split into batches of 200 with 0.5s delay)
- ERR013 retry with exponential backoff (30s, 60s, 120s)
- Balance caching after verify/send
- JSONL logging with credential masking
- Invalid number collection (never crashes, collects in `.invalid`)
- Error enrichment with developer-friendly action messages

## Security Checklist

Before going live, verify:

```
[ ] Bot protection enabled (Device Attestation for mobile, CAPTCHA for web)
[ ] Rate limit per phone number (max 3-5 OTP/hour)
[ ] Rate limit per IP address (max 10-20/hour)
[ ] Rate limit per user/session if authenticated
[ ] Monitoring/alerting on abuse patterns
[ ] Admin notification on low balance
[ ] Test mode OFF (KWTSMS_TEST_MODE=0)
[ ] Private Sender ID registered (not KWT-SMS)
[ ] Transactional Sender ID for OTP (not promotional)
```

## FAQ

**Why do I get "Wrong username or password"?**
The API uses separate API credentials, not your account mobile number. Check KWTSMS_USERNAME and KWTSMS_PASSWORD. If your password contains special characters (#, &, ?), make sure you are using POST with JSON (this library always does).

**Why is my message not being delivered?**
Check: (1) Is test mode off? (2) Is the message stuck in the queue at kwtsms.com? (3) Are you using `KWT-SMS` sender? Switch to a private sender ID. (4) Does the message contain emojis? This library strips them automatically, but check your message content.

**Why do I get ERR028?**
You must wait at least 15 seconds before sending to the same number again. The entire request is rejected if any number triggers this. For OTP, always send to one number per request.

**Can I use this with Flutter?**
Yes. The library works in both pure Dart (server-side) and Flutter (mobile) contexts. Install with `flutter pub add kwtsms`.

**How do I check if a message was delivered?**
Save the `msg-id` from the send response, then call `sms.status(msgId)`. For international numbers, use `sms.deliveryReport(msgId)` (wait 5+ minutes). Kuwait numbers do not support delivery reports.

## Help & Support

- **[kwtSMS FAQ](https://www.kwtsms.com/faq/)** — Answers to common questions about credits, sender IDs, OTP, and delivery
- **[kwtSMS Support](https://www.kwtsms.com/support.html)** — Open a support ticket or browse help articles
- **[Contact kwtSMS](https://www.kwtsms.com/#contact)** — Reach the kwtSMS team directly for Sender ID registration and account issues
- **[API Documentation (PDF)](https://www.kwtsms.com/doc/KwtSMS.com_API_Documentation_v41.pdf)** — kwtSMS REST API v4.1 full reference
- **[kwtSMS Dashboard](https://www.kwtsms.com/login/)** — Recharge credits, buy Sender IDs, view message logs, manage coverage
- **[Other Integrations](https://www.kwtsms.com/integrations.html)** — Plugins and integrations for other platforms and languages
- **[Library Issues](https://github.com/boxlinknet/kwtsms-dart/issues)** — Report bugs or request features for this Dart client

## License

MIT
