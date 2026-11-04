import 'package:coyhaique_basecamp_pt/core/local/catalog_local_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pruebas unitarias de la copia local del catálogo (HU-09, HU-10, RNF-04).
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = CatalogLocalDb.instance;

  Map<String, dynamic> place(String id, String kind, String categoryId) => {
        'id': id,
        'kind': kind,
        'category_id': categoryId,
        'name_es': 'Lugar $id',
        'is_active': true,
        'place_media_v2': <dynamic>[],
        'categories_v2': {'id': categoryId, 'slug': 'cat', 'name_es': 'Cat'},
      };

  setUp(() async => db.deleteForTesting());

  test('sin descarga no hay copia local', () async {
    expect(await db.hasData(), isFalse);
    expect(await db.getLastSyncAt(), isNull);
  });

  test('guarda y lee el catálogo con su fecha', () async {
    final date = DateTime(2026, 11, 3, 10, 30);
    await db.replaceAll(
      categories: [
        {'id': 'c1', 'name_es': 'Gastronomía', 'group_type': 'gastronomia'},
      ],
      places: [place('p1', 'place', 'c1'), place('a1', 'activity', 'c1')],
      informationalContent: [
        {'id': 'i1', 'content_type': 'prevencion', 'title': 'Fuego'},
      ],
      syncedAt: date,
    );

    expect(await db.hasData(), isTrue);
    expect(await db.getLastSyncAt(), date);
    expect((await db.getPlaces(kind: 'place')).single['id'], 'p1');
    expect((await db.getPlaces(kind: 'activity')).single['id'], 'a1');
    expect((await db.getPlaces(categoryId: 'c1')).length, 2);
    expect((await db.getPlaceById('p1'))?['categories_v2']['id'], 'c1');
    expect(
      (await db.getInformationalContent(contentType: 'prevencion')).length,
      1,
    );
  });

  test('una nueva descarga reemplaza la copia anterior', () async {
    await db.replaceAll(
      categories: [],
      places: [place('p1', 'place', 'c1'), place('p2', 'place', 'c1')],
      informationalContent: [],
      syncedAt: DateTime(2026, 11, 1),
    );
    await db.replaceAll(
      categories: [],
      places: [place('p3', 'place', 'c1')],
      informationalContent: [],
      syncedAt: DateTime(2026, 11, 2),
    );

    final places = await db.getPlaces();
    expect(places.map((p) => p['id']), ['p3']);
    expect(await db.getLastSyncAt(), DateTime(2026, 11, 2));
  });

  test('si la descarga falla se conserva la copia anterior', () async {
    await db.replaceAll(
      categories: [],
      places: [place('p1', 'place', 'c1')],
      informationalContent: [],
      syncedAt: DateTime(2026, 11, 1),
    );

    // Dos registros con el mismo id provocan un error dentro de la transacción.
    await expectLater(
      db.replaceAll(
        categories: [],
        places: [place('x', 'place', 'c1'), place('x', 'place', 'c1')],
        informationalContent: [],
        syncedAt: DateTime(2026, 11, 2),
      ),
      throwsA(anything),
    );

    expect((await db.getPlaces()).map((p) => p['id']), ['p1']);
    expect(await db.getLastSyncAt(), DateTime(2026, 11, 1));
  });
}
