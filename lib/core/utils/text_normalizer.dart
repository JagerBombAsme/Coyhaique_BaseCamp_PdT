/// Normaliza texto para búsquedas: minúsculas, sin tildes ni diéresis y sin
/// espacios repetidos (HU-04: la búsqueda no distingue mayúsculas ni tildes).
String normalizeForSearch(String? text) {
  if (text == null || text.isEmpty) return '';

  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';

  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }

  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
