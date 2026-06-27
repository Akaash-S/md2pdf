class TextSanitizer {
  static const _map = <int, String>{
    0x2013: '-',    // – en dash
    0x2014: '--',   // — em dash
    0x2018: "'",    // ' left single quote
    0x2019: "'",    // ' right single quote
    0x201C: '"',    // " left double quote
    0x201D: '"',    // " right double quote
    0x2022: '*',    // • bullet
    0x2190: '<-',   // ← left arrow
    0x2192: '->',   // → right arrow
    0x2194: '<->',  // ↔ left-right arrow
    0x21D2: '=>',   // ⇒ right double arrow
    0x2248: '~=',   // ≈ almost equal
    0x2260: '!=',   // ≠ not equal
    0x2500: '-',    // ─ box draw horizontal
    0x2502: '|',    // │ box draw vertical
    0x250C: '+',    // ┌ box draw down-right
    0x2510: '+',    // ┐ box draw down-left
    0x2514: '+',    // └ box draw up-right
    0x2518: '+',    // ┘ box draw up-left
    0x251C: '+',    // ├ box draw vertical-right
    0x2524: '+',    // ┤ box draw vertical-left
    0x252C: '+',    // ┬ box draw down-horizontal
    0x2534: '+',    // ┴ box draw up-horizontal
    0x253C: '+',    // ┼ box draw cross
    0x2550: '=',    // ═ box draw double horizontal
    0x2551: '|',    // ║ box draw double vertical
    0x2588: '#',    // █ full block
    0x25A0: '#',    // ■ black square
    0x25B6: '>',    // ▶ play
    0x2713: 'v',    // ✓ check
    0x2714: 'V',    // ✔ heavy check
    0x2716: 'x',    // ✖ heavy multiply
    0x2717: 'X',    // ✗ ballot x
  };

  static String sanitize(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      buf.write(_map[rune] ?? String.fromCharCode(rune));
    }
    return buf.toString();
  }
}
