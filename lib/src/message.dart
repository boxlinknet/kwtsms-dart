// Message cleaning utilities for kwtSMS.
//
// Removes emojis, hidden control characters, HTML tags, and converts
// Arabic/Persian digits to Latin before sending.

/// Clean message text for SMS delivery.
///
/// Performs these transformations in order:
/// 1. Convert Arabic-Indic and Extended Arabic-Indic/Persian digits to Latin
/// 2. Remove emojis
/// 3. Remove hidden invisible characters (zero-width space, BOM, etc.)
/// 4. Remove directional formatting characters
/// 5. Remove C0/C1 control characters (except \n and \t)
/// 6. Strip HTML tags
String cleanMessage(String text) {
  final buf = StringBuffer();

  for (final rune in text.runes) {
    // 1. Convert Arabic-Indic digits (U+0660-U+0669)
    if (rune >= 0x0660 && rune <= 0x0669) {
      buf.writeCharCode(0x30 + (rune - 0x0660)); // '0' + offset
      continue;
    }

    // 1. Convert Extended Arabic-Indic / Persian digits (U+06F0-U+06F9)
    if (rune >= 0x06F0 && rune <= 0x06F9) {
      buf.writeCharCode(0x30 + (rune - 0x06F0));
      continue;
    }

    // 2. Remove emojis
    if (_isEmoji(rune)) continue;

    // 3. Remove hidden invisible characters
    if (_isHiddenChar(rune)) continue;

    // 4. Remove directional formatting characters
    if (_isDirectional(rune)) continue;

    // 5. Remove C0/C1 control characters (except \n and \t)
    if (_isControlChar(rune)) continue;

    buf.writeCharCode(rune);
  }

  // 6. Strip HTML tags
  var result = buf.toString();
  result = result.replaceAll(RegExp(r'<[^>]*>'), '');

  return result;
}

bool _isEmoji(int rune) {
  return (rune >= 0x1F000 && rune <= 0x1F02F) || // Mahjong, domino tiles
      (rune >= 0x1F0A0 && rune <= 0x1F0FF) || // Playing cards
      (rune >= 0x1F1E0 && rune <= 0x1F1FF) || // Regional indicator symbols
      (rune >= 0x1F300 && rune <= 0x1F5FF) || // Misc symbols and pictographs
      (rune >= 0x1F600 && rune <= 0x1F64F) || // Emoticons
      (rune >= 0x1F680 && rune <= 0x1F6FF) || // Transport and map
      (rune >= 0x1F700 && rune <= 0x1F77F) || // Alchemical symbols
      (rune >= 0x1F780 && rune <= 0x1F7FF) || // Geometric shapes extended
      (rune >= 0x1F800 && rune <= 0x1F8FF) || // Supplemental arrows
      (rune >= 0x1F900 && rune <= 0x1F9FF) || // Supplemental symbols
      (rune >= 0x1FA00 && rune <= 0x1FA6F) || // Chess symbols
      (rune >= 0x1FA70 && rune <= 0x1FAFF) || // Symbols extended
      (rune >= 0x2600 && rune <= 0x26FF) || // Misc symbols
      (rune >= 0x2700 && rune <= 0x27BF) || // Dingbats
      (rune >= 0xFE00 && rune <= 0xFE0F) || // Variation selectors
      rune == 0x20E3 || // Combining enclosing keycap
      (rune >= 0xE0000 && rune <= 0xE007F); // Tags block
}

bool _isHiddenChar(int rune) {
  return rune == 0x200B || // Zero-width space
      rune == 0x200C || // Zero-width non-joiner
      rune == 0x200D || // Zero-width joiner
      rune == 0x2060 || // Word joiner
      rune == 0x00AD || // Soft hyphen
      rune == 0xFEFF || // BOM
      rune == 0xFFFC; // Object replacement character
}

bool _isDirectional(int rune) {
  return rune == 0x200E || // Left-to-right mark
      rune == 0x200F || // Right-to-left mark
      (rune >= 0x202A && rune <= 0x202E) || // LRE, RLE, PDF, LRO, RLO
      (rune >= 0x2066 && rune <= 0x2069); // LRI, RLI, FSI, PDI
}

bool _isControlChar(int rune) {
  // C0 controls (U+0000-U+001F), except TAB (U+0009) and LF (U+000A)
  if (rune >= 0x0000 && rune <= 0x001F && rune != 0x0009 && rune != 0x000A) {
    return true;
  }
  // DEL (U+007F)
  if (rune == 0x007F) return true;
  // C1 controls (U+0080-U+009F)
  if (rune >= 0x0080 && rune <= 0x009F) return true;
  return false;
}
