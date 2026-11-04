import 'package:coyhaique_basecamp_pt/core/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-04: la búsqueda no distingue mayúsculas ni tildes (casos PF-04).
void main() {
  test('quita tildes, eñes y mayúsculas', () {
    expect(normalizeForSearch('Café RÁFAGA'), 'cafe rafaga');
    expect(normalizeForSearch('Señal Ñandú'), 'senal nandu');
    expect(normalizeForSearch('Pingüino'), 'pinguino');
  });

  test('valores límite', () {
    expect(normalizeForSearch(null), '');
    expect(normalizeForSearch(''), '');
    expect(normalizeForSearch('  a  '), 'a');
    expect(normalizeForSearch('Reserva   Nacional'), 'reserva nacional');
  });

  test('un término sin tildes encuentra un nombre con tildes', () {
    expect(
      normalizeForSearch('Museo Regional de Aysén').contains(
        normalizeForSearch('aysen'),
      ),
      isTrue,
    );
  });
}
