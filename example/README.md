# Examples

Runnable examples for the kwtsms Dart client library.

## Setup

All examples that send SMS require credentials. Create a `.env` file:

```ini
KWTSMS_USERNAME=your_api_user
KWTSMS_PASSWORD=your_api_pass
KWTSMS_SENDER_ID=KWT-SMS
KWTSMS_TEST_MODE=1
```

## Examples

| # | File | Description | Needs credentials |
|---|------|-------------|-------------------|
| 01 | `01_basic_usage.dart` | Verify credentials, check balance, send SMS, list sender IDs, check coverage | Yes |
| 02 | `02_otp_flow.dart` | OTP generation, validation, and sending to a single number | Yes |
| 03 | `03_bulk_sms.dart` | Bulk SMS to >200 numbers with automatic batching | Yes |
| 04 | `04_shelf_endpoint.dart` | Shelf web server endpoint pattern for SMS sending | Yes (pattern only) |
| 05 | `05_error_handling.dart` | Handle all error cases with user-facing and admin error patterns | Yes |
| 06 | `06_otp_production/` | Production OTP service with rate limiting, hashing, and device attestation | Yes |

## Running

```bash
# Basic usage
KWTSMS_TEST_MODE=1 dart run example/01_basic_usage.dart

# OTP flow
KWTSMS_TEST_MODE=1 dart run example/02_otp_flow.dart

# Bulk SMS
KWTSMS_TEST_MODE=1 dart run example/03_bulk_sms.dart

# Error handling
KWTSMS_TEST_MODE=1 dart run example/05_error_handling.dart

# OTP production (Shelf pattern)
KWTSMS_TEST_MODE=1 dart run example/06_otp_production/usage/shelf_usage.dart
```
