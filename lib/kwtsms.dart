/// Official Dart/Flutter client for the kwtSMS SMS gateway API.
///
/// Send SMS, check balance, validate numbers, and more with the kwtSMS API.
/// Zero dependencies: uses only dart:io, dart:convert, and dart:math.
library kwtsms;

export 'src/client.dart'
    show
        KwtSMS,
        VerifyResult,
        SendResult,
        BulkSendResult,
        BatchError,
        ValidateResult,
        SenderIdResult,
        CoverageResult,
        StatusResult,
        DeliveryReportEntry,
        DeliveryReportResult;
export 'src/errors.dart' show apiErrors, enrichError;
export 'src/phone.dart'
    show normalizePhone, validatePhoneInput, deduplicatePhones, InvalidEntry;
export 'src/message.dart' show cleanMessage;
export 'src/env.dart' show loadEnvFile;
