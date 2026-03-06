# Changelog

## [0.1.3] - 2026-03-06

### Fixed
- Remove `doc/` from git tracking (internal PRD, not part of published package)
- Fix README title to proper brand casing: "kwtSMS for Dart"
- Fix FAQ link (was pointing to deprecated faq_all.php)
- Remove WhatsApp number from Help & Support section

## [0.1.2] - 2026-03-06

### Fixed
- Remove `.claude/` from git tracking (internal tool files, not project code)
- Fix clone URL in CONTRIBUTING.md (underscore to dash)
- Sync CLI version string with pubspec.yaml
- Add `.claude/` to .gitignore

## [0.1.1] - 2026-03-06

### Fixed
- CI: relax static analysis to warnings-only (info-level file_names lint on numbered examples)
- CI: bump actions/checkout to v6
- Rename `docs/` to `doc/` per pub.dev layout convention
- Add SECURITY.md
- Configure GitHub Actions OIDC for automated pub.dev publishing

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
