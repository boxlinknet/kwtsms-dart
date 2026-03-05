# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-03-06] Dart HttpClient requires explicit contentLength for POST bodies**
   Do instead: Always use `request.contentLength = body.length; request.add(utf8.encode(jsonBody))` rather than `request.write(jsonBody)`. The kwtSMS API returns ERR002 (missing params) when content-length is not set.

2. **[2026-03-06] Dart SDK is installed at ~/dart-sdk/dart-sdk/bin/**
   Do instead: `export PATH="$HOME/dart-sdk/dart-sdk/bin:$PATH"` before running dart commands.

3. **[2026-03-06] Integration test credentials use DART_USERNAME / DART_PASSWORD**
   Do instead: Load from Swift .env with `export $(grep -E "^SWIFT_" /mnt/d/projects/kwtsms_integrations/kwtsms_swift/.env | xargs) && export DART_USERNAME=$SWIFT_USERNAME && export DART_PASSWORD=$SWIFT_PASSWORD`.

## Shell & Command Reliability
1. **[2026-03-06] `tail` is not available in this environment**
   Do instead: Avoid piping to `tail` or `head`. Use full output or Read tool with offset/limit.

## Domain Behavior Guardrails
1. **[2026-03-06] kwtSMS API returns ERR002 if Content-Type or body format is wrong**
   Do instead: Always POST with Content-Type: application/json, Accept: application/json, and proper JSON body with content-length.

2. **[2026-03-06] Example file names with numeric prefixes trigger Dart lint info**
   Do instead: Accept the info-level file_names lint for numbered examples (PRD requires this naming convention). Only errors and warnings matter.

## User Directives
1. **[2026-03-06] User does not know Dart; provide copy-paste commands**
   Do instead: Give exact terminal commands for anything requiring user action.
