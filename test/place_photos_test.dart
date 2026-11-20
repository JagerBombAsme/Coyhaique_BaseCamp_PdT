import 'package:coyhaique_basecamp_pt/features/categories/data/models/place_dto.dart';
import 'package:coyhaique_basecamp_pt/features/categories/presentation/widgets/place_editorial_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceDto _place({String? imageUrl, List<String?> media = const []}) {
  return PlaceDto(
    id: 'p1',
    categoryId: 'c1',
    titleEs: 'Lugar',
    imageUrl: imageUrl,
    media: [
      for (var i = 0; i < media.length; i++)
        PlaceMediaDto(
          id: 'm$i',
          placeId: 'p1',
          externalUrl: media[i],
          sortOrder: i,
        ),
    ],
  );
}

void main() {
  group('placeHasText', () {
    test('rechaza null, vacío, "null" y "n/a"', () {
      expect(placeHasText(null), isFalse);
      expect(placeHasText('   '), isFalse);
      expect(placeHasText('null'), isFalse);
      expect(placeHasText('N/A'), isFalse);
    });

    test('acepta texto real', () {
      expect(placeHasText('Lunes a viernes'), isTrue);
    });
  });

  group('placePhotoUrls', () {
    test('sin fotos devuelve lista vacía', () {
      expect(placePhotoUrls(_place()), isEmpty);
    });

    test('la portada va primero y no se repite si está en media', () {
      final urls = placePhotoUrls(
        _place(imageUrl: 'https://x/a.jpg', media: ['https://x/a.jpg', 'https://x/b.jpg']),
      );
      expect(urls, ['https://x/a.jpg', 'https://x/b.jpg']);
    });

    test('sin portada usa la primera foto de media', () {
      final urls = placePhotoUrls(_place(media: ['https://x/b.jpg']));
      expect(urls, ['https://x/b.jpg']);
    });

    test('ignora URLs vacías y repetidas dentro de media', () {
      final urls = placePhotoUrls(
        _place(media: ['', null, 'https://x/b.jpg', ' https://x/b.jpg ']),
      );
      expect(urls, ['https://x/b.jpg']);
    });
  });
}
