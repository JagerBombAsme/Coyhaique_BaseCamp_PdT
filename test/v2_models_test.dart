import 'package:flutter_test/flutter_test.dart';
import 'package:coyhaique_basecamp_pt/core/models/category_model.dart';
import 'package:coyhaique_basecamp_pt/core/models/informational_content_dto.dart';
import 'package:coyhaique_basecamp_pt/features/categories/data/models/place_dto.dart';

void main() {
  group('Supabase V2 Models & Mappers Tests', () {
    test('CategoryModel.fromJson decodifica correctamente categories_v2', () {
      final jsonV2 = {
        'id': '082a68a4-55ee-4b32-bca0-afa7fa2e2e6b',
        'slug': 'turismo-gastronomico-industrial',
        'name_es': 'Turismo Gastronómico / Industrial',
        'name_en': 'Gastronomic Tourism',
        'description_es': 'Rutas y fábricas locales',
        'description_en': 'Local routes and factories',
        'group_type': 'atractivo',
        'image_url': 'https://example.com/cat.jpg',
        'is_active': true,
      };

      final cat = CategoryModel.fromJson(jsonV2);
      expect(cat.id, '082a68a4-55ee-4b32-bca0-afa7fa2e2e6b');
      expect(cat.slug, 'turismo-gastronomico-industrial');
      expect(cat.nameEs, 'Turismo Gastronómico / Industrial');
      expect(cat.nameEn, 'Gastronomic Tourism');
      expect(cat.name, 'Turismo Gastronómico / Industrial');
      expect(cat.getNombre('es'), 'Turismo Gastronómico / Industrial');
      expect(cat.getNombre('en'), 'Gastronomic Tourism');
      expect(cat.getDescripcion('es'), 'Rutas y fábricas locales');
      expect(cat.isActive, true);
    });

    test('PlaceDto.fromJson decodifica places_v2 y place_media_v2 relacionales', () {
      final jsonPlaceV2 = {
        'id': 'e2f9463b-ea7e-45a4-a5d2-feb88d1c2707',
        'category_id': '082a68a4-55ee-4b32-bca0-afa7fa2e2e6b',
        'kind': 'place',
        'name_es': "Cervecería D'Olbek (Fábrica y Tours)",
        'name_en': "D'Olbek Brewery",
        'description_es': 'Cervecería de tradición familiar.',
        'description_en': 'Family tradition brewery.',
        'address': 'General Baquedano 1899, Coyhaique.',
        'latitude': -45.57588,
        'longitude': -72.04345,
        'schedule': 'Lunes a Viernes 10:00 - 18:00',
        'reference_price': '\$10.000',
        'contact_info': '+56 9 7381 2369',
        'website_url': 'https://www.dolbek.cl/',
        'is_active': true,
        'place_media_v2': [
          {
            'id': 'media-1',
            'place_id': 'e2f9463b-ea7e-45a4-a5d2-feb88d1c2707',
            'external_url': 'https://example.com/photo1.jpg',
            'sort_order': 0,
            'is_active': true,
          },
          {
            'id': 'media-2',
            'place_id': 'e2f9463b-ea7e-45a4-a5d2-feb88d1c2707',
            'external_url': 'https://example.com/photo2.jpg',
            'sort_order': 1,
            'is_active': true,
          }
        ],
        'categories_v2': {
          'id': '082a68a4-55ee-4b32-bca0-afa7fa2e2e6b',
          'slug': 'gastronomia',
          'name_es': 'Gastronomía',
          'group_type': 'gastronomia',
        }
      };

      final place = PlaceDto.fromJson(jsonPlaceV2);
      expect(place.id, 'e2f9463b-ea7e-45a4-a5d2-feb88d1c2707');
      expect(place.kind, 'place');
      expect(place.nameEs, "Cervecería D'Olbek (Fábrica y Tours)");
      expect(place.nameEn, "D'Olbek Brewery");
      expect(place.name, "Cervecería D'Olbek (Fábrica y Tours)");
      expect(place.getTitle(true), "Cervecería D'Olbek (Fábrica y Tours)");
      expect(place.getTitle(false), "D'Olbek Brewery");
      expect(place.address, 'General Baquedano 1899, Coyhaique.');
      expect(place.schedule, 'Lunes a Viernes 10:00 - 18:00');
      expect(place.referencePrice, '\$10.000');
      expect(place.media.length, 2);
      expect(place.imageUrl, 'https://example.com/photo1.jpg');
      expect(place.category?.slug, 'gastronomia');
      expect(place.category?.groupType, 'gastronomia');
    });

    test('PlaceDto.fromJson maneja kind = activity correctamente', () {
      final jsonActivity = {
        'id': 'act-1',
        'category_id': '4f0071ae-dcaa-42cf-8684-fc94b0968f63',
        'kind': 'activity',
        'name_es': 'Cabalgatas en Valle Simpson',
        'name_en': 'Horseback Riding in Valle Simpson',
        'description_es': 'Recorrido a caballo por la estepa patagónica.',
        'description_en': 'Horseback riding through the Patagonian steppe.',
        'is_active': true,
      };

      final activity = PlaceDto.fromJson(jsonActivity);
      expect(activity.id, 'act-1');
      expect(activity.kind, 'activity');
      expect(activity.getTitle(true), 'Cabalgatas en Valle Simpson');
      expect(activity.getTitle(false), 'Horseback Riding in Valle Simpson');
    });

    test('InformationalContentDto.fromJson decodifica informational_content_v2', () {
      final jsonInfo = {
        'id': '00d94388-ade4-4cbf-b464-7d3714a1de81',
        'content_type': 'guia_transporte',
        'title': 'Guía: Transfer Compartido (Minibuses)',
        'category': 'Transporte / Guía',
        'description_es': 'Empresas oficiales licitadas por el aeropuerto.',
        'description_en': 'Airport authorized transfer services.',
        'reference_url': 'https://example.com/transfer',
        'schedule': '08:00 a 22:00 hrs',
        'reference_price': '\$9.000',
        'contact_info': '+56 9 93123939',
        'is_active': true,
      };

      final info = InformationalContentDto.fromJson(jsonInfo);
      expect(info.id, '00d94388-ade4-4cbf-b464-7d3714a1de81');
      expect(info.contentType, 'guia_transporte');
      expect(info.getTitle(true), 'Guía: Transfer Compartido (Minibuses)');
      expect(info.getTitle(false), 'Guía: Transfer Compartido (Minibuses)');
      expect(info.referencePrice, '\$9.000');
      expect(info.isActive, true);
    });
  });
}
