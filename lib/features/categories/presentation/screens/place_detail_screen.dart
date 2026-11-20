import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/place_dto.dart';
import '../../data/providers/places_provider.dart';
import '../widgets/place_editorial_widgets.dart';

/// Ficha de un lugar o actividad con composición editorial: foto a pantalla,
/// texto, galería, datos prácticos y una barra de acciones.
class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  final VoidCallback onBack;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.onBack,
  });

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  bool _isReloading = false;

  /// Ancla de «Información práctica», a la que lleva el botón Información.
  final GlobalKey _infoKey = GlobalKey();

  Future<void> _reloadPlace({bool showMessage = false}) async {
    if (_isReloading) {
      return;
    }

    setState(() {
      _isReloading = true;
    });

    try {
      final provider = placeDetailProvider(widget.placeId);

      ref.invalidate(provider);

      await ref.read(provider.future);

      if (!mounted) {
        return;
      }

      if (showMessage) {
        final locale = ref.read(languageProvider);

        final isSpanish = locale.languageCode == 'es';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish ? 'Información actualizada.' : 'Information updated.',
            ),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final locale = ref.read(languageProvider);

      final isSpanish = locale.languageCode == 'es';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No fue posible actualizar la información.'
                : 'Could not update information.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReloading = false;
        });
      }
    }
  }

  // ================================================================
  // ACCIONES
  // ================================================================

  /// Cómo llegar: abre el mapa sobre este lugar, donde ya existen las rutas
  /// a pie y en auto.
  void _openDirections(PlaceDto place) {
    context.go(Uri(path: '/map', queryParameters: {'lugar': place.id}).toString());
  }

  Future<void> _openWebsite(String raw, bool isSpanish) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = raw.trim();
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');

    var opened = false;
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (error) {
        debugPrint('No se pudo abrir $uri: $error');
      }
    }

    if (!opened && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No se pudo abrir la página web.'
                : 'Could not open the website.',
          ),
        ),
      );
    }
  }

  void _showSchedule(String schedule, bool isSpanish) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BcColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BcRadius.card),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BcSpace.gutter,
              BcSpace.s2,
              BcSpace.gutter,
              BcSpace.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PlaceSectionTitle(isSpanish ? 'Horario' : 'Hours'),
                const SizedBox(height: BcSpace.s4),
                Text(
                  schedule.trim(),
                  style: BcText.body(
                    color: BcColors.ink,
                  ).copyWith(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToInfo() {
    final target = _infoKey.currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _openPhoto(List<String> photos, int index, bool isSpanish) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PlacePhotoViewer(
          urls: photos,
          initialIndex: index,
          closeLabel: isSpanish ? 'Cerrar' : 'Close',
        ),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    final isSpanish = locale.languageCode == 'es';

    final placeAsync = ref.watch(placeDetailProvider(widget.placeId));

    final place = placeAsync.valueOrNull;

    return Scaffold(
      backgroundColor: BcColors.surface,

      body: placeAsync.when(
        data: (place) {
          if (place == null) {
            return _StateView(
              icon: Icons.search_off_rounded,
              title: isSpanish ? 'Lugar no encontrado' : 'Place not found',
              retryLabel: isSpanish ? 'Reintentar' : 'Retry',
              backLabel: isSpanish ? 'Volver' : 'Back',
              isBusy: _isReloading,
              onRetry: () => _reloadPlace(showMessage: true),
              onBack: widget.onBack,
            );
          }

          return _buildContent(context, place, isSpanish);
        },

        loading: () {
          return SafeArea(
            child: Stack(
              children: [
                const Center(
                  child: CircularProgressIndicator(color: BcColors.glacierDeep),
                ),
                PositionedDirectional(
                  top: BcSpace.s3,
                  start: BcSpace.gutter,
                  child: BcCornerButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: isSpanish ? 'Volver' : 'Back',
                    onTap: widget.onBack,
                  ),
                ),
              ],
            ),
          );
        },

        error: (error, stackTrace) {
          debugPrint('ERROR PlaceDetailScreen: $error');

          return _StateView(
            icon: Icons.error_outline_rounded,
            title: isSpanish
                ? 'No pudimos cargar este lugar'
                : 'We could not load this place',
            message: isSpanish
                ? 'Revisa tu conexión e inténtalo de nuevo.'
                : 'Check your connection and try again.',
            retryLabel: isSpanish ? 'Reintentar' : 'Retry',
            backLabel: isSpanish ? 'Volver' : 'Back',
            isBusy: _isReloading,
            onRetry: () => _reloadPlace(showMessage: true),
            onBack: widget.onBack,
          );
        },
      ),

      bottomNavigationBar: place == null ? null : _buildActionBar(place, isSpanish),
    );
  }

  // ================================================================
  // CONTENIDO
  // ================================================================

  Widget _buildContent(BuildContext context, PlaceDto place, bool isSpanish) {
    final language = isSpanish ? 'es' : 'en';
    final title = place.getTitle(isSpanish);
    // Frase propia del lugar. No se usa getSubtitle(): devuelve la
    // descripción cuando existe y la repetiría justo encima de ella.
    final subtitle = isSpanish
        ? place.subtitleEs
        : (placeHasText(place.subtitleEn) ? place.subtitleEn : place.subtitleEs);
    final description = place.getDescription(isSpanish);

    final photos = placePhotoUrls(place);
    final heroUrl = photos.isEmpty ? null : photos.first;
    final gallery = photos.length > 1 ? photos.sublist(1) : <String>[];

    final heroHeight = (MediaQuery.sizeOf(context).height * 0.6).clamp(
      380.0,
      600.0,
    );

    final categoryName = place.category?.getNombre(language);
    final categoryLabel = placeHasText(categoryName)
        ? categoryName!
        : (placeHasText(place.categorySlug)
              ? place.categorySlug!.replaceAll('-', ' ')
              : (isSpanish ? 'Lugar' : 'Place'));

    final kindLabel = place.kind == 'activity'
        ? (isSpanish ? 'Actividad' : 'Activity')
        : (isSpanish ? 'Atractivo' : 'Attraction');

    return RefreshIndicator(
      onRefresh: () => _reloadPlace(),
      color: BcColors.glacierDeep,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlaceHero(
              title: title,
              categoryLabel: categoryLabel,
              photoUrl: heroUrl,
              height: heroHeight,
              backLabel: isSpanish ? 'Volver' : 'Back',
              reloadLabel: isSpanish ? 'Actualizar' : 'Refresh',
              onBack: widget.onBack,
              onReload: _isReloading
                  ? null
                  : () => _reloadPlace(showMessage: true),
            ),

            PlaceLede(kicker: kindLabel, lede: subtitle),

            PlaceAboutSection(
              heading: isSpanish ? 'Sobre el lugar' : 'About this place',
              description: description,
              emptyText: isSpanish
                  ? 'No hay descripción disponible.'
                  : 'No description available.',
              moreLabel: isSpanish ? 'Leer más' : 'Read more',
              lessLabel: isSpanish ? 'Leer menos' : 'Read less',
            ),

            PlaceGallery(
              heading: isSpanish ? 'Galería' : 'Gallery',
              countLabel: isSpanish
                  ? '${photos.length} fotos'
                  : '${photos.length} photos',
              urls: gallery,
              photoLabel: (index) => isSpanish
                  ? 'Foto ${index + 2} de ${photos.length}'
                  : 'Photo ${index + 2} of ${photos.length}',
              onOpen: (index) => _openPhoto(photos, index + 1, isSpanish),
            ),

            KeyedSubtree(
              key: _infoKey,
              child: PlaceFacts(
                heading: isSpanish ? 'Información práctica' : 'Practical information',
                facts: _facts(place, isSpanish),
                disclaimer: isSpanish
                    ? 'La información mostrada es referencial. Se recomienda verificar horarios, precios y disponibilidad directamente con el prestador antes de realizar la visita.'
                    : 'The information shown is for reference. It is recommended to verify schedules, prices and availability directly with the provider before visiting.',
                verification: _verificationText(
                  place.lastVerifiedDate,
                  isSpanish,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Solo los datos que el lugar realmente tiene.
  List<PlaceFact> _facts(PlaceDto place, bool isSpanish) {
    return [
      if (placeHasText(place.address))
        PlaceFact(isSpanish ? 'Ubicación' : 'Location', place.address!.trim()),
      if (placeHasText(place.schedule))
        PlaceFact(isSpanish ? 'Horario' : 'Hours', place.schedule!.trim()),
      if (placeHasText(place.referencePrice))
        PlaceFact(
          isSpanish ? 'Precio referencial' : 'Reference price',
          place.referencePrice!.trim(),
        ),
      if (placeHasText(place.meetingPoint))
        PlaceFact(
          isSpanish ? 'Punto de encuentro' : 'Meeting point',
          place.meetingPoint!.trim(),
        ),
    ];
  }

  Widget _buildActionBar(PlaceDto place, bool isSpanish) {
    final hasCoordinates = place.latitude != null && place.longitude != null;
    final hasSchedule = placeHasText(place.schedule);
    final hasWebsite = placeHasText(place.websiteUrl);
    final hasFacts = _facts(place, isSpanish).isNotEmpty;

    return PlaceActionBar(
      directionsLabel: isSpanish ? 'Cómo llegar' : 'Get directions',
      scheduleLabel: isSpanish ? 'Horario' : 'Hours',
      websiteLabel: isSpanish ? 'Página web' : 'Website',
      infoLabel: isSpanish ? 'Información' : 'Info',
      onDirections: hasCoordinates ? () => _openDirections(place) : null,
      onSchedule: hasSchedule
          ? () => _showSchedule(place.schedule!, isSpanish)
          : null,
      onWebsite: hasWebsite
          ? () => _openWebsite(place.websiteUrl!, isSpanish)
          : null,
      onInfo: hasFacts ? _scrollToInfo : null,
    );
  }

  // ================================================================
  // TEXTO DE VERIFICACIÓN
  // ================================================================
  String _verificationText(DateTime? date, bool isSpanish) {
    if (date == null) {
      return isSpanish
          ? 'Fecha de verificación no disponible.'
          : 'Verification date not available.';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final formatted = '$day-$month-${date.year}';
    return isSpanish
        ? 'Fecha de verificación: $formatted'
        : 'Verification date: $formatted';
  }
}

/// Pantalla de «no encontrado» o de error, con reintento y volver.
class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.retryLabel,
    required this.backLabel,
    required this.isBusy,
    required this.onRetry,
    required this.onBack,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String retryLabel;
  final String backLabel;
  final bool isBusy;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BcSpace.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: BcColors.muted),
              const SizedBox(height: BcSpace.s4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: BcText.title().copyWith(fontSize: 20),
              ),
              if (message != null) ...[
                const SizedBox(height: BcSpace.s2),
                Text(message!, textAlign: TextAlign.center, style: BcText.body()),
              ],
              const SizedBox(height: BcSpace.section),
              BcButton(
                label: retryLabel,
                icon: Icons.refresh_rounded,
                isLoading: isBusy,
                onPressed: onRetry,
              ),
              const SizedBox(height: BcSpace.s2),
              BcButton(
                label: backLabel,
                style: BcButtonStyle.surface,
                onPressed: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
