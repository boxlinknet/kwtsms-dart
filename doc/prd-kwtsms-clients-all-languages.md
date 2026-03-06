# PRD: kwtSMS API Client Libraries (All Languages)

**Date:** 2026-03-04
**Updated:** 2026-03-06
**Status:** Active
**Reference implementation:** Python `kwtsms` v0.7.9. Full feature parity required.
**Completed:** JavaScript/TypeScript `kwtsms` v0.2.0, PHP `kwtsms/kwtsms`, Python `kwtsms`, Swift `kwtsms-swift` v0.2.0.

---

## Documentation Writing Rules

Apply these rules to ALL prose in README files, example `.md` files, inline code comments, and this PRD itself:

- **No em dashes or hyphens as sentence separators.** Use commas, colons, or periods instead.
  - Wrong: `Phone numbers are normalized automatically — stripping +, 00, and spaces.`
  - Correct: `Phone numbers are normalized automatically: it strips +, 00, and spaces.`
- **Hyphens are OK in compound words:** `case-sensitive`, `zero-dependency`, `thread-safe`, `built-in`, `well-maintained`.
- **Range en dashes are OK:** `3–5 minutes`, `10–20 requests/hour`, `Node.js 16+`.
- **Em dashes inside code blocks and inline code comments are acceptable.**
- **Do not start sentences with "This" when a more direct subject is available.**
- **Avoid filler phrases:** "In order to", "It is important to note that", "Please note that".

---

## Goal

Create official kwtSMS API client libraries for 8 languages. Each library must:

1. Mirror every feature in the Python `kwtsms` client
2. Never crash on any input. Always return structured errors
3. Include comprehensive tests (unit + mocked API + real integration)
4. Publish to the language's global package registry (or GitHub for languages without one)
5. Include a standalone README with install + usage + publishing instructions
6. Work with the widest range of language versions possible
7. Use minimal or zero external dependencies
8. Handle all edge cases the Python client handles

A developer should go from zero to sending an SMS in under 5 minutes.

---

## Languages & Registries

| # | Language | Registry | Install command | Package name | Status |
|---|----------|----------|-----------------|--------------|--------|
| 1 | **PHP** | Packagist | `composer require kwtsms/kwtsms` | `kwtsms/kwtsms` | Done |
| 2 | **TypeScript/JavaScript** | npm | `npm install kwtsms` | `kwtsms` | Done |
| 3 | **Go** | pkg.go.dev | `go get github.com/boxlinknet/kwtsms-go` | `kwtsms-go` | |
| 4 | **Rust** | crates.io | `cargo add kwtsms` | `kwtsms` | |
| 5 | **Swift** | Swift Package Manager | Add GitHub URL in Xcode or `Package.swift` | `kwtsms-swift` | Done |
| 6 | **Kotlin** | Maven Central / JitPack | `implementation("com.kwtsms:kwtsms:0.1.0")` | `kwtsms` | |
| 7 | **Dart/Flutter** | pub.dev | `dart pub add kwtsms` | `kwtsms` | |
| 8 | **Zig** | GitHub (zon) | Add dependency in `build.zig.zon` | `kwtsms-zig` | |

---

## Feature Parity Checklist

Every client library MUST implement all of the following. No exceptions.

### Core methods

| # | Method | Python signature | Returns |
|---|--------|-----------------|---------|
| 1 | Constructor | `KwtSMS(username, password, sender_id="KWT-SMS", test_mode=False, log_file="kwtsms.log")` | client instance |
| 2 | Factory | `KwtSMS.from_env(env_file=".env")` | client instance (loads from env vars → .env fallback) |
| 3 | Verify | `verify()` | `(ok: bool, balance: float, error: str)`, never raises |
| 4 | Balance | `balance()` | `float` or `None`, also stores `purchased` internally |
| 5 | Send | `send(mobile, message, sender=None)` | dict with `result`, `code`, `description`, `action` |
| 6 | Validate | `validate(phones[])` | dict with `ok`, `er`, `nr`, `rejected`, `error`, `raw` |
| 7 | Sender IDs | `senderids()` | dict with `result`, `senderids[]`, or error dict |
| 8 | Coverage | `coverage()` | dict with `result`, `prefixes[]`, or error dict |

### Utility functions (exported publicly)

| # | Function | Behaviour |
|---|----------|-----------|
| 1 | `normalize_phone(phone)` | Convert Arabic digits to Latin, strip all non-digits, strip leading zeros |
| 2 | `validate_phone_input(phone)` | Returns `(valid, error, normalized)`, catches email, empty, too short <7, too long >15, no digits |
| 3 | `clean_message(text)` | Strip emojis, hidden control chars (BOM, zero-width space, soft hyphen, directional marks, C0/C1), HTML tags; convert Arabic digits |

### Additional public exports

These must also be exported publicly for callers who want to use them directly:

| # | Export | Purpose |
|---|--------|---------|
| 1 | `API_ERRORS` | The complete error code map (read-only dict/const). Useful for building custom error UIs. |
| 2 | `enrich_error()` | Adds an `action` field to any API response dict. Useful for callers doing their own HTTP requests. |
| 3 | `InvalidEntry` / equivalent type | The structured type for numbers that failed local pre-validation. `{ input: string, error: string }`. |
| 4 | `SendResult`, `BulkSendResult`, `ValidateResult` | Return types for typed languages (TypeScript, Swift, Kotlin, Rust, Go). Export all public return types. |

### Bulk send (>200 numbers)

- Auto-detect when numbers > 200, split into batches of 200
- 0.5s delay between batches (≤2 req/s)
- ERR013 (queue full): retry up to 3× with backoff at 30s / 60s / 120s
- Return aggregated result: `result` = `"OK"` | `"PARTIAL"` | `"ERROR"`, `batches`, `msg-ids[]`, `numbers`, `points-charged`, `balance-after`, `errors[]`

### API error enrichment

Map ALL 33 kwtSMS error codes to developer-friendly `action` messages. Every ERROR response MUST include:

```
{
    "result":      "ERROR",
    "code":        "ERR003",
    "description": "Authentication error...",        // from the API
    "action":      "Check KWTSMS_USERNAME and..."    // from our error table
}
```

Full error code table to include:

| Code | Action message |
|------|---------------|
| ERR001 | API is disabled on this account. Enable it at kwtsms.com → Account → API. |
| ERR002 | A required parameter is missing. Check that username, password, sender, mobile, and message are all provided. |
| ERR003 | Wrong API username or password. Check KWTSMS_USERNAME and KWTSMS_PASSWORD. These are your API credentials, not your account mobile number. |
| ERR004 | This account does not have API access. Contact kwtSMS support to enable it. |
| ERR005 | This account is blocked. Contact kwtSMS support. |
| ERR006 | No valid phone numbers. Make sure each number includes the country code (e.g., 96598765432 for Kuwait, not 98765432). |
| ERR007 | Too many numbers in a single request (maximum 200). Split into smaller batches. |
| ERR008 | This sender ID is banned. Use a different sender ID registered on your kwtSMS account. |
| ERR009 | Message is empty. Provide a non-empty message text. |
| ERR010 | Account balance is zero. Recharge credits at kwtsms.com. |
| ERR011 | Insufficient balance for this send. Buy more credits at kwtsms.com. |
| ERR012 | Message is too long (over 6 SMS pages). Shorten your message. |
| ERR013 | Send queue is full (1000 messages). Wait a moment and try again. |
| ERR019 | No delivery reports found for this message. |
| ERR020 | Message ID does not exist. Make sure you saved the msg-id from the send response. |
| ERR021 | No delivery report available for this message yet. |
| ERR022 | Delivery reports are not ready yet. Try again after 24 hours. |
| ERR023 | Unknown delivery report error. Contact kwtSMS support. |
| ERR024 | Your IP address is not in the API whitelist. Add it at kwtsms.com → Account → API → IP Lockdown, or disable IP lockdown. |
| ERR025 | Invalid phone number. Make sure the number includes the country code (e.g., 96598765432 for Kuwait, not 98765432). |
| ERR026 | This country is not activated on your account. Contact kwtSMS support to enable the destination country. |
| ERR027 | HTML tags are not allowed in the message. Remove any HTML content and try again. |
| ERR028 | You must wait at least 15 seconds before sending to the same number again. No credits were consumed. |
| ERR029 | Message ID does not exist or is incorrect. |
| ERR030 | Message is stuck in the send queue with an error. Delete it at kwtsms.com → Queue to recover credits. |
| ERR031 | Message rejected: bad language detected. |
| ERR032 | Message rejected: spam detected. |
| ERR033 | No active coverage found. Contact kwtSMS support. |
| ERR_INVALID_INPUT | One or more phone numbers are invalid. See details above. |

### Input validation

`send()` and `validate()` must run `validate_phone_input()` on every number BEFORE calling the API. Invalid numbers are:
- Collected into an `invalid` / `rejected` array with per-number error messages
- Never sent to the API
- Never crash the call. Valid numbers still get sent

Validation rules:
- Empty / blank → `"Phone number is required"`
- Contains `@` → `"'...' is an email address, not a phone number"`
- No digits after normalization → `"'...' is not a valid phone number, no digits found"`
- Less than 7 digits → `"'...' is too short (N digits, minimum is 7)"`
- More than 15 digits → `"'...' is too long (N digits, maximum is 15)"`

### JSONL logging

One JSON line per API call. Fields: `ts` (UTC ISO-8601), `endpoint`, `request` (password masked as `***`), `response`, `ok`, `error`. Logging MUST never crash the main flow.

### .env file support

Load credentials from env vars first, then `.env` file as fallback:

```ini
KWTSMS_USERNAME=your_api_user
KWTSMS_PASSWORD=your_api_pass
KWTSMS_SENDER_ID=YOUR-SENDERID
KWTSMS_TEST_MODE=1
KWTSMS_LOG_FILE=kwtsms.log
```

**`.env` parsing requirements:**
- Strip inline `# comments` from unquoted values: `KWTSMS_SENDER_ID=MY-APP  # set to your ID` → `MY-APP`
- Ignore blank lines and lines starting with `#`
- Return empty dict/map for missing files (never throw/panic)
- Do NOT modify `process.env` or the system environment (read-only parsing)
- Support quoted values: `KWTSMS_SENDER_ID="MY APP"` → `MY APP`

**Integration test `.env` (language-prefixed, for multi-language development):**

```ini
# Use language-prefixed names to avoid conflicts when testing multiple clients
JS_USERNAME=your_api_user
JS_PASSWORD=your_api_pass
PHP_USERNAME=your_api_user
PHP_PASSWORD=your_api_pass
# ... etc. for each language being tested
```

### CLI (where applicable)

Languages where a CLI is idiomatic should register a `kwtsms` command:

```
kwtsms setup                                          # interactive wizard
kwtsms verify                                         # test credentials, show balance + purchased
kwtsms balance                                        # show available + purchased credits
kwtsms senderid                                       # list sender IDs
kwtsms coverage                                       # list active country prefixes
kwtsms send <mobile> <message> [--sender SENDER_ID]   # send SMS
kwtsms send <m1>,<m2> <message> [--sender "NAME"]     # multi-number
kwtsms validate <number> [number2 ...]                 # validate numbers
```

CLI requirements:
- Never show a traceback/stack trace. Always a clean error message
- `--sender` flag supports spaces when quoted: `--sender "kwt sms"`
- Multiple numbers as comma-separated string
- Test mode prints a visible warning before sending
- Errors print `action` guidance

---

## Security & Input Sanitization

### Credentials

- NEVER hardcode credentials in source code, in ANY language, on ANY platform
- Always load from environment variables, `.env` file, remote config, or a user-editable admin/settings UI
- Credentials must be changeable WITHOUT recompiling, redeploying, or rebuilding the application
- `from_env()` must be the primary/default way to create a client
- Constructor must accept credentials as parameters for users who have their own config system
- Password must be masked as `***` in ALL logs, no exceptions
- Never expose API credentials, phone numbers, or message content in client-facing error messages

### HTTP

- Always POST, never GET (GET logs credentials in server logs even with HTTPS)
- Always set `Content-Type: application/json` and `Accept: application/json`
- Read HTTP 4xx/5xx response bodies. kwtSMS returns JSON error details in the body of 403 responses
- Set reasonable timeouts (15 seconds)

### Input: Phone Number Sanitization

