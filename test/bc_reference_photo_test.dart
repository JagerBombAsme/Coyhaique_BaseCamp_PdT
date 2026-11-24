import 'package:coyhaique_basecamp_pt/core/widgets/basecamp/bc_widgets.dart';
import 'package:coyhaique_basecamp_pt/features/categories/data/models/place_dto.dart';
import 'package:coyhaique_basecamp_pt/features/planner/data/models/itinerary_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <(String, String, String, String)>[
    ('cafeterias', 'Cafeterías', 'Cafés', 'gastronomia'),
    ('restaurantes', 'Restaurantes', 'Restaurants', 'gastronomia'),
    ('comida-tradicional', 'Comida tradicional y patagónica',
      'Traditional and Patagonian food', 'gastronomia'),
    ('fuentes-de-soda', 'Fuentes de soda y colaciones',
      'Diners and set lunches', 'gastronomia'),
    ('hoteles', 'Hoteles', 'Hotels', 'alojamiento'),
    ('cabanas', 'Cabañas', 'Cabins', 'alojamiento'),
    ('departamentos', 'Departamentos turísticos', 'Holiday apartments',
      'alojamiento'),
    ('buses', 'Buses', 'Buses', 'transporte'),
    ('rent-a-car', 'Rent a car', 'Car rental', 'transporte'),
    ('bencineras', 'Bencineras', 'Gas stations', 'servicios'),
    ('estacionamientos', 'Estacionamientos', 'Parking', 'servicios'),
    ('banos-publicos', 'Baños públicos', 'Public restrooms', 'servicios'),
    ('agencias-de-viaje', 'Agencias de viaje', 'Travel agencies', 'servicios'),
  ];

  for (final (slug, es, en, folder) in cases) {
    test('subcategoría $slug resuelve su asset en ambos idiomas', () {
      final expected = 'assets/images/fallback/$folder/$slug.jpg';
      expect(bcReferenceAsset(slug), expected);
      expect(bcReferenceAsset(es), expected);
      expect(bcReferenceAsset(en), expected);
      expect(bcReferenceAsset('$slug $folder $es'), expected);
    });
  }

  test('prioriza slug y aliases específicos frente al grupo general', () {
    expect(bcReferenceAsset('cafeterias gastronomia Restaurante'),
        endsWith('gastronomia/cafeterias.jpg'));
    expect(bcReferenceAsset('Restaurante / Comida Casera y Tradicional'),
        endsWith('gastronomia/comida-tradicional.jpg'));
    expect(bcReferenceAsset('Servicios Básicos / Estación de Servicio'),
        endsWith('servicios/bencineras.jpg'));
  });

  test('planificador conserva slug sin cambiar el ID del interés', () {
    final dto = PlaceDto.fromJson({
      'id': 'place-1', 'kind': 'place', 'name_es': 'Café de prueba',
      'category_id': 'sub-1',
      'categories_v2': {
        'id': 'sub-1', 'parent_id': 'main-1', 'slug': 'cafeterias',
        'name_es': 'Cafeterías', 'group_type': 'gastronomia',
      },
    });
    final place = plannerPlaceFromDto(dto);
    expect(place.categoryId, 'main-1');
    expect(place.categorySlug, 'cafeterias');
    expect(bcReferenceAsset(place.categorySlug),
        endsWith('gastronomia/cafeterias.jpg'));
  });

  testWidgets('las 13 imágenes específicas están incluidas en assets',
      (tester) async {
    for (final (slug, _, _, _) in cases) {
      final asset = await rootBundle.load(bcReferenceAsset(slug));
      expect(asset.lengthInBytes, greaterThan(0));
    }
  });

  test('resuelve categorías con tildes, inglés y valores desconocidos', () {
    expect(bcReferenceAsset('Gastronomía'), endsWith('gastronomia_fogon.jpg'));
    expect(bcReferenceAsset('Accommodation'), endsWith('alojamiento_hotel.jpg'));
    expect(bcReferenceAsset('Museo'), endsWith('cultura_gaucho.jpg'));
    expect(bcReferenceAsset('Reserva natural'), endsWith('nature_green_forest.jpg'));
    expect(bcReferenceAsset('Aventura'), endsWith('mountain_hike.jpg'));
    expect(bcReferenceAsset('Transporte'), endsWith('miradores_coyhaique.jpg'));
    expect(bcReferenceAsset(null), endsWith('cerro_castillo_panoramico.jpg'));
  });

  testWidgets('todos los respaldos están incluidos en assets', (tester) async {
    for (final category in ['gastronomia', 'alojamiento', 'cultura', 'naturaleza', 'aventura', 'transporte', '']) {
      final asset = await rootBundle.load(bcReferenceAsset(category));
      expect(asset.lengthInBytes, greaterThan(0));
    }
  });

  Future<void> pumpPhoto(WidgetTester tester, String source, {String? category = 'gastronomia'}) async {
    await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox(
      width: 220, height: 160,
      child: BcPhotoImage(source: source, fallbackCategory: category),
    ))));
    await tester.pump();
  }

  for (final source in ['', '  ', 'null', 'n/a', 'https://', 'not-a-url']) {
    testWidgets('respaldo para fuente inválida: $source', (tester) async {
      await pumpPhoto(tester, source);
      expect(find.byType(BcReferencePhoto), findsOneWidget);
      expect(find.text('Imagen referencial'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('una cafetería sin foto muestra su respaldo específico',
      (tester) async {
    await pumpPhoto(tester, '', category: 'cafeterias gastronomia');
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;
    final asset = provider is ResizeImage ? provider.imageProvider : provider;
    expect((asset as AssetImage).assetName,
        'assets/images/fallback/gastronomia/cafeterias.jpg');
    expect(find.text('Imagen referencial'), findsOneWidget);
  });

  testWidgets('una fuente local válida conserva prioridad', (tester) async {
    await pumpPhoto(tester, 'assets/images/cerro_mckay.jpg');
    expect(find.byType(BcReferencePhoto), findsNothing);
  });

  testWidgets('una galería sin respaldo opt-in conserva el logo', (tester) async {
    await pumpPhoto(tester, '', category: null);
    expect(find.byType(BcLogoPlaceholder), findsOneWidget);
    expect(find.byType(BcReferencePhoto), findsNothing);
  });
}
