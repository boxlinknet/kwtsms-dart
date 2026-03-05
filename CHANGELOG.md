# Changelog

## [0.1.0] - 2026-03-06

### Added
- Initial release
- KwtSMS client with all API endpoints: send, balance, verify, validate, senderIds, coverage, status, deliveryReport
- Bulk send with automatic batching (>200 numbers)
- Phone number normalization and validation utilities
- Message cleaning (emoji, HTML, control character removal)
- .env file loading
- JSONL logging with credential masking
- CLI tool (kwtsms command)
- Full error code mapping with developer-friendly action messages
- Test mode support