- `trim()` whitespace (leading and trailing) before any other processing
- Convert Arabic-Indic (U+0660–U+0669) and Extended Arabic-Indic / Persian (U+06F0–U+06F9) digits to Latin (0–9)
- Strip ALL non-digit characters without exception: `+`, spaces, dashes, dots, parentheses, slashes, brackets
- Strip leading zeros (handles `00` country code prefix and regional dialing habits)
- Validate length (7–15 digits) and structure before submission
- Reject email addresses, empty strings, non-numeric input, with clear error messages per entry
- Never pass raw user input directly to the API
- **Deduplicate normalized numbers before sending.** If the caller passes `+96598765432` and `0096598765432`, they normalize to the same number. Send it only once. Report the deduplicated list in the response.
- Never crash on non-string input: coerce to string with `String(value)` before processing

### Input: Message Cleaning (REQUIRED before every send)

Three categories of content cause silent delivery failure (API returns OK, but message is stuck in queue and never delivered, credits wasted):

| Content | Effect | Fix |
|---------|--------|-----|
| **Emojis** | Stuck in queue indefinitely, credits wasted, no error returned | Strip before send |
| **Hidden control characters** (zero-width space, BOM, soft hyphen, etc.) | Spam filter rejection or queue stuck, introduced by copy-pasting from Word/PDF/rich editors | Strip before send |
| **Arabic/Hindi numerals in body** (`١٢٣٤`) | OTP codes and amounts may render inconsistently | Convert to Latin digits |
| **HTML tags** | ERR027, message rejected | Strip before send |

Every client library's `send()` method MUST call `clean_message()` internally before every API call. This is not optional. It prevents the #1 cause of "message sent but not received" support tickets.

`clean_message()` must:

1. **Convert Arabic-Indic and Extended Arabic-Indic digits to Latin.** U+0660–U+0669 (Arabic-Indic: ٠١٢٣٤٥٦٧٨٩) and U+06F0–U+06F9 (Extended Arabic-Indic / Persian: ۰۱۲۳۴۵۶۷۸۹).

2. **Remove emojis.** Use code point iteration (not UTF-16 char-by-char) to handle surrogate pairs safely. In JavaScript use `Array.from()` before iterating. Remove all code points in these ranges:
   - U+1F000–U+1F02F (Mahjong, domino tiles)
   - U+1F0A0–U+1F0FF (Playing cards)
   - U+1F1E0–U+1F1FF (Regional indicator symbols / flag components)
   - U+1F300–U+1F5FF (Misc symbols and pictographs)
   - U+1F600–U+1F64F (Emoticons)
   - U+1F680–U+1F6FF (Transport and map)
   - U+1F700–U+1F77F (Alchemical symbols)
   - U+1F780–U+1F7FF (Geometric shapes extended)
   - U+1F800–U+1F8FF (Supplemental arrows)
   - U+1F900–U+1F9FF (Supplemental symbols and pictographs)
   - U+1FA00–U+1FA6F (Chess symbols)
   - U+1FA70–U+1FAFF (Symbols and pictographs extended)
   - U+2600–U+26FF (Misc symbols)
   - U+2700–U+27BF (Dingbats)
   - U+FE00–U+FE0F (Variation selectors — emoji style modifiers)
   - U+20E3 (Combining enclosing keycap — used in keycap emoji sequences)
   - U+E0000–U+E007F (Tags block — used in subdivision flag sequences)

3. **Remove hidden invisible characters** that trigger spam filters or cause messages to get stuck in the queue:
   - U+200B (Zero-width space)
   - U+200C (Zero-width non-joiner)
   - U+200D (Zero-width joiner)
   - U+2060 (Word joiner)
   - U+00AD (Soft hyphen)
   - U+FEFF (Byte order mark / BOM)
   - U+FFFC (Object replacement character)

4. **Remove directional formatting characters** (bidirectional text control codes introduced by rich-text editors and some RTL-aware apps):
   - U+200E (Left-to-right mark)
   - U+200F (Right-to-left mark)
   - U+202A–U+202E (Directional formatting: LRE, RLE, PDF, LRO, RLO)
   - U+2066–U+2069 (Directional isolates: LRI, RLI, FSI, PDI)

5. **Remove C0 and C1 control characters** (unprintable binary control codes introduced by copy-pasting from terminals or binary content), but preserve `\n` (U+000A) and `\t` (U+0009):
   - U+0000–U+001F (C0 controls, except U+0009 TAB and U+000A LF)
   - U+007F (DEL)
   - U+0080–U+009F (C1 controls)

6. **Strip HTML tags** after character-level processing. Use a regex like `/<[^>]*>/g`. This handles ERR027.

7. **Post-clean empty message check.** After all cleaning, if the result is empty or whitespace-only (e.g., the original message contained only emojis), return an ERR009-equivalent error immediately. Do NOT send an empty message to the API.

8. **Arabic letters and Arabic text must NOT be stripped.** Arabic text is fully supported by kwtSMS. Only digits (converted), invisible chars, emojis, control chars, and HTML are affected.

---

## Credential Management (ALL platforms, not just mobile)

**This applies to ALL applications**: web backends, mobile apps, CLIs, desktop apps, serverless functions. Credentials must NEVER be hardcoded and must be changeable without code changes.

### For ALL applications

Every integrating application MUST provide an **admin settings UI or configuration mechanism** where API credentials can be viewed, updated, and tested without touching code:

1. **Environment variables / .env file** (server-side default): Load credentials from env vars or a `.env` file. The file is `.gitignore`d and editable without redeployment. The client library's `from_env()` method handles this automatically.

2. **Admin settings UI** (recommended for web apps, CMS plugins, SaaS): Provide a settings page where an admin can enter/update API username, password, sender ID, and toggle test mode. Store in the application's database or config store. Include a "Test Connection" button that calls `verify()` and shows the result.

3. **Remote config / secrets manager** (recommended for production): Load credentials from AWS Secrets Manager, Google Secret Manager, HashiCorp Vault, Firebase Remote Config, or your own config API. Credentials rotate without redeployment.

4. **Constructor injection** (for developers with their own config system): The client constructor accepts all credentials as parameters. Works with any config source (DI containers, custom config, etc.).

### Additional requirements for mobile apps (Swift/Kotlin/Dart-Flutter)

Mobile apps have extra constraints. The compiled binary can be reverse-engineered:

- **Backend proxy** (strongly recommended): The mobile app calls YOUR backend server, which holds the kwtSMS credentials and makes the API call. The app never touches the SMS API directly. This is the only pattern that fully protects credentials.
- **Secure storage**: If calling the API directly (not recommended), store credentials in the OS keychain (iOS Keychain / Android EncryptedSharedPreferences / Flutter `flutter_secure_storage`) and provide a settings screen for entering/updating them.
- **NEVER** compile credentials into the binary, store in `Info.plist`, `strings.xml`, `BuildConfig` fields, asset bundles, or any resource file that ships with the app.
- **Build-time config** (last resort): Use environment variables during build that inject into a gitignored config file. Credentials are still compiled in, requires a new build to change. Use only if backend proxy is not feasible.

### README documentation requirement

Every language README must include a **"Credential Management"** section explaining these patterns with code examples. The documentation must make it clear that hardcoding credentials is unacceptable and show the recommended alternatives for that language's ecosystem.

---

## Testing Requirements

Every client must have 3 tiers of tests:

### Tier 1: Unit tests (no network)

Test pure functions. Always run, always pass, no credentials needed:

- `normalize_phone()`: all format variations: +prefix, 00prefix, spaces, dashes, Arabic digits, empty string
- `validate_phone_input()`: email, empty, blank, too short, too long, no digits, minimum valid (7 digits), maximum valid (15 digits), Arabic digits
- `clean_message()`: emoji stripped, Arabic digits converted, HTML stripped, BOM/zero-width stripped, Arabic letters preserved, newlines preserved

### Tier 2: Mocked API tests (no network)

Mock the HTTP request function and simulate API responses:

- ERR003 (wrong credentials): verify returns error, send returns error dict with action
- ERR026 (country not allowed): send returns error with action mentioning country
- ERR025 (invalid number): send returns error with action
- ERR010 (zero balance): send returns error with action mentioning kwtsms.com
- ERR024 (IP not whitelisted): send returns error with action mentioning IP
- ERR028 (15 second rate limit): send returns error with action
- ERR008 (banned sender ID): send returns error with action
- ERR999 (unknown error code): does not crash, returns description without action
- Network error: returns clean error, never crashes

### Tier 3: Real integration tests (hit live API)

Skip if no credentials are configured. Use `test_mode=True` always.

- Valid credentials → verify succeeds, balance is a number
- Wrong credentials → verify fails with auth error message
- Send to valid Kuwait number → result is OK or expected ERROR
- Send to invalid input (email, too short, letters) → result is ERROR with code
- Mixed valid+invalid numbers → valid sent, invalid reported in `invalid` field
- Number normalization works end-to-end (+ prefix, 00 prefix, Arabic digits)
- Duplicate normalized numbers → deduplicated before send, sent only once
- senderids() returns a list
- coverage() returns prefixes
- Empty sender ID → API rejects or falls back
- Wrong sender ID → API returns error with action

#### Integration test credential naming

Integration tests must use **language-prefixed environment variable names** for credentials. This allows developers to run tests for multiple language clients on the same machine simultaneously without credential conflicts.

| Language | Test env vars |
|----------|--------------|
| JavaScript / TypeScript | `JS_USERNAME`, `JS_PASSWORD` |
| PHP | `PHP_USERNAME`, `PHP_PASSWORD` |
| Go | `GO_USERNAME`, `GO_PASSWORD` |
| Rust | `RUST_USERNAME`, `RUST_PASSWORD` |
| Swift | `SWIFT_USERNAME`, `SWIFT_PASSWORD` |
| Kotlin | `KOTLIN_USERNAME`, `KOTLIN_PASSWORD` |
| Dart / Flutter | `DART_USERNAME`, `DART_PASSWORD` |
| Zig | `ZIG_USERNAME`, `ZIG_PASSWORD` |

Integration tests must:
1. Read the language-prefixed credentials (e.g., `JS_USERNAME`) from the environment
2. Skip the test (do not fail) if the variable is absent or empty
3. Pass credentials directly to the constructor. Do NOT use `from_env()` in tests (it reads `KWTSMS_USERNAME` which is the runtime env var, not the test env var)
4. Always pass `test_mode=True` / `testMode: true` — no credits consumed

Example (JavaScript):
```typescript
const username = process.env.JS_USERNAME;
const password = process.env.JS_PASSWORD;
if (!username || !password) { test.skip('JS_USERNAME / JS_PASSWORD not set'); }
const sms = new KwtSMS(username, password, { testMode: true });
```

Example (Python):
```python
username = os.getenv('PY_USERNAME')
password = os.getenv('PY_PASSWORD')
if not username or not password:
    pytest.skip('PY_USERNAME / PY_PASSWORD not set')
sms = KwtSMS(username, password, test_mode=True)
```

The runtime library itself still reads `KWTSMS_USERNAME` / `KWTSMS_PASSWORD` via `from_env()`. Only tests use language-prefixed names.

---

## Best Practices (library internals)

These are requirements for the client library code itself.

### 1. Idempotent msg-id tracking

Every `send()` response includes a `msg-id`. The README must emphasize:
> **Always save `msg-id` immediately after a successful send.** You need it for status checks and delivery reports. If you don't store it at send time, you cannot retrieve it later.

### 2. Balance tracking without extra API calls

Every `send()` response includes `balance-after`. The README must emphasize:
> **Never call `balance()` after `send()`.** The send response already includes your updated balance. Save `balance-after` to your database. This eliminates unnecessary API calls.

The client must cache the balance internally and expose it as a read-only accessor:
- `cachedBalance` / `cached_balance`: available balance from the last `verify()` or successful `send()` call
- `cachedPurchased` / `cached_purchased`: total purchased credits from the last `verify()` call
- `balance()` returns the live balance on success, or the cached value if the API call fails (and logs that the value may be stale). Returns null/None if no cached value exists.

### 3. Timezone awareness

> **`unix-timestamp` in API responses is GMT+3 (Asia/Kuwait server time), NOT UTC.** Always convert when storing or displaying timestamps. Log `ts` fields written by this client are always UTC.

### 4. Rate limiting (API level)

> You must wait at least **15 seconds** before sending to the same number again (ERR028). The entire request is rejected if any number in the batch triggers this, even if other numbers are fine.

### 5. Thread safety

For languages with concurrency (Go, Rust, Kotlin, Swift):
- The client instance must be safe to share across threads/goroutines/tasks
- Internal state (cached balance) must use appropriate synchronization

### 6. Retry logic

ERR013 (queue full) is the only error that should be automatically retried. All other errors should be returned immediately. Never retry auth errors, invalid input, or balance errors.

### 7. Graceful degradation

- If logging fails (disk full, permission denied), the main send/verify/etc. flow must continue. Logging must never block or crash the API call
- If .env file doesn't exist, fall back to environment variables silently. No warning needed

