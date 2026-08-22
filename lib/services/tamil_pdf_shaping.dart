/// The `pdf` package renders glyphs strictly in logical (memory) order and
/// does not perform complex-script shaping. Tamil Unicode stores certain
/// vowel signs AFTER their consonant in logical order even though they must
/// be drawn BEFORE the consonant (and some vowel signs split into a
/// before+after pair). Without shaping, PDF output shows them in the wrong
/// visual position (e.g. "பெயர்" renders as "பயெர்").
///
/// This reorders the string so that feeding it, character-by-character, to a
/// naive left-to-right renderer produces the visually correct result. Only
/// used for PDF export — screen rendering (Flutter/Skia) already shapes
/// Tamil correctly, so this must NOT be applied anywhere in the UI.
String reorderTamilForPdf(String text) {
  const preBase = {'\u0BC6', '\u0BC7', '\u0BC8'}; // ெ ே ை
  const twoPart = {
    '\u0BCA': ['\u0BC6', '\u0BBE'], // ொ = ெ + ா
    '\u0BCB': ['\u0BC7', '\u0BBE'], // ோ = ே + ா
    '\u0BCC': ['\u0BC6', '\u0BD7'], // ௌ = ெ + ௗ
  };

  final chars = text.split('');
  final out = <String>[];

  for (var i = 0; i < chars.length; i++) {
    final ch = chars[i];
    if (out.isNotEmpty && twoPart.containsKey(ch)) {
      final prevConsonant = out.removeLast();
      out.add(twoPart[ch]![0]);
      out.add(prevConsonant);
      out.add(twoPart[ch]![1]);
    } else if (out.isNotEmpty && preBase.contains(ch)) {
      final prevConsonant = out.removeLast();
      out.add(ch);
      out.add(prevConsonant);
    } else {
      out.add(ch);
    }
  }
  return out.join();
}