---

## Implementation Best Practices (for developers integrating the library)

> Reference: [kwtSMS SMS API Implementation Best Practices](https://www.kwtsms.com/articles/sms-api-implementation-best-practices.html)

Every README must include a **"Best Practices"** section covering the following. These are not optional. They prevent wasted API calls, wasted credits, security breaches, and poor user experience.

### 1. Validate BEFORE calling the API: prevent meaningless API hits

**The #1 cause of wasted API calls is lazy implementations that send everything to the API and let it reject.** Every input must be validated locally BEFORE making any network request:

| Check | When | Why |
|-------|------|-----|
| **Country code is active** | Before `send()` | Call `coverage()` once at startup, cache the active prefixes. If the number's country prefix is not in the list, return an error immediately. Do NOT hit the API. "This country is not active on your account. Contact kwtSMS support to enable it." |
| **Phone number format** | Before `send()` and `validate()` | Run `validate_phone_input()` locally. Reject email addresses, too-short/too-long numbers, non-numeric input. Never send obviously invalid input to the API. |
| **Message is not empty** | Before `send()` | Check locally. Don't waste an API call to get ERR009. |
| **Message length** | Before `send()` | Calculate SMS page count locally. Reject if >6 pages (ERR012). Warn the user about multi-page cost. |
| **Balance is sufficient** | Before `send()` | If you have a cached `balance-after` from a previous send, check it locally. If balance is 0 or less than the estimated cost, show an error immediately. |
| **Sender ID is valid** | Before `send()` | If you have cached sender IDs from `senderids()`, verify the sender exists. Reject unknown sender IDs locally. |

**Example implementation pattern:**

```python
# BAD: lazy, wastes API calls on every invalid input
result = sms.send(user_input_phone, user_input_message)
# The API rejects it with ERR006/ERR009/ERR025/ERR026, a wasted round-trip

# GOOD: validate locally first, only hit API with clean input
valid, error, normalized = validate_phone_input(user_input_phone)
if not valid:
    return {"error": error}  # "Phone number is too short (3 digits, minimum is 7)"

if not is_country_active(normalized, cached_prefixes):
    return {"error": "This country is not active on your account."}

message = clean_message(user_input_message)
if not message.strip():
    return {"error": "Message is empty after cleaning."}

result = sms.send(normalized, message)  # only valid, clean input reaches the API
```

### 2. User-facing error messages: never expose raw API errors

The developer integrating this library is building an app for end users (customers, employees, etc.). Raw API errors like "ERR006" or "ERR025" are meaningless to end users. The README must include a recommended mapping:

| Situation | Raw API error | User-facing message |
|-----------|--------------|---------------------|
| Invalid phone number | ERR006, ERR025 | "Please enter a valid phone number in international format (e.g., +965 9876 5432)." |
| Wrong credentials | ERR003 | "SMS service is temporarily unavailable. Please try again later." (do NOT tell users about auth errors. Log it and alert the admin) |
| No balance | ERR010, ERR011 | "SMS service is temporarily unavailable. Please try again later." (alert the admin to top up) |
| Country not supported | ERR026 | "SMS delivery to this country is not available. Please contact support." |
| Rate limited | ERR028 | "Please wait a moment before requesting another code." |
| Message rejected | ERR031, ERR032 | "Your message could not be sent. Please try again with different content." |
| Network error | connection timeout | "Could not connect to SMS service. Please check your internet connection and try again." |
| Queue full | ERR013 | "SMS service is busy. Please try again in a few minutes." (library retries automatically) |

**Key principle:** API errors split into two categories:
- **User-recoverable** (bad phone, rate limited) → show a helpful message to the user
- **System-level** (auth, balance, network) → show a generic message to the user + log the real error + alert the admin

### 3. Anti-abuse: Rate limiting and bot detection (REQUIRED before launch)

Without rate limiting, a bot can drain your entire SMS balance in minutes. These protections are **mandatory** before any production deployment:

#### Bot detection (CAPTCHA for web, Device Attestation for mobile)

- **Web apps: CAPTCHA is required** on ALL forms that trigger SMS sends (OTP request, signup, password reset, contact forms)
  - Implement before the SMS send logic. If CAPTCHA fails, never call the API
  - Options: Cloudflare Turnstile (free, recommended), hCaptcha (GDPR-safe), reCAPTCHA v3 (invisible)
- **iOS apps: Apple App Attest** (replaces CAPTCHA). Proves requests come from a genuine app installation on a real device, blocks scripts/bots/modified binaries. See `DeviceAttestVerifier` protocol in Swift library.
- **Android apps: Google Play Integrity API** (replaces SafetyNet). Verifies app genuineness and device integrity. See `DeviceAttestVerifier` protocol pattern.
- **Auth token validation (optional):** For 2FA flows where the user is already partially authenticated, require a valid JWT/session token before allowing OTP operations. See `TokenAuthenticator` protocol pattern.

#### Rate limiting per phone number

- Maximum **3–5 OTP/SMS requests per phone number per hour**
- Track by normalized phone number (not raw input, prevent bypass via formatting)
- Return a clear message: "Too many requests to this number. Please try again in X minutes."
- Implementation: in-memory counter (Redis, Memcached) or database counter with TTL

#### Rate limiting per IP address

- Maximum **10–20 SMS requests per IP per hour** (adjust based on your use case)
- Use rolling time windows, not fixed windows (prevents burst attacks at window boundaries)
- Behind load balancers: use `X-Forwarded-For` header (validate it)
- Return: "Too many requests. Please try again later."

#### Rate limiting per user/session

- If the user is authenticated, limit per user ID in addition to per IP
- Maximum **3–5 OTP requests per user per hour**
- Prevents abuse from authenticated accounts

#### Abuse monitoring

- Log and alert on:
  - Sudden spikes in SMS sends from a single IP or phone number
  - High error rates (especially ERR006, indicates automated probing)
  - Rapid balance depletion
- Consider auto-blocking IPs that exceed thresholds by 10x

**README must include a "Security Checklist" box:**

```
BEFORE GOING LIVE:
[ ] Bot protection enabled (CAPTCHA for web, Device Attestation for mobile apps)
[ ] Rate limit per phone number (max 3-5/hour)
[ ] Rate limit per IP address (max 10-20/hour)
[ ] Rate limit per user/session if authenticated
[ ] Monitoring/alerting on abuse patterns
[ ] Admin notification on low balance
[ ] Test mode OFF (KWTSMS_TEST_MODE=0)
[ ] Private Sender ID registered (not KWT-SMS)
[ ] Transactional Sender ID for OTP (not promotional)
```

### 4. OTP implementation requirements

- **Always include app/company name** in the OTP message: `"Your OTP for APPNAME is: 123456"`, telecom compliance requirement
- **Resend timer:** minimum 3–4 minutes before allowing resend (KNET standard is 4 minutes)
- **OTP expiry:** 3–5 minutes is standard. Reject expired codes
- **New code on resend:** always generate a fresh code and invalidate all previous codes for that number
- **Use Transactional Sender ID** for OTP. Promotional sender IDs are filtered by DND (Do Not Disturb) on Zain and Ooredoo, meaning OTP messages silently fail to deliver and credits are still deducted
- **One number per OTP request:** never batch OTP sends. Send to a single number per API call to avoid ERR028 (15-second rate limit) rejecting the entire batch

### 5. Sender ID: do not skip this

| | Promotional | Transactional |
|--|-------------|---------------|
| **Use for** | Bulk SMS, marketing, offers, announcements | OTP, alerts, notifications, reminders |
| **Delivery to DND numbers** | Blocked/filtered, credits lost | Bypasses DND (whitelisted like banks) |
| **Speed** | May have delays | Priority delivery |
| **Cost** | 10 KD one-time | 15 KD one-time |

- `KWT-SMS` is a shared test sender: delays, blocked on Virgin Kuwait, **never use in production**
- Sender ID is **case sensitive**: `Kuwait` ≠ `KUWAIT` ≠ `kuwait`
- Registration takes ~5 working days (Kuwait), 1–2 months (international)
- **For OTP/authentication, you MUST use Transactional**. Using Promotional means messages to DND numbers are silently blocked and credits are still deducted

### 6. Country coverage pre-check

Call `coverage()` once at application startup and cache the list of active country prefixes. Before every send, extract the country prefix from the phone number and check it against the cached list. If the country is not active:
- Do NOT call the API (saves a wasted round-trip)
- Return a clear error: "SMS delivery to [country] is not available on this account. Contact kwtSMS support to enable it."
- Log the attempt for the admin to review

### 7. Balance monitoring

- Save `balance-after` from every successful send response to your database/cache
- Set up low-balance alerts (e.g., when balance drops below 50 credits)
- Use kwtSMS account low-balance email notifications as a safety net (configure at kwtsms.com)
- Before bulk sends, estimate credit cost (number of recipients × pages per message) and warn if balance is insufficient

### 8. Monitoring and alerting

Set up alerts for:
- **Failed sends**: sudden increase in error responses
- **Balance depletion**: rapid decrease or approaching zero
- **Delivery latency**: messages taking longer than expected
- **Error rate spikes**: especially ERR003 (credential issues), ERR010/ERR011 (balance), ERR028 (rate limit)
- **Queue buildup**: messages stuck in kwtSMS queue (check via dashboard)

### 9. Keep libraries updated

- Monitor for security patches and updates to the kwtSMS client library
- Subscribe to kwtSMS announcements for API changes
- Test with the latest library version before deploying updates

### 10. Compliance

- Stay informed about local telecom regulations regarding sender IDs, message content, and user consent
- Promotional SMS may require opt-in consent from recipients
- Different countries have different rules. Check before enabling international coverage
- Transactional messages (OTP, alerts) generally do not require opt-in but must be legitimate

---

## Per-Language Details

---

### 1. PHP → Packagist

**Registry:** https://packagist.org/packages/kwtsms/kwtsms
**Repo:** `github.com/boxlinknet/kwtsms-php`
**Install:** `composer require kwtsms/kwtsms`
**Min version:** PHP 7.4+ (still widely deployed on shared hosting; use `?type` union syntax only in docblocks)
**Dependencies:** Zero. Use PHP built-in `curl` extension and `json_encode`/`json_decode`
**CLI:** No (not idiomatic for Composer packages)
**Test runner:** PHPUnit

**Project structure:**
```
kwtsms-php/
├── composer.json
├── README.md
├── CHANGELOG.md                  ← Keep a Changelog format
├── CONTRIBUTING.md               ← dev setup, branch naming, PR checklist
├── LICENSE
├── .gitignore
├── .github/
│   └── workflows/
│       └── publish.yml           ← GitHub Actions: test + publish on tag
├── src/
│   ├── KwtSMS.php                ← main client class
│   ├── PhoneUtils.php            ← normalize_phone(), validate_phone_input()
│   ├── MessageUtils.php          ← clean_message()
│   └── ApiErrors.php             ← error code → action message mapping
├── tests/
│   ├── PhoneUtilsTest.php
│   ├── MessageUtilsTest.php
│   ├── ApiErrorsTest.php         ← mocked API responses
│   └── IntegrationTest.php       ← real API, skipped without PHP_USERNAME
└── examples/
    ├── README.md                 ← index of all examples
    ├── 01-basic-usage.php
    ├── 01-basic-usage.md
    ├── 02-otp-flow.php
    ├── 02-otp-flow.md
    ├── 03-bulk-sms.php
    ├── 03-bulk-sms.md
    ├── 04-laravel-endpoint.php
    ├── 04-laravel-endpoint.md
    ├── 05-error-handling.php
    └── 05-error-handling.md
```

**Namespace:** `KwtSMS`
**Autoloading:** PSR-4 in `composer.json`:
```json
{
    "autoload": {
        "psr-4": { "KwtSMS\\": "src/" }
    }
}
```

**PHP-specific considerations:**
- `curl_setopt` with `CURLOPT_POSTFIELDS` for JSON body, `CURLOPT_HTTPHEADER` for Content-Type/Accept
- Read HTTP error response bodies: `curl_exec` returns the body even on 4xx if `CURLOPT_FAILONERROR` is NOT set (leave it off)
- `.env` loading: parse file manually (no `vlucas/phpdotenv` dependency)
- Return associative arrays (not objects) for API responses, idiomatic PHP
- Use `mb_` string functions for Unicode handling

**Publishing to Packagist:**
```
1. Push code to github.com/boxlinknet/kwtsms-php
2. Go to https://packagist.org/packages/submit
3. Enter the GitHub repo URL
4. Packagist validates and registers the package
5. Set up GitHub webhook for auto-updates:
   Packagist → Profile → Show API Token
   GitHub → Repo Settings → Webhooks → Add:
     URL: https://packagist.org/api/github?username=YOUR_PACKAGIST_USER
     Content type: application/json
     Secret: your Packagist API token
6. Tag releases on GitHub:
   git tag v0.1.0 && git push origin v0.1.0
   Packagist picks up the tag automatically
```

---

### 2. TypeScript/JavaScript → npm

**Registry:** https://npmjs.com/package/kwtsms
**Repo:** `github.com/boxlinknet/kwtsms-js`
**Install:** `npm install kwtsms` / `yarn add kwtsms` / `pnpm add kwtsms` / `bun add kwtsms`
**Min version:** Node.js 16+ (oldest maintained LTS as of 2025; still widely deployed)
**Dependencies:** Zero. Use Node.js built-in `https` module
**CLI:** Yes. Register `kwtsms` command via `"bin"` in `package.json`
**Test runner:** Node.js built-in `node:test` (no Jest needed)

**Recommendation: Write in TypeScript, ship JavaScript + type declarations.**
- TypeScript users get full type safety and autocomplete
- JavaScript users `require('kwtsms')` and it works. Types are optional
- No runtime overhead. Types are stripped at compile time
- This is the industry standard for npm libraries

**Project structure:**
```
kwtsms-js/
├── package.json
├── tsconfig.json
├── README.md
├── CHANGELOG.md                  ← Keep a Changelog format
├── CONTRIBUTING.md               ← dev setup, branch naming, PR checklist
├── LICENSE
├── .gitignore
├── .github/
│   └── workflows/
│       └── publish.yml           ← GitHub Actions: test + publish on npm tag
├── src/
│   ├── index.ts              ← public exports (KwtSMS, normalizePhone, validatePhoneInput,
│   │                            cleanMessage, API_ERRORS, enrichError, all types)
│   ├── client.ts             ← KwtSMS class
│   ├── phone.ts              ← normalizePhone(), validatePhoneInput()
│   ├── message.ts            ← cleanMessage()
│   ├── errors.ts             ← API_ERRORS map, enrichError()
│   ├── request.ts            ← HTTP POST with JSON, reads 4xx bodies
│   ├── env.ts                ← loadEnvFile() (never modifies process.env)
│   ├── logger.ts             ← JSONL logger (maskCredentials, writeLog)
│   └── cli.ts                ← CLI entry point
├── dist/                     ← compiled JS + .d.ts (gitignored, built before publish)
├── test/
│   ├── phone.test.ts
│   ├── message.test.ts
│   ├── errors.test.ts        ← mocked
│   ├── client.test.ts        ← mocked API responses
│   ├── env.test.ts           ← .env parsing
│   ├── logger.test.ts        ← password masking
│   └── integration.test.ts   ← real API, skipped without JS_USERNAME
└── examples/
    ├── README.md             ← index of all examples
    ├── 01-basic-usage.ts
    ├── 01-basic-usage.md
    ├── 02-otp-flow.ts
    ├── 02-otp-flow.md
    ├── 03-bulk-sms.ts
    ├── 03-bulk-sms.md
    ├── 04-express-endpoint.ts
    ├── 04-express-endpoint.md
    ├── 05-nextjs-route.ts
    ├── 05-nextjs-route.md
    └── 06-otp-production/   ← production OTP: adapters, CAPTCHA, 9 framework wiring files
        ├── README.md
        ├── otp-service.ts
        ├── adapters/
        │   ├── memory.ts
        │   ├── sqlite.ts
        │   ├── drizzle.ts
        │   └── prisma.ts
        ├── captcha/
        │   ├── turnstile.ts
        │   └── hcaptcha.ts
        └── usage/
            ├── node-http.ts
            ├── express.ts
            ├── fastify.ts
            ├── nextjs.ts
            ├── hono.ts
            ├── nestjs.ts
            ├── tanstack.ts
            ├── astro.ts
            └── sveltekit.ts
```

**package.json key fields:**
```json
{
    "name": "kwtsms",
    "type": "module",
    "main": "dist/index.js",
    "types": "dist/index.d.ts",
    "exports": {
        ".": {
            "import": "./dist/index.js",
            "require": "./dist/index.cjs",
            "types": "./dist/index.d.ts"
        }
    },
    "bin": { "kwtsms": "dist/cli.js" },
    "files": ["dist/", "README.md", "LICENSE"]
}
```

**JS/TS-specific considerations:**
- Use `node:https` (built-in) for HTTP. No `axios`, `node-fetch`, or `undici`
- Dual output: ESM (`.js`) + CommonJS (`.cjs`) via `tsup`
- Async/await for all API methods. Node.js HTTP is callback-based, wrap in Promise
- `.env` parsing: read file manually with `node:fs.readFileSync`, no `dotenv` dependency
- `loadEnvFile()` must NOT modify `process.env` (read-only). Returns a plain object.
- Unicode: JavaScript strings are UTF-16. Use `Array.from(text)` before iterating to handle surrogate pairs correctly. Use `codePointAt(0)` not `charCodeAt()` for emoji ranges.
- CLI: use `node:util.parseArgs` (Node 18.3+) for argument parsing. No `commander` or `yargs` dependency.
- Export `API_ERRORS` as a `const` (read-only) for TypeScript callers
- Password field in KwtSMS class must use private class field (`#password`) not just a private variable, so it is genuinely inaccessible outside the class and does not appear in `JSON.stringify(client)`

**Publishing to npm:**
```
1. Create an npm account at https://www.npmjs.com/signup
2. npm login
3. Build: npm run build (runs tsc, outputs to dist/)
4. Publish: npm publish --access public
5. Updates:
   - Bump version: npm version patch (or minor/major)
   - Rebuild: npm run build
   - Publish: npm publish
```

---

### 3. Go → pkg.go.dev

**Registry:** https://pkg.go.dev (auto-indexed from GitHub)
**Repo:** `github.com/boxlinknet/kwtsms-go`
**Install:** `go get github.com/boxlinknet/kwtsms-go`
**Min version:** Go 1.18+ (generics support, widely deployed)
**Dependencies:** Zero. Go stdlib has `net/http`, `encoding/json`, `os`, `regexp`, `strings`, `unicode`
**CLI:** Yes. Separate `cmd/kwtsms/main.go` binary, installed via `go install`
**Test runner:** Go built-in `testing` package

**Project structure:**
```
kwtsms-go/
├── go.mod
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── .github/
│   └── workflows/
│       └── publish.yml        ← GitHub Actions: test on tag (Go auto-indexes, no publish step)
├── kwtsms.go                  ← KwtSMS struct, New(), FromEnv(), all methods
├── phone.go                   ← NormalizePhone(), ValidatePhoneInput()
├── message.go                 ← CleanMessage()
├── errors.go                  ← apiErrors map, enrichError()
├── request.go                 ← HTTP POST, JSON marshal/unmarshal, reads 4xx bodies
├── logger.go                  ← JSONL logger
├── env.go                     ← loadEnvFile()
├── kwtsms_test.go             ← unit + mocked tests
├── phone_test.go
├── message_test.go
├── integration_test.go        ← real API (build tag: //go:build integration)
│                                 reads GO_USERNAME, GO_PASSWORD
├── cmd/
│   └── kwtsms/
│       └── main.go            ← CLI binary
└── examples/
    ├── README.md
    ├── 01-basic-usage/
    │   ├── main.go
    │   └── README.md
    ├── 02-otp-flow/
    │   ├── main.go
    │   └── README.md
    ├── 03-bulk-sms/
    │   ├── main.go
    │   └── README.md
    ├── 04-http-handler/
    │   ├── main.go
    │   └── README.md
    └── 05-error-handling/
        ├── main.go
        └── README.md
```

**Go-specific considerations:**
- Module path: `github.com/boxlinknet/kwtsms-go`
- Exported names follow Go conventions: `KwtSMS`, `NormalizePhone`, `CleanMessage`, `ValidatePhoneInput`
- Return `(result, error)` tuples, idiomatic Go error handling
- `Verify()` returns `(ok bool, balance float64, err error)`
- `Send()` returns `(*SendResult, error)` where SendResult is a struct
- Thread-safe: use `sync.Mutex` for cached balance
- `.env` parsing: read file with `os.ReadFile`, split lines manually
- Integration tests behind build tag: `//go:build integration`. Run with `go test -tags integration`
- No `context.Context` in v1 (keep it simple), add in v2 if needed

**Publishing to pkg.go.dev:**
```
Go modules are published via git tags. No registry submission needed.

1. Push code to github.com/boxlinknet/kwtsms-go
2. Ensure go.mod has: module github.com/boxlinknet/kwtsms-go
3. Tag a release:
   git tag v0.1.0
   git push origin v0.1.0
4. pkg.go.dev indexes it automatically within minutes
5. Users install:
   go get github.com/boxlinknet/kwtsms-go@v0.1.0
6. To install the CLI:
   go install github.com/boxlinknet/kwtsms-go/cmd/kwtsms@latest
```

---

### 4. Rust → crates.io

**Registry:** https://crates.io/crates/kwtsms
**Repo:** `github.com/boxlinknet/kwtsms-rust`
**Install:** `cargo add kwtsms`
**Min version:** Rust 2021 edition (1.56+)
**Dependencies:** Minimal. Rust stdlib has no HTTP client or JSON parser:
- `ureq`: tiny, synchronous HTTP client (no async runtime needed, ~300KB)
- `serde` + `serde_json`: JSON serialization (the universal Rust standard)
- Total: 3 deps, all widely trusted, well-maintained
**CLI:** Yes. Behind feature flag `cli` (opt-in, not forced on library users)
**Test runner:** `cargo test` (built-in)

**Project structure:**
```
kwtsms-rust/
├── Cargo.toml
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── .github/
│   └── workflows/
│       └── publish.yml        ← GitHub Actions: test + cargo publish on tag
├── src/
│   ├── lib.rs              ← public exports
│   ├── client.rs           ← KwtSMS struct + impl
│   ├── phone.rs            ← normalize_phone(), validate_phone_input()
│   ├── message.rs          ← clean_message()
│   ├── errors.rs           ← API_ERRORS map, enrich_error()
│   ├── request.rs          ← HTTP POST via ureq, reads 4xx bodies
│   ├── env.rs              ← load_env_file()
│   ├── logger.rs           ← JSONL logger
│   └── bin/
│       └── kwtsms.rs       ← CLI (only compiled with feature "cli")
├── tests/
│   ├── phone_test.rs
│   ├── message_test.rs
│   ├── errors_test.rs      ← mocked
│   └── integration_test.rs ← real API (behind #[cfg(feature = "integration")])
│                               reads RUST_USERNAME, RUST_PASSWORD
└── examples/
    ├── README.md
    ├── 01_basic_usage.rs
    ├── 01_basic_usage.md
    ├── 02_otp_flow.rs
    ├── 02_otp_flow.md
    ├── 03_bulk_sms.rs
    ├── 03_bulk_sms.md
    ├── 04_axum_endpoint.rs
    ├── 04_axum_endpoint.md
    ├── 05_error_handling.rs
    └── 05_error_handling.md
```

**Cargo.toml key fields:**
```toml
[package]
name = "kwtsms"
version = "0.1.0"
edition = "2021"
description = "Rust client for the kwtSMS API (kwtsms.com)"
license = "MIT"
repository = "https://github.com/boxlinknet/kwtsms-rust"

[dependencies]
ureq = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[features]
cli = []

[[bin]]
name = "kwtsms"
required-features = ["cli"]
```

**Rust-specific considerations:**
- Return `Result<T, KwtSmsError>` for all methods. Use a custom error enum
- `KwtSmsError` enum: `NetworkError(String)`, `ApiError { code, description, action }`, `InvalidInput(String)`
- Thread-safe: use `Arc<Mutex<>>` for interior mutability (cached balance)
- Phone normalization: iterate `char`s with `.is_ascii_digit()` and Unicode category checks
- Emoji removal: check Unicode ranges per codepoint (same approach as Python)
- `.env` parsing: read file with `std::fs::read_to_string`, split lines
- No async. Keep the library synchronous with `ureq`. Users who need async can use `tokio::task::spawn_blocking`

**Publishing to crates.io:**
```
1. Create account at https://crates.io (sign in with GitHub)
2. Get API token: crates.io → Account Settings → New Token
3. Login: cargo login <token>
4. First publish:
   cargo publish
5. Updates:
   - Bump version in Cargo.toml
   - cargo publish
```

---

### 5. Swift → Swift Package Manager

**Registry:** No centralized registry. Swift packages are hosted on GitHub and added via URL
**Repo:** `github.com/boxlinknet/kwtsms-swift`
**Install:** Add in Xcode: File → Add Packages → enter GitHub URL. Or in `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/boxlinknet/kwtsms-swift.git", from: "0.1.0")
]
```
**Min version:** Swift 5.7+ / iOS 15+ / macOS 12+ (async/await stable, widely deployed)
**Dependencies:** Zero. Use Foundation `URLSession` (built-in on all Apple platforms)
**CLI:** No (not idiomatic for Swift packages targeting iOS/macOS)
**Test runner:** XCTest (built-in)

**Project structure:**
```
kwtsms-swift/
├── Package.swift
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── .github/
│   ├── workflows/
│   │   ├── test.yml           ← GitHub Actions: test on push/PR (Swift 5.9, 5.10, 6.0)
│   │   └── codeql.yml         ← CodeQL security analysis (weekly + push/PR)
│   └── dependabot.yml         ← Auto-updates for Swift packages and GitHub Actions
├── Sources/
│   └── KwtSMS/
│       ├── KwtSMS.swift             ← main client class
│       ├── PhoneUtils.swift         ← normalizePhone(), validatePhoneInput()
│       ├── MessageUtils.swift       ← cleanMessage()
│       ├── ApiErrors.swift          ← error code map, enrichError()
│       ├── Request.swift            ← URLSession POST, JSON, reads 4xx bodies
│       ├── EnvLoader.swift          ← loadEnvFile() (macOS/server only)
│       └── Logger.swift             ← JSONL logger
├── Tests/
│   └── KwtSMSTests/
│       ├── PhoneTests.swift
│       ├── MessageTests.swift
│       ├── ApiErrorTests.swift      ← mocked URLProtocol
│       └── IntegrationTests.swift   ← real API, skipped without SWIFT_USERNAME
└── Examples/
    ├── README.md
    ├── 01-BasicUsage/
    │   ├── main.swift
    │   └── README.md
    ├── 02-OtpFlow/
    │   ├── main.swift
    │   └── README.md
    ├── 03-BulkSms/
    │   ├── main.swift
    │   └── README.md
    ├── 04-ErrorHandling/
    │   ├── main.swift
    │   └── README.md
    └── 05-OtpProduction/        ← production OTP with device attestation
        ├── OtpService.swift     ← core service: send/verify, rate limiting, SHA-256 hashing
        ├── README.md
        ├── adapters/
        │   └── MemoryStore.swift
        ├── attestation/
        │   └── AppAttestVerifier.swift  ← Apple App Attest (no CAPTCHA for iOS)
        └── usage/
            ├── VaporUsage.swift
            └── HummingbirdUsage.swift
```

**Swift-specific considerations:**
- All API methods should be `async` (Swift concurrency): `try await sms.send(...)`
- Return custom types: `VerifyResult`, `SendResult`, `ValidateReport`, `CoverageResult`
- Errors via `throws`. Define `KwtSMSError` enum conforming to `Error` and `LocalizedError`
- `KwtSMSError.apiError(code: String, description: String, action: String)`, always has action
- Thread-safe: `actor` or `@Sendable` closures. Swift concurrency handles this naturally
- `.env` loading: only works on macOS/server (iOS apps don't have filesystem access to `.env`). On iOS, use constructor with explicit credentials.
- **Credential management for iOS apps** (see universal "Credential Management" section above):
  - Backend proxy strongly recommended. App calls your server, never touches SMS API directly
  - If direct API access: use Keychain Services for storing credentials + provide a settings screen
  - NEVER store credentials in `Info.plist`, hardcoded strings, or bundled config files
  - Show example of loading from a remote config endpoint
- Mock `URLProtocol` for unit tests, no network dependency
- JSON decoding: use `Codable` protocol with custom `CodingKeys`

**Publishing via Swift Package Manager:**
```
Swift packages are published via git tags on GitHub.

1. Push code to github.com/boxlinknet/kwtsms-swift
2. Ensure Package.swift is valid:
   swift package describe
3. Tag a release:
   git tag 0.1.0
   git push origin 0.1.0
4. Users add in Xcode:
   File → Add Package Dependencies
   Enter: https://github.com/boxlinknet/kwtsms-swift.git
   Select version: 0.1.0
5. Or in Package.swift:
   .package(url: "https://github.com/boxlinknet/kwtsms-swift.git", from: "0.1.0")
```

---

### 6. Kotlin → Maven Central / JitPack

**Registry:** Maven Central (preferred) or JitPack (easier setup, pulls from GitHub)
**Repo:** `github.com/boxlinknet/kwtsms-kotlin`
**Install (JitPack):**
```kotlin
// settings.gradle.kts
repositories {
    maven("https://jitpack.io")
}

// build.gradle.kts
dependencies {
    implementation("com.github.boxlinknet:kwtsms-kotlin:0.1.0")
}
```
**Min version:** Kotlin 1.6+ / Java 8+ (maximum backward compatibility)
**Dependencies:** Zero runtime. Use Java built-in `java.net.HttpURLConnection` and `org.json` (bundled with Android)
**CLI:** No (not idiomatic for Kotlin/JVM libraries)
**Test runner:** JUnit 5 + kotlin.test

**Project structure:**
```
kwtsms-kotlin/
├── build.gradle.kts
├── settings.gradle.kts
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── jitpack.yml                    ← tells JitPack which JDK to use
├── .github/
│   └── workflows/
│       └── test.yml               ← GitHub Actions: test on tag (JitPack auto-builds)
├── src/
│   └── main/
│       └── kotlin/
│           └── com/kwtsms/
│               ├── KwtSMS.kt              ← main client class
│               ├── PhoneUtils.kt          ← normalizePhone(), validatePhoneInput()
│               ├── MessageUtils.kt        ← cleanMessage()
│               ├── ApiErrors.kt           ← error map, enrichError()
│               ├── Request.kt             ← HTTP POST, reads 4xx bodies
│               ├── EnvLoader.kt           ← loadEnvFile()
│               └── Logger.kt              ← JSONL logger
├── src/
│   └── test/
│       └── kotlin/
│           └── com/kwtsms/
│               ├── PhoneUtilsTest.kt
│               ├── MessageUtilsTest.kt
│               ├── ApiErrorsTest.kt       ← mocked
│               └── IntegrationTest.kt     ← real API, skipped without KOTLIN_USERNAME
└── examples/
    ├── README.md
    ├── 01-basic-usage/
    │   ├── Main.kt
    │   └── README.md
    ├── 02-otp-flow/
    │   ├── Main.kt
    │   └── README.md
    ├── 03-bulk-sms/
    │   ├── Main.kt
    │   └── README.md
    └── 04-error-handling/
        ├── Main.kt
        └── README.md
```

**Kotlin-specific considerations:**
- Use `HttpURLConnection` (Java stdlib). No OkHttp or Ktor dependency
- Read 4xx response bodies via `connection.errorStream`. kwtSMS returns JSON in error bodies
- JSON parsing: use `org.json.JSONObject` (bundled with Android) or manual parsing. No Gson/Moshi dependency
- For non-Android JVM: bundle a minimal JSON parser or use `javax.json` (avoid adding kotlinx.serialization as a required dependency)
- Return sealed classes: `sealed class SmsResult { data class Ok(...); data class Error(...) }`
- Thread-safe: `@Volatile` for cached balance, or use `AtomicReference`
- Kotlin coroutine support: provide `suspend` variants of API methods as extension functions (optional, don't force kotlinx.coroutines as a dependency)
- **Credential management for Android apps** (see universal "Credential Management" section above):
  - Backend proxy strongly recommended. App calls your server, never touches SMS API directly
  - If direct API access: use `EncryptedSharedPreferences` for storing credentials + provide a settings Activity
  - Document loading credentials from Firebase Remote Config or your own API endpoint
  - NEVER store credentials in `strings.xml`, `BuildConfig` fields, or hardcoded in source
  - Admin settings screen must include a "Test Connection" button that calls `verify()`

**Publishing via JitPack (easiest):**
```
JitPack builds directly from GitHub. No manual upload needed.

1. Push code to github.com/boxlinknet/kwtsms-kotlin
2. Ensure build.gradle.kts has:
   group = "com.github.boxlinknet"
   version = "0.1.0"
3. Create jitpack.yml:
   jdk:
     - openjdk17
4. Tag a release:
   git tag v0.1.0
   git push origin v0.1.0
5. Visit https://jitpack.io/#boxlinknet/kwtsms-kotlin to trigger build
6. Users add to their project:
   repositories { maven("https://jitpack.io") }
   dependencies { implementation("com.github.boxlinknet:kwtsms-kotlin:0.1.0") }
```

**Publishing via Maven Central (more credible, harder setup):**
```
Requires GPG signing and Sonatype OSSRH account.

1. Create Sonatype OSSRH account: https://issues.sonatype.org/secure/Signup!default.jspa
2. Open a ticket to claim group ID (e.g., com.kwtsms)
3. Generate GPG key: gpg --gen-key
4. Upload public key: gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>
5. Configure ~/.gradle/gradle.properties with signing key and Sonatype credentials
6. Add maven-publish and signing plugins to build.gradle.kts
7. Publish: ./gradlew publish
8. Login to https://s01.oss.sonatype.org → Close → Release the staging repo
```

---

### 7. Dart/Flutter → pub.dev

**Registry:** https://pub.dev/packages/kwtsms
**Repo:** `github.com/boxlinknet/kwtsms-dart`
**Install:** `dart pub add kwtsms` / `flutter pub add kwtsms`
**Min version:** Dart 3.0+ / Flutter 3.10+ (null safety stable, records, patterns)
**Dependencies:** Zero. Dart has built-in `dart:io` (HttpClient), `dart:convert` (JSON), `dart:math` (Random.secure)
**CLI:** Yes. Register via `executables` in `pubspec.yaml`, installed with `dart pub global activate kwtsms`
**Test runner:** `dart test` (built-in via `package:test`)

**Project structure:**
```
kwtsms-dart/
├── pubspec.yaml
├── analysis_options.yaml        ← Dart linter rules
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── .github/
│   ├── workflows/
│   │   ├── test.yml             ← test on push/PR (Dart stable + beta)
│   │   ├── codeql.yml           ← CodeQL security analysis
│   │   └── publish.yml          ← publish to pub.dev on tag
│   └── dependabot.yml           ← auto-updates for GitHub Actions
├── lib/
│   ├── kwtsms.dart              ← public exports
│   └── src/
│       ├── client.dart          ← KwtSMS class
│       ├── phone.dart           ← normalizePhone(), validatePhoneInput()
│       ├── message.dart         ← cleanMessage()
│       ├── errors.dart          ← apiErrors map, enrichError()
│       ├── request.dart         ← HTTP POST via dart:io HttpClient
│       ├── env.dart             ← loadEnvFile()
│       └── logger.dart          ← JSONL logger
├── test/
│   ├── phone_test.dart
│   ├── message_test.dart
│   ├── errors_test.dart
│   └── integration_test.dart    ← real API, skipped without DART_USERNAME
├── bin/
│   └── kwtsms.dart              ← CLI binary
└── example/                     ← pub.dev convention: example/ not examples/
    ├── README.md
    ├── 01_basic_usage.dart
    ├── 02_otp_flow.dart
    ├── 03_bulk_sms.dart
    ├── 04_shelf_endpoint.dart   ← Shelf (Dart's built-in HTTP server framework)
    ├── 05_error_handling.dart
    └── 06_otp_production/       ← production OTP with device attestation
        ├── README.md
        ├── otp_service.dart
        ├── adapters/
        │   └── memory_store.dart
        ├── attestation/         ← device attestation (no CAPTCHA for mobile)
        │   ├── app_attest_verifier.dart    ← iOS App Attest
        │   └── play_integrity_verifier.dart ← Android Play Integrity
        └── usage/
            ├── shelf_usage.dart
            └── dart_frog_usage.dart
```

**pubspec.yaml key fields:**
```yaml
name: kwtsms
description: Official Dart/Flutter client for the kwtSMS SMS gateway API (kwtsms.com).
version: 0.1.0
homepage: https://www.kwtsms.com/integrations.html
repository: https://github.com/boxlinknet/kwtsms-dart

environment:
  sdk: ">=3.0.0 <4.0.0"

executables:
  kwtsms: kwtsms
```

**Dart-specific considerations:**
- Use `dart:io` `HttpClient` for HTTP (built-in, no `http` or `dio` package needed)
- Read HTTP error response bodies: `HttpClientResponse` gives the body even on 4xx
- Return custom classes: `VerifyResult`, `SendResult`, `ValidateResult` (not Maps)
- Use records for multi-return: `(bool valid, String? error, String normalized)` from `validatePhoneInput()`
- JSON: use `dart:convert` `jsonDecode`/`jsonEncode` (built-in)
- `.env` parsing: read file with `File().readAsStringSync()`, split lines manually
- Async: all API methods return `Future<T>`, use `async`/`await`
- Thread-safe: Dart is single-threaded (event loop). No mutex needed for cached balance in standard use. For Isolates, document that each Isolate needs its own `KwtSMS` instance
- **Credential management for Flutter apps** (see universal "Credential Management" section above):
  - Backend proxy strongly recommended. App calls your server, never touches SMS API directly
  - If direct API access: use `flutter_secure_storage` for credentials + provide a settings screen
  - NEVER store credentials in assets, hardcoded strings, or environment files bundled with the app
  - **No CAPTCHA needed for mobile apps.** Use device attestation instead:
    - iOS: Apple App Attest via `DCAppAttestService` (see Swift library's `DeviceAttestVerifier` pattern)
    - Android: Google Play Integrity API (replaces SafetyNet). Verifies app genuineness and device integrity
    - Both: `TokenAuthenticator` protocol for JWT/session-based 2FA flows
- CLI: use `package:args` for argument parsing (well-maintained, Dart team package). Or `dart:io` `ArgParser` for zero deps
- Export types: all public types in `lib/kwtsms.dart` barrel file via `export 'src/...'`
- Unicode: Dart strings are UTF-16. Use `String.runes` (Runes iterator) for correct codepoint iteration. Do NOT use `String.codeUnitAt()` for emoji ranges
- Linting: use `package:lints/recommended.yaml` in `analysis_options.yaml`
- **Flutter compatibility:** the library must work in both pure Dart (server-side) and Flutter (mobile) contexts. Avoid `dart:io` imports in code that needs to run on web. Use conditional imports if web support is needed

**Publishing to pub.dev:**
```
1. Create a Google account (pub.dev uses Google sign-in)
2. Ensure pubspec.yaml has all required fields (name, version, description, homepage, environment)
3. Dry run: dart pub publish --dry-run
4. First publish: dart pub publish
5. pub.dev verifies your email and publishes the package
6. Updates:
   - Bump version in pubspec.yaml
   - Update CHANGELOG.md
   - dart pub publish
7. Automated publishing via GitHub Actions:
   - Use dart-lang/setup-dart action
   - Authenticate with OIDC (pub.dev supports GitHub Actions OIDC, no token needed)
   - Or use PUB_TOKEN secret
```

---

### 8. Zig → GitHub (build.zig.zon)

**Registry:** No centralized registry. Zig packages are hosted on GitHub and fetched via `build.zig.zon`
**Repo:** `github.com/boxlinknet/kwtsms-zig`
**Install:** Add to `build.zig.zon`:
```zig
.dependencies = .{
    .kwtsms = .{
        .url = "https://github.com/boxlinknet/kwtsms-zig/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "...",  // zig will tell you this on first fetch
    },
},
```
Then in `build.zig`:
```zig
const kwtsms = b.dependency("kwtsms", .{});
exe.root_module.addImport("kwtsms", kwtsms.module("kwtsms"));
```
**Min version:** Zig 0.13+ (stable package manager)
**Dependencies:** Zero. Use Zig stdlib `std.http.Client` and `std.json`
**CLI:** Yes. Separate binary in `src/main.zig` (CLI) vs `src/kwtsms.zig` (library)
**Test runner:** `zig test` (built-in)

**Project structure:**
```
kwtsms-zig/
├── build.zig
├── build.zig.zon
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
├── .github/
│   └── workflows/
│       └── test.yml           ← GitHub Actions: test on tag (no publish step for Zig)
├── src/
│   ├── kwtsms.zig          ← public module: KwtSMS struct, all methods
│   ├── phone.zig           ← normalizePhone(), validatePhoneInput()
│   ├── message.zig         ← cleanMessage()
│   ├── errors.zig          ← error code map, enrichError()
│   ├── request.zig         ← HTTP POST via std.http.Client
│   ├── env.zig             ← loadEnvFile()
│   ├── logger.zig          ← JSONL logger
│   └── main.zig            ← CLI binary
├── tests/
│   ├── phone_test.zig
│   ├── message_test.zig
│   └── integration_test.zig   ← skipped without ZIG_USERNAME
└── examples/
    ├── README.md
    ├── 01_basic_usage.zig
    ├── 01_basic_usage.md
    ├── 02_otp_flow.zig
    ├── 02_otp_flow.md
    ├── 03_bulk_sms.zig
    ├── 03_bulk_sms.md
    ├── 04_error_handling.zig
    └── 04_error_handling.md
```

**Zig-specific considerations:**
- Use `std.http.Client` for HTTP (available in Zig stdlib since 0.11)
- Use `std.json` for JSON parsing
- Return error unions: `fn send(...) !SendResult`, Zig's native error handling
- Define `KwtSmsError` error set: `AuthError`, `NetworkError`, `ApiError`, `InvalidInput`
- Use allocator pattern: client takes an `std.mem.Allocator` parameter
- Phone normalization: iterate Unicode codepoints with `std.unicode.utf8Decode`
- `.env` parsing: read file with `std.fs`, split lines
- Thread-safe: use `std.Thread.Mutex` for cached balance
- No garbage collector. All allocations must be explicit and freed

**Publishing via GitHub:**
```
Zig packages are hosted on GitHub and referenced by URL + hash.

1. Push code to github.com/boxlinknet/kwtsms-zig
2. Ensure build.zig.zon has package metadata:
   .name = "kwtsms",
   .version = "0.1.0",
3. Tag a release:
   git tag v0.1.0
   git push origin v0.1.0
4. Users add to their build.zig.zon:
   .kwtsms = .{
       .url = "https://github.com/boxlinknet/kwtsms-zig/archive/refs/tags/v0.1.0.tar.gz",
       .hash = "...",
   },
5. Run: zig build (Zig fetches and prints the expected hash on first run)
6. To install the CLI:
   zig fetch --save https://github.com/boxlinknet/kwtsms-zig/archive/refs/tags/v0.1.0.tar.gz
```

---

## Implementation Order (recommended)

| Priority | Language | Reason | Status |
|----------|----------|--------|--------|
| 1 | TypeScript/JavaScript | Largest ecosystem, web+server, npm reach | Done |
| 2 | PHP | Most common in Kuwait/MENA hosting (WordPress, Laravel) | Done |
| 3 | Swift | iOS apps, captures half of mobile market | Done |
| 4 | Dart/Flutter | Cross-platform mobile (iOS + Android), growing fast in Gulf | |
| 5 | Kotlin | Android-native apps, JVM server-side | |
| 6 | Go | Growing server-side adoption, clean module system | |
| 7 | Rust | Strong systems/CLI audience, excellent crate ecosystem | |
| 8 | Zig | Smallest audience, no package registry, lowest priority | |

---

## Folder Layout

```
kwtsms_integrations/
├── kwtsms_py/             ← done (v0.7.9), repo root = package root
├── kwtsms_js/             ← done (v0.2.0)
├── kwtsms_php/            ← done
├── kwtsms_swift/          ← done (v0.2.0)
├── kwtsms_dart/           ← next
├── kwtsms_kotlin/
├── kwtsms_go/
├── kwtsms_rust/
└── kwtsms_zig/
```

Each directory is its own git repo pushed to GitHub under the `boxlinknet` organization. The package manifest (e.g., `pyproject.toml`, `package.json`, `composer.json`, `Cargo.toml`) sits directly at the repo root. Do NOT create a nested subdirectory inside the repo.

---

## Repository Setup (REQUIRED for every language)

### Flat structure: no nesting

All package files must live directly at the repo root. The repo root IS the package. Never create a subdirectory like `kwtsms/` inside the repo to hold the actual package. This avoids double READMEs, double .gitignores, and a confusing structure.

**Correct:**
```
python_packages/          ← git repo root
├── src/kwtsms/
├── pyproject.toml        ← package manifest at root
├── README.md
└── LICENSE
```

**Wrong:**
```
python_packages/          ← git repo root
└── kwtsms/               ← unnecessary nesting
    ├── src/kwtsms/
    ├── pyproject.toml
    └── README.md
```

### Git initialization

If no local git repo exists in the language directory, initialize one:

```bash
cd kwtsms_integrations/<language>_packages/
git init
git remote add origin https://github.com/boxlinknet/kwtsms-<language>.git
```

### .gitignore (REQUIRED, create at repo root)

Every repo must have a `.gitignore` at the repo root.

**IMPORTANT: Tests belong in the repository.** Never gitignore the `test/` or `tests/` directory. Tests help contributors and are part of the public repo. Exclude tests from the published package artifact instead (via `"files"` in `package.json`, `exclude` in `Cargo.toml`, `.npmignore`, etc.).

**Universal base — include in every language's `.gitignore`:**

```gitignore
# Credentials — NEVER commit
.env
*.env

# Logs — may contain phone numbers and message bodies
*.log

# Claude Code project config — local only, contains session data and memory
.claude/

# Claude Code AI instructions — personal to each developer, stays local
CLAUDE.md

# Internal docs and planning — PRDs, design docs, meeting notes
docs/

# Git worktrees (if used)
.worktrees/

# IDE and OS
.vscode/
.idea/
.DS_Store
Thumbs.db
```

**Language-specific additions (append to the universal base):**

**JavaScript / TypeScript:**
```gitignore
# Build output (generated, not committed)
dist/

# Dependencies
node_modules/
.npm

# TypeScript incremental build info
*.tsbuildinfo
```

**PHP:**
```gitignore
# Composer dependencies
vendor/

# Composer lock is committed for applications, gitignored for libraries
# For a library: gitignore composer.lock so users get compatible versions
composer.lock
```

**Go:**
```gitignore
# Compiled binaries
*.exe
*.test
/bin/

# Module download cache (populated by go get)
# go.sum IS committed — it locks dependency checksums
```

**Rust:**
```gitignore
# Cargo build output
/target/

# Cargo.lock: commit for binaries/CLIs, gitignore for libraries
# For a library: gitignore Cargo.lock
Cargo.lock
```

**Swift:**
```gitignore
# SPM build output
.build/

# SPM workspace
.swiftpm/

# Resolved package versions (libraries should not commit lock files)
Package.resolved

# Xcode
xcuserdata/
DerivedData/
*.xcodeproj
*.xcworkspace
```

**Kotlin / Gradle:**
```gitignore
# Gradle build output
build/
.gradle/

# Compiled class files
*.class
*.jar

# Local Gradle properties (may contain signing credentials)
local.properties
```

**Dart/Flutter:**
```gitignore
# Dart/Flutter build output
.dart_tool/
build/

# Package resolution
.packages
pubspec.lock    # gitignore for libraries, commit for applications

# Flutter
.flutter-plugins
.flutter-plugins-dependencies
```

**Zig:**
```gitignore
# Zig build output
zig-out/
.zig-cache/
```

**Sensitive files that must NEVER be committed:**
- `.env` and `*.env` (API credentials for the library, test credentials, etc.)
- `*.log` (JSONL request logs include phone numbers and message bodies)
- `.claude/` (Claude Code session data and project memory)
- `CLAUDE.md` (personal AI assistant config, may contain project-specific notes)

**Files that stay local:**
- `docs/` (PRD, planning docs, design decisions — use git history and GitHub releases for public docs)
- `.worktrees/` (git worktrees directory used during development)

---

## CHANGELOG.md Requirements

Every language repository must include a `CHANGELOG.md` at the repo root following the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format with [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### Required structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - YYYY-MM-DD

Initial release of the `kwtsms` <Language> client library.

### Added

**Core client (`KwtSMS`)**
- List every significant feature at initial release

**Phone normalization**
- List normalization behaviors

**Message cleaning**
- List cleaning behaviors

**Error handling**
- Number of error codes, enrichError, etc.

**HTTP layer**
- Timeout, JSON, 4xx body reading, etc.

**Tests**
- Test file names, number of tests per file

**Documentation**
- README sections, examples count

[Unreleased]: https://github.com/boxlinknet/kwtsms-<lang>/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/boxlinknet/kwtsms-<lang>/releases/tag/v0.1.0
```

### What to document in each entry

Use these categories (include only categories that have entries):

| Category | What goes here |
|----------|---------------|
| `Added` | New features, new methods, new exports |
| `Changed` | Changes to existing behavior (non-breaking) |
| `Deprecated` | Features planned for removal |
| `Removed` | Features removed in this version |
| `Fixed` | Bug fixes |
| `Security` | Security-related fixes |

### Rules

- Update `[Unreleased]` during development. Move to a versioned section at release time.
- Every public API change must have a CHANGELOG entry.
- Be specific: "Added `validate()` method" not "Improvements".
- Include breaking changes prominently under `Changed` or `Removed`.

---

## CONTRIBUTING.md Requirements

Every language repository must include a `CONTRIBUTING.md` at the repo root.

### Required sections (in this order)

1. **Opening**: "Contributions are welcome: bug reports, fixes, new examples, and documentation improvements."
2. **Before You Start**: search existing issues; open issue before large changes; all contributions must pass the test suite.
3. **Development Setup**: prerequisites (language version + package manager version), clone + install + verify commands.
4. **Running Tests**: all three tiers with exact commands. Note that unit tests need no credentials.
5. **Build**: how to build, what outputs are produced, where they go.
6. **Project Structure**: a directory tree with one-line description per file.
7. **Making Changes**: branch naming conventions, commit style (Conventional Commits), code style rules.
8. **Adding a New Method**: step-by-step TDD workflow (write failing test → verify it fails → implement → verify it passes → export → document → update CHANGELOG).
9. **Pull Request Process**: steps, PR checklist, PR description template.
10. **Reporting Bugs**: bug report template (language version, package version, reproduction, expected vs actual).
11. **Security Issues**: do not open public issues for security vulnerabilities; use private GitHub security advisory or support channel.
12. **License**: "By contributing, you agree that your contributions will be licensed under the MIT License."

### Branch naming conventions (use in all languages)

```
fix/short-description        — bug fix
feat/short-description       — new feature
docs/short-description       — documentation only
test/short-description       — tests only
chore/short-description      — build, tooling, dependency updates
```

### Commit style (Conventional Commits, all languages)

```
<type>: <short description>

[optional body]
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`

Examples:
```
feat: add status() method for message queue lookup
fix: handle ERR028 (15s same-number cooldown) in bulk send
docs: add Next.js App Router example
test: cover Arabic digit normalization edge cases
chore: bump dependency versions
```

### PR checklist (adapt per language)

```
- [ ] Tests added/updated for all changed behavior
- [ ] All existing tests pass
- [ ] Build succeeds without warnings
- [ ] CHANGELOG.md updated under [Unreleased]
- [ ] No new runtime dependencies added (zero-dep policy)
- [ ] Public types exported if new public types added
```

---

## Examples Requirements

Every language repository must include an `examples/` directory at the repo root with numbered, runnable examples. Each example must have both a code file and a companion `.md` documentation file.

### Required examples (all languages)

| # | Example | Code file | Doc file |
|---|---------|-----------|---------|
| 01 | Basic usage: verify, send, balance | `01-basic-usage.<ext>` | `01-basic-usage.md` |
| 02 | OTP flow: send + verify OTP | `02-otp-flow.<ext>` | `02-otp-flow.md` |
| 03 | Bulk SMS: >200 numbers, batch handling | `03-bulk-sms.<ext>` | `03-bulk-sms.md` |
| 04 | Web framework integration (simplest supported framework) | `04-<framework>-endpoint.<ext>` | `04-<framework>-endpoint.md` |
| 05 | Error handling: all error paths, user-facing messages | `05-error-handling.<ext>` | `05-error-handling.md` |

Languages with rich framework ecosystems (JS, PHP, Go, Kotlin) should add:

| # | Example |
|---|---------|
| 06 | Production OTP with DB storage, rate limiting, CAPTCHA |

### Each companion `.md` file must include

1. **What this example demonstrates** (2–3 sentences)
2. **Prerequisites**: what must be installed or configured before running
3. **Environment setup**: the exact `.env` variables needed
4. **Annotated walkthrough**: step-by-step explanation of what the code does and why
5. **Expected output**: exact or representative output from a successful run
6. **Common mistakes**: at least 2–3 mistakes specific to this example with wrong/correct patterns

### Production OTP example (06-otp-production/) requirements

The OTP production example is a self-contained, drop-in implementation that any developer can copy into their project. It must include:

**Core service file** (`otp-service.<ext>`):
- `sendOtp(phone, captchaToken/assertion, ip)` method
- `verifyOtp(phone, code, ip)` method
- All checks in correct order: sanitize phone, verify bot protection (CAPTCHA for web / device attestation for mobile), check auth token (if 2FA), check IP rate limit, check phone rate limit, resend cooldown, generate code, hash securely (bcrypt cost 8 for JS/PHP, SHA-256+salt for Swift/Dart/Go/Rust/Zig), store, send SMS, rollback on failure
- Verify flow: sanitize both inputs, check rate limit, load record, check used/expired/max attempts, bcrypt.compare (timing-safe), increment on wrong / mark used on correct
- Configurable constants: `CODE_LENGTH=6`, `CODE_EXPIRY_MS`, `RESEND_COOLDOWN_MS`, `MAX_ATTEMPTS`, `IP_LIMIT_PER_HOUR`, `PHONE_LIMIT_PER_HOUR`, `VERIFY_LIMIT_PER_HOUR`
- Exported types: `OtpStore`, `CaptchaVerifier`, `OtpServiceConfig`, `SendOtpResult`, `VerifyOtpResult`
- **Use `crypto.randomInt` (or language equivalent) for OTP generation, NOT `Math.random()`**
- **Hash OTP codes with bcrypt (cost 8) before storing. Never store plain codes.**
- **Rate limit counters must not be rolled back on send failure** (prevents bypass)

**Database adapters** (`adapters/`):
- `memory.<ext>` — zero-dep, in-memory store, for dev/testing only
- `sqlite.<ext>` — embedded DB, WAL mode, auto-creates tables, prepared statements
- `drizzle.<ext>` (JS) or language-appropriate ORM adapter — with upsert pattern
- `prisma.<ext>` (JS) or equivalent — with full schema snippet in file comments

**Bot prevention adapters** (choose based on platform):

For **web** backends (`captcha/`):
- `turnstile.<ext>` — Cloudflare Turnstile verifier, JSON body POST, 5s timeout, fail-safe false
- `hcaptcha.<ext>` — hCaptcha verifier, URL-encoded body POST, 5s timeout, fail-safe false
- Both must: use only stdlib HTTP (no fetch dependencies), return false on ALL errors (timeout, network, invalid JSON)

For **mobile** apps (`attestation/`):
- `DeviceAttestVerifier` protocol — verifies device attestation/assertion tokens
- iOS: `AppAttestVerifier` — Apple App Attest (DCAppAttestService) server-side verification
- Android: `PlayIntegrityVerifier` — Google Play Integrity API server-side verification
- `TokenAuthenticator` protocol — JWT/session token validation for 2FA flows
- Mobile apps do NOT need CAPTCHA. Device attestation is the equivalent protection.

**Framework usage files** (`usage/`): one file per supported framework showing wiring. At minimum:
- Native HTTP server
- The most popular web framework for that language
- For JS: Express, Fastify, Next.js App Router, Hono, NestJS, TanStack Start, Astro, SvelteKit

**Companion README.md** for the OTP example must document:
- The complete send flow (numbered steps with annotations explaining the security reason for each)
- All four DB adapter options with install commands and setup instructions
- Both CAPTCHA options with frontend and backend code snippets
- Rate limiting behavior: how in-memory vs DB-backed works
- Framework wiring table (one row per framework)
- Environment variables required
- Security checklist (at least 8 items)
- Common mistakes (at least 4 patterns with wrong/correct code)

### `examples/README.md` index file

Every `examples/` directory must include an `examples/README.md` that:
- Lists all examples with one-sentence descriptions
- Shows the recommended run command for each
- Notes which examples require credentials and which run without them

---

## CI/CD Requirements

### GitHub Actions workflow (REQUIRED for every language)

Every repository must include a GitHub Actions workflow at `.github/workflows/publish.yml` that:
1. Triggers on version tag pushes: `on: push: tags: ['v*']`
2. Runs the unit test suite
3. Publishes to the language's registry using a secret token

**The `.github/` directory must be committed to the repository.** GitHub Actions only runs from files tracked in git. Do NOT add `.github/` to `.gitignore`.

**Registry secrets** are stored in GitHub repository settings (Settings → Secrets and variables → Actions). The workflow file references them as `${{ secrets.NPM_TOKEN }}`, `${{ secrets.CRATES_TOKEN }}`, etc. The secret value never appears in the file.

**Example workflow (JavaScript/npm):**
```yaml
name: Publish to npm

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'
      - run: npm ci
      - run: npm run test:unit
      - run: npm run build
      - run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Registry secret names per language:**

| Language | Registry | Secret name |
|----------|----------|-------------|
| JavaScript | npm | `NPM_TOKEN` |
| PHP | Packagist | `PACKAGIST_TOKEN` (webhook secret) |
| Go | pkg.go.dev | No secret needed (auto-indexed from git tags) |
| Rust | crates.io | `CRATES_TOKEN` |
| Swift | SPM | No secret needed (auto-indexed from git tags) |
| Kotlin | JitPack | No secret needed (auto-built from git tags) |
| Dart | pub.dev | `PUB_TOKEN` (or use GitHub Actions OIDC, no token needed) |
| Zig | GitHub | No secret needed (users fetch by URL + hash) |

---

## Repository Hardening (REQUIRED for every language)

Every repository must include these security and maintenance configurations. These were validated during the Swift implementation and must be applied to all languages.

### CodeQL Security Analysis

Add `.github/workflows/codeql.yml`:
- Trigger: on push to main, on PR to main, weekly schedule (Monday 6am UTC)
- Analyze the repository's primary language
- Requires `security-events: write` permission
- For languages CodeQL does not support (Zig), skip this workflow

**Supported languages:** JavaScript/TypeScript, Python, Go, Java/Kotlin, Swift, Ruby, C/C++
**Not supported:** Rust (use `cargo audit` instead), Zig, Dart (use `dart analyze` instead), PHP (use `phpstan` instead)

### Dependabot

Add `.github/dependabot.yml`:
- Monitor the language's package ecosystem for dependency updates
- Monitor `github-actions` ecosystem for workflow action updates
- Weekly schedule (Monday)
- Max 5 open PRs per ecosystem
- Label PRs with `dependencies`

### Branch Protection

After initial push, enable branch protection on `main`:
- Block force pushes
- Block branch deletion
- Require status checks to pass before merging (all test matrix jobs)
- Strict mode: branch must be up-to-date before merging

Set via GitHub API:
```bash
curl -X PUT -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/boxlinknet/kwtsms-<lang>/branches/main/protection" \
  -d '{
    "required_status_checks": { "strict": true, "contexts": ["test (...)"] },
    "enforce_admins": false,
    "required_pull_request_reviews": null,
    "restrictions": null,
    "allow_force_pushes": false,
    "allow_deletions": false
  }'
```

### GitHub Release

After tagging, create a GitHub Release with:
- Tag name and release title matching the version
- Body listing all changes (from CHANGELOG.md)
- Install command snippet
- Not a draft, not a pre-release

### Repository Metadata

Set via GitHub API or web UI:
- Description: "Official <Language> client for the kwtSMS SMS gateway API"
- Homepage: `https://www.kwtsms.com/integrations.html`
- Topics: `kwtsms`, `sms`, `kuwait`, `sms-api`, `otp`, `<language>`

---

## Non-Requirements

- No legacy `text/html` API support. JSON API only
- No webhook / callback handling (not part of the kwtSMS API)
- No message scheduling
- No contact list management
- No SMS template management
- No delivery report polling loops (provide the method, let the user poll)

---

## README Template (every language must follow)

Every README must include these sections in this order:

1. **Package name + one-line description**
2. **kwtSMS intro** (exact text below)
3. **Prerequisites: Installing the package manager** (zero-knowledge, step-by-step)
4. **Install the package** (one command)
5. **Quick start** (from zero to sending SMS in <10 lines)
6. **Setup / Configuration** (.env file format, env vars, setup wizard if CLI)
7. **All methods** with signatures, parameters, return types, and examples
8. **Utility functions** with examples
9. **CLI usage** (if applicable) with all commands
10. **Error handling** with example code and common error code table
11. **Phone number formats** table (input → normalized)
12. **Test mode** explanation
13. **Sender ID** explanation and warning about KWT-SMS
14. **For mobile apps** (Swift/Kotlin/Dart-Flutter only): credential management patterns, device attestation (no CAPTCHA)
15. **What's handled automatically** bullet list
16. **FAQ** (top 5, exact questions below)
17. **Help & Support** (exact links below)
18. **License** (MIT)

---

### README Section: kwtSMS Intro (required, use this exact text)

Place this immediately after the package name / one-line description, before any install instructions.

```markdown
## About kwtSMS

kwtSMS is a Kuwaiti SMS gateway trusted by top businesses to deliver messages anywhere in the world, with private Sender ID, free API testing, non-expiring credits, and competitive flat-rate pricing. Secure, simple to integrate, built to last. Open a free account in under 1 minute, no paperwork or payment required. [Click here to get started](https://www.kwtsms.com/signup/) 👍
```

---

### README Section: Prerequisites: Installing the Package Manager (required)

Each language README must include a **Prerequisites** section that assumes the reader has never used the language's package manager before. Provide copy-paste terminal commands with brief explanations. Adapt the content below for each language:

#### PHP: Composer

```markdown
## Prerequisites

You need **PHP** (7.4 or newer) and **Composer** (PHP's package manager) installed.

### Step 1: Check if PHP is installed

```bash
php -v
```

If you see a version number (e.g., `PHP 8.2.x`), PHP is installed. If not, install it:

- **macOS:** `brew install php`
- **Ubuntu/Debian:** `sudo apt update && sudo apt install php php-curl`
- **Windows:** Download from https://windows.php.net/download/ or install via https://laragon.org/

### Step 2: Check if Composer is installed

```bash
composer --version
```

If you see a version number, Composer is installed. If not, install it:

- **macOS / Linux:**
  ```bash
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  ```
- **Windows:** Download and run the installer from https://getcomposer.org/download/

### Step 3: Install kwtsms

```bash
composer require kwtsms/kwtsms
```

This creates a `vendor/` folder and a `composer.json` file in your project. If you don't have a project yet, create a folder first:

```bash
mkdir my-project && cd my-project
composer require kwtsms/kwtsms
```
```

#### TypeScript/JavaScript: npm

```markdown
## Prerequisites

You need **Node.js** (16 or newer) installed. Node.js comes with **npm** (the package manager) built in.

### Step 1: Check if Node.js is installed

```bash
node -v
npm -v
```

If you see version numbers, you're ready. If not, install Node.js:

- **All platforms:** Download from https://nodejs.org/ (choose the LTS version)
- **macOS:** `brew install node`
- **Ubuntu/Debian:** `sudo apt update && sudo apt install nodejs npm`

### Step 2: Create a project (if you don't have one)

```bash
mkdir my-project && cd my-project
npm init -y
```

### Step 3: Install kwtsms

```bash
npm install kwtsms
```

You can also use other package managers:

```bash
yarn add kwtsms       # if you use Yarn
pnpm add kwtsms       # if you use pnpm
bun add kwtsms        # if you use Bun
```
```

#### Go

```markdown
## Prerequisites

You need **Go** (1.18 or newer) installed.

### Step 1: Check if Go is installed

```bash
go version
```

If you see a version number, Go is installed. If not:

- **All platforms:** Download from https://go.dev/dl/
- **macOS:** `brew install go`
- **Ubuntu/Debian:** `sudo apt update && sudo apt install golang-go`

### Step 2: Create a project (if you don't have one)

```bash
mkdir my-project && cd my-project
go mod init my-project
```

### Step 3: Install kwtsms

```bash
go get github.com/boxlinknet/kwtsms-go
```
```

#### Rust: Cargo

```markdown
## Prerequisites

You need **Rust** and **Cargo** (Rust's package manager) installed. They come together.

### Step 1: Check if Rust is installed

```bash
rustc --version
cargo --version
```

If you see version numbers, you're ready. If not, install Rust:

- **All platforms (recommended):**
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```
  Then restart your terminal.

- **Windows:** Download and run https://win.rustup.rs/

### Step 2: Create a project (if you don't have one)

```bash
cargo new my-project && cd my-project
```

### Step 3: Install kwtsms

```bash
cargo add kwtsms
```
```

#### Swift: Swift Package Manager (SPM)

```markdown
## Prerequisites

You need **Xcode** (14 or newer) installed. Swift and SPM come bundled with Xcode.

### Option A: Add via Xcode (GUI)

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter: `https://github.com/boxlinknet/kwtsms-swift.git`
4. Select version: `0.1.0` or later
5. Click **Add Package**

### Option B: Add via Package.swift (command line)

If you don't have a project yet:

```bash
mkdir MyProject && cd MyProject
swift package init --type executable
```

Open `Package.swift` and add the dependency:

```swift
dependencies: [
    .package(url: "https://github.com/boxlinknet/kwtsms-swift.git", from: "0.1.0")
],
targets: [
    .executableTarget(
        name: "MyProject",
        dependencies: [.product(name: "KwtSMS", package: "kwtsms-swift")]
    )
]
```

Then run:

```bash
swift build
```
```

#### Kotlin: Gradle

```markdown
## Prerequisites

You need **Java** (8 or newer) and **Gradle** installed. If you are using Android Studio, both are already included.

### Step 1: Check if Java is installed

```bash
java -version
```

If not installed:
- **All platforms:** Download from https://adoptium.net/ (Temurin JDK, free)
- **macOS:** `brew install openjdk`
- **Ubuntu/Debian:** `sudo apt update && sudo apt install default-jdk`

### Step 2: Add JitPack repository

In your `settings.gradle.kts` (or `build.gradle.kts` under `repositories`):

```kotlin
repositories {
    mavenCentral()
    maven("https://jitpack.io")
}
```

### Step 3: Add kwtsms dependency

In your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.github.boxlinknet:kwtsms-kotlin:0.1.0")
}
```

Then sync your project (Android Studio: click "Sync Now", or run `./gradlew build`).
```

#### Dart/Flutter

```markdown
## Prerequisites

You need **Dart** (3.0 or newer) installed. If you use Flutter, Dart is included.

### Option A: Dart only (server-side / CLI)

```bash
dart --version
```

If not installed:
- **All platforms:** Download from https://dart.dev/get-dart
- **macOS:** `brew tap dart-lang/dart && brew install dart`
- **Ubuntu/Debian:** Follow instructions at https://dart.dev/get-dart#install

### Option B: Flutter (mobile / cross-platform apps)

```bash
flutter --version
```

If not installed:
- **All platforms:** Follow https://docs.flutter.dev/get-started/install

### Install kwtsms

For a Dart project:
```bash
dart pub add kwtsms
```

For a Flutter project:
```bash
flutter pub add kwtsms
```
```

#### Zig

```markdown
## Prerequisites

You need **Zig** (0.13 or newer) installed.

### Step 1: Check if Zig is installed

```bash
zig version
```

If not installed:
- **All platforms:** Download from https://ziglang.org/download/
- **macOS:** `brew install zig`

### Step 2: Create a project (if you don't have one)

```bash
mkdir my-project && cd my-project
zig init
```

### Step 3: Add kwtsms dependency

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .kwtsms = .{
        .url = "https://github.com/boxlinknet/kwtsms-zig/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "...",  // Zig prints the expected hash on first build
    },
},
```

Then add to your `build.zig`:

```zig
const kwtsms = b.dependency("kwtsms", .{});
exe.root_module.addImport("kwtsms", kwtsms.module("kwtsms"));
```

Run `zig build`. Zig will fetch the package and print the correct hash if needed.
```

---

### README Section: FAQ (required, include these 5 questions)

```markdown
## FAQ

**1. My message was sent successfully (result: OK) but the recipient didn't receive it. What happened?**

Check the **Sending Queue** at [kwtsms.com](https://www.kwtsms.com/login/). If your message is stuck there, it was accepted by the API but not dispatched. Common causes are emoji in the message, hidden characters from copy-pasting, or spam filter triggers. Delete it from the queue to recover your credits. Also verify that `test` mode is off (`KWTSMS_TEST_MODE=0`). Test messages are queued but never delivered.

**2. What is the difference between Test mode and Live mode?**

**Test mode** (`KWTSMS_TEST_MODE=1`) sends your message to the kwtSMS queue but does NOT deliver it to the handset. No SMS credits are consumed. Use this during development. **Live mode** (`KWTSMS_TEST_MODE=0`) delivers the message for real and deducts credits. Always develop in test mode and switch to live only when ready for production.

**3. What is a Sender ID and why should I not use "KWT-SMS" in production?**

A **Sender ID** is the name that appears as the sender on the recipient's phone (e.g., "MY-APP" instead of a random number). `KWT-SMS` is a shared test sender. It causes delivery delays, is blocked on Virgin Kuwait, and should never be used in production. Register your own private Sender ID through your kwtSMS account. For OTP/authentication messages, you need a **Transactional** Sender ID to bypass DND (Do Not Disturb) filtering.

**4. I'm getting ERR003 "Authentication error". What's wrong?**

You are using the wrong credentials. The API requires your **API username and API password**, NOT your account mobile number. Log in to [kwtsms.com](https://www.kwtsms.com/login/), go to Account → API settings, and check your API credentials. Also make sure you are using POST (not GET) and `Content-Type: application/json`.

**5. Can I send to international numbers (outside Kuwait)?**

International sending is **disabled by default** on kwtSMS accounts. Contact kwtSMS support to request activation for specific country prefixes. Use `coverage()` to check which countries are currently active on your account. Be aware that activating international coverage increases exposure to automated abuse. Implement rate limiting and CAPTCHA before enabling.
```

---

### README Section: Help & Support (required, use these exact links)

```markdown
## Help & Support

- **[kwtSMS FAQ](https://www.kwtsms.com/faq/)**: Answers to common questions about credits, sender IDs, OTP, and delivery
- **[kwtSMS Support](https://www.kwtsms.com/support.html)**: Open a support ticket or browse help articles
- **[Contact kwtSMS](https://www.kwtsms.com/#contact)**: Reach the kwtSMS team directly for Sender ID registration and account issues
- **[API Documentation (PDF)](https://www.kwtsms.com/doc/KwtSMS.com_API_Documentation_v41.pdf)**: kwtSMS REST API v4.1 full reference
- **[kwtSMS Dashboard](https://www.kwtsms.com/login/)**: Recharge credits, buy Sender IDs, view message logs, manage coverage
- **[Other Integrations](https://www.kwtsms.com/integrations.html)**: Plugins and integrations for other platforms and languages
```

---

### README Section Order (final checklist)

Every language README must include these sections in this exact order:

1. **Package name + one-line description**
2. **About kwtSMS**: intro paragraph + signup link (exact text above)
3. **Prerequisites**: how to install the package manager, step by step (exact templates above, adapted per language)
4. **Install**: one command to install the package
5. **Quick start**: from zero to sending SMS in <10 lines of code
6. **Setup / Configuration**: .env file format, env vars, setup wizard if CLI
7. **Credential Management**: how to manage credentials on ALL platforms (env vars, admin UI, remote config, constructor). Extra section for mobile apps (Swift/Kotlin) covering backend proxy, secure storage, and why hardcoding is unacceptable.
8. **All methods**: signatures, parameters, return types, and code examples
9. **Utility functions**: with examples (normalize_phone, validate_phone_input, clean_message)
10. **Input Sanitization**: explain what clean_message() does and why it's critical (emojis stuck in queue, hidden chars, Arabic digits). Show that send() calls it automatically.
11. **CLI usage** (if applicable): all commands with examples
12. **Error handling**: example code, error code table, user-facing vs system-level error mapping
13. **Phone number formats**: table showing input → normalized output
14. **Test mode**: explanation of test vs live, how to switch
15. **Sender ID**: explanation, KWT-SMS warning, transactional vs promotional table
16. **Best Practices**: country coverage pre-check, local validation before API calls, balance monitoring, OTP requirements, user-facing error messages
17. **Security Checklist**: CAPTCHA, rate limiting (per phone, per IP, per user), bot detection, monitoring/alerting, pre-launch checklist box
18. **What's handled automatically**: bullet list of auto-normalization, auto-cleaning, deduplication, ERR013 retry, etc.
19. **Examples**: link to the `examples/` directory with one-line description of each example
20. **FAQ**: the 5 questions above
21. **Help & Support**: the exact links above
22. **License**: MIT

### README: "What's handled automatically" section content

Every README must include this section with at minimum these items (adapt names to language conventions):

```
## What's Handled Automatically

- **Phone normalization**: `+`, `00`, spaces, dashes, dots, parentheses stripped. Arabic-Indic digits converted. Leading zeros removed.
- **Duplicate phone removal**: If the same number appears multiple times (in different formats), it is sent only once.
- **Message cleaning**: Emojis removed (surrogate-pair safe). Hidden control characters (BOM, zero-width spaces, directional marks) removed. HTML tags stripped. Arabic-Indic digits in message body converted to Latin.
- **Batch splitting**: More than 200 numbers are automatically split into batches of 200 with 0.5s delay between batches.
- **ERR013 retry**: Queue-full errors are automatically retried up to 3 times with exponential backoff (30s / 60s / 120s).
- **Error enrichment**: Every API error response includes an `action` field with a developer-friendly fix hint.
- **Credential masking**: Passwords are always masked as `***` in log files. Never exposed.
- **Never throws**: All public methods return structured error objects. They never raise exceptions on API errors.
```
