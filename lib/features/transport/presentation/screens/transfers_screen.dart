import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_scroll_back_bar.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/transfer_service.dart';
import '../../data/providers/transfer_providers.dart';
import '../../data/repository/transfer_repository.dart';
import '../widgets/transfer_widgets.dart';

/// Transfers hacia y desde el aeropuerto de Balmaceda (HU-18, pantalla 1).
///
/// El sentido lo fija la entrada y no se cambia dentro de la pantalla, para
/// que cada sentido muestre solo lo suyo. «Hacia el aeropuerto»: se reserva
/// con anticipación por WhatsApp con una empresa autorizada. «Desde el
/// aeropuerto»: guía para contratar y pagar en el counter antes de viajar.
/// La información es referencial.
class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key, this.fromAirport = false});

  /// true abre la guía «desde el aeropuerto»; por defecto se abre «hacia».
  final bool fromAirport;

  static const String _heroPhoto = 'assets/images/miradores_coyhaique.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toAirport = !fromAirport;
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final transfersAsync = ref.watch(airportTransfersProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: BcPinnedBackLayout(
          title: 'Transfer',
          backLabel: isSpanish ? 'Volver' : 'Back',
          onBack: () => context.pop(),
          child: RefreshIndicator(
          color: BcColors.ink,
          backgroundColor: BcColors.surface,
          onRefresh: () => ref.refresh(airportTransfersProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const BcPhotoImage(source: _heroPhoto),
                      const BcPhotoShade(topShade: 0.35),
                      Positioned(
                        left: BcSpace.gutter,
                        right: BcSpace.gutter,
                        bottom: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BcTag(
                              toAirport
                                  ? (isSpanish
                                        ? 'Hacia el aeropuerto · Balmaceda'
                                        : 'To the airport · Balmaceda')
                                  : (isSpanish
                                        ? 'Desde el aeropuerto · Balmaceda'
                                        : 'From the airport · Balmaceda'),
                            ),
                            const SizedBox(height: BcSpace.s3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'TRANSFER',
                                style: BcText.displayHero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.gutter,
                    BcSpace.gutter,
                    0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Tile(
                            dark: true,
                            children: [
                              // Distancia por la Ruta 245 hasta el centro.
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('55 KM', style: BcText.figure()),
                              ),
                              const SizedBox(height: BcSpace.s2),
                              Text(
                                isSpanish
                                    ? 'ENTRE EL AEROPUERTO Y EL CENTRO DE COYHAIQUE'
                                    : 'BETWEEN THE AIRPORT AND COYHAIQUE',
                                style: BcText.label(color: BcColors.onPhoto),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: BcSpace.s3),
                        Expanded(
                          child: _Tile(
                            children: [
                              Text(
                                isSpanish ? 'CÓMO FUNCIONA' : 'HOW IT WORKS',
                                style: BcText.label(color: BcColors.muted),
                              ),
                              const SizedBox(height: BcSpace.s2),
                              Text(
                                toAirport
                                    ? (isSpanish
                                          ? 'Reservas con anticipación por WhatsApp y la empresa confirma hora y tarifa.'
                                          : 'You book ahead by WhatsApp and the company confirms time and fare.')
                                    : (isSpanish
                                          ? 'Contratas en el counter del aeropuerto y pagas ahí, antes de viajar.'
                                          : 'You book at the airport counter and pay there, before you travel.'),
                                style: BcText.body(color: BcColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.section,
                    BcSpace.gutter,
                    0,
                  ),
                  child: _InfoCard(
                    icon: Icons.verified_user_rounded,
                    title: isSpanish
                        ? 'Solo servicios autorizados'
                        : 'Authorized services only',
                    text: toAirport
                        ? (isSpanish
                              ? 'Reserva solo con empresas que tengan vehículos habilitados. Usar un servicio ilegal a sabiendas puede tener multa de 1 a 3 UTM (Ley 21.787).'
                              : 'Book only with companies that have licensed vehicles. Knowingly using an illegal service can carry a fine of 1 to 3 UTM (Law 21,787).')
                        : (isSpanish
                              ? 'Contrata solo en el counter del aeropuerto y no aceptes ofertas de quienes te abordan en el terminal. Usar un servicio ilegal a sabiendas puede tener multa de 1 a 3 UTM (Ley 21.787).'
                              : 'Book only at the airport counter and do not accept offers from people who approach you in the terminal. Knowingly using an illegal service can carry a fine of 1 to 3 UTM (Law 21,787).'),
                  ),
                ),
              ),

              if (!toAirport)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.s3,
                    BcSpace.gutter,
                    0,
                  ),
                  child: _InfoCard(
                    icon: Icons.hotel_rounded,
                    title: isSpanish ? 'Antes de viajar' : 'Before you travel',
                    text: isSpanish
                        ? 'Encuentra tu alojamiento antes de viajar y contrata tu transfer con anticipación.'
                        : 'Find your lodging before you travel and book your transfer ahead of time.',
                    actionLabel: isSpanish
                        ? 'Ver alojamientos'
                        : 'See lodgings',
                    onAction: () => context.push('/categories/alojamiento'),
                  ),
                ),
              ),

              if (toAirport)
                ..._companySlivers(context, ref, isSpanish, toAirport, transfersAsync)
              else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.section,
                    BcSpace.gutter,
                    0,
                  ),
                  child: _CounterGuide(isSpanish: isSpanish),
                ),
              ),
                ..._companySlivers(context, ref, isSpanish, toAirport, transfersAsync),
              ],

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.s4,
                    BcSpace.gutter,
                    40,
                  ),
                  child: Text(
                    toAirport
                        ? (isSpanish
                              ? 'Información referencial. Confirma la tarifa y la hora con la empresa antes del viaje.'
                              : 'Reference information. Confirm the fare and time with the company before the trip.')
                        : (isSpanish
                              ? 'Información referencial. La tarifa final la informa el counter antes de pagar; cómo opera cada counter en el terminal se confirma en el lugar.'
                              : 'Reference information. The counter gives the final fare before you pay; how each counter works in the terminal is confirmed on site.'),
                    style: BcText.caption(),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// Encabezado y lista de empresas verificadas y habilitadas del sentido
  /// elegido, con su tarifa referencial y sus enlaces de contacto.
  List<Widget> _companySlivers(
    BuildContext context,
    WidgetRef ref,
    bool isSpanish,
    bool toAirport,
    AsyncValue<TransferListResult> transfersAsync,
  ) {
    return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.section,
                    BcSpace.gutter,
                    BcSpace.s3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isSpanish
                              ? 'EMPRESAS VERIFICADAS'
                              : 'VERIFIED COMPANIES',
                          style: BcText.displaySection,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        toAirport
                            ? (isSpanish
                                  ? 'Revisadas por el equipo; cada tarjeta indica cómo y cuándo. Reserva con anticipación; la empresa confirma la hora.'
                                  : 'Reviewed by the team; each card says how and when. Book ahead; the company confirms the time.')
                            : (isSpanish
                                  ? 'Revisadas por el equipo; cada tarjeta indica cómo y cuándo. Contáctalas antes de viajar o contrata en el counter.'
                                  : 'Reviewed by the team; each card says how and when. Contact them before you travel or book at the counter.'),
                        style: BcText.caption(),
                      ),
                    ],
                  ),
                ),
              ),

              ...transfersAsync.when<List<Widget>>(
                loading: () => [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: BcColors.ink),
                      ),
                    ),
                  ),
                ],
                error: (_, _) => [
                  SliverToBoxAdapter(
                    child: BcMessage(
                      icon: Icons.wifi_off_rounded,
                      text: isSpanish
                          ? 'No hay conexión ni fichas guardadas en el teléfono. Conéctate a Internet una vez para guardarlas.'
                          : 'There is no connection and no saved listings. Connect to the Internet once to save them.',
                      actionLabel: isSpanish ? 'Reintentar' : 'Try again',
                      onAction: () => ref.invalidate(airportTransfersProvider),
                    ),
                  ),
                ],
                data: (result) {
                  final services = result.services
                      .where((service) => service.serves(toAirport: toAirport))
                      .toList();
                  return [
                  if (result.fromCache)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          BcSpace.gutter,
                          0,
                          BcSpace.gutter,
                          BcSpace.s3,
                        ),
                        child: Text(
                          result.savedAt == null
                              ? (isSpanish
                                    ? 'Sin conexión: mostramos las fichas guardadas.'
                                    : 'Offline: showing saved listings.')
                              : (isSpanish
                                    ? 'Sin conexión: fichas guardadas el ${formatDate(result.savedAt!)}.'
                                    : 'Offline: listings saved on ${formatDate(result.savedAt!)}.'),
                          style: BcText.caption(color: BcColors.glacierDeep),
                        ),
                      ),
                    ),
                  if (services.isEmpty)
                    SliverToBoxAdapter(
                      child: BcMessage(
                        icon: Icons.airport_shuttle_rounded,
                        text: isSpanish
                            ? 'Todavía no hay empresas verificadas y habilitadas para este sentido.'
                            : 'There are no verified, licensed companies for this direction yet.',
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: services.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BcSpace.s3),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BcSpace.gutter,
                          ),
                          child: _TransferCard(
                            service: service,
                            isSpanish: isSpanish,
                            onPrepare: toAirport && service.canGenerateQr
                                ? () => context.push(
                                      transferRequestRoute(service.id),
                                    )
                                : null,
                          ),
                        );
                      },
                    ),
                ];
                },
              ),
    ];
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.children, this.dark = false});

  final List<Widget> children;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(BcSpace.s4),
      decoration: BoxDecoration(
        color: dark ? BcColors.ink : BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.service,
    required this.isSpanish,
    required this.onPrepare,
  });

  final TransferService service;
  final bool isSpanish;

  /// null cuando la empresa no recibe solicitudes por la app (sentido
  /// «desde» o sin WhatsApp habilitado): solo se muestran sus contactos.
  final VoidCallback? onPrepare;

  @override
  Widget build(BuildContext context) {
    final schedule = service.schedule(isSpanish);
    final fare = service.referenceFareClp;
    final verifiedOn = service.authorizationVerifiedDate;
    final source = service.authorizationSource;

    final payments = [
      if (service.acceptsCash) isSpanish ? 'Efectivo' : 'Cash',
      if (service.acceptsCard) isSpanish ? 'Tarjeta' : 'Card',
    ].join(' · ');

    final contacts = <Widget>[
      if (service.whatsappLink case final link?)
        _ContactButton(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          semanticLabel: isSpanish
              ? 'Escribir por WhatsApp a ${service.name}'
              : 'Message ${service.name} on WhatsApp',
          uri: link,
          isSpanish: isSpanish,
        ),
      if (service.phoneLink case final link?)
        _ContactButton(
          icon: Icons.call_rounded,
          label: isSpanish ? 'Llamar' : 'Call',
          semanticLabel: isSpanish
              ? 'Llamar a ${service.name}'
              : 'Call ${service.name}',
          uri: link,
          isSpanish: isSpanish,
        ),
      if (service.websiteLink case final link?)
        _ContactButton(
          icon: Icons.language_rounded,
          label: isSpanish ? 'Sitio web' : 'Website',
          semanticLabel: isSpanish
              ? 'Abrir el sitio web de ${service.name}'
              : 'Open the website of ${service.name}',
          uri: link,
          isSpanish: isSpanish,
        ),
    ];

    final publicSource = service.verificationLevel == 'fuente_publica';

    return Container(
      padding: const EdgeInsets.all(BcSpace.gutter),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Con fuente pública no se afirma la habilitación: solo que los
          // datos se revisaron en fuentes públicas (la inscripción en el
          // MTT puede estar pendiente, y así lo dice la fuente).
          BcTag(
            publicSource
                ? (isSpanish ? 'fuente pública' : 'public source')
                : (isSpanish ? 'y habilitada' : 'and licensed'),
            lead: isSpanish ? 'Verificada' : 'Verified',
            style: BcTagStyle.ink,
          ),
          const SizedBox(height: BcSpace.s2),
          Text(service.name.toUpperCase(), style: BcText.display(27)),
          const SizedBox(height: BcSpace.s4),
          TransferInfoRow(
            label: isSpanish ? 'Tarifa referencial' : 'Reference fare',
            value: fare == null
                ? (isSpanish ? 'Por confirmar' : 'To be confirmed')
                : formatClp(fare),
          ),
          TransferInfoRow(
            label: isSpanish ? 'Pago' : 'Payment',
            value: payments.isEmpty
                ? (isSpanish ? 'Por confirmar' : 'To be confirmed')
                : payments,
          ),
          TransferInfoRow(
            label: isSpanish ? 'Capacidad' : 'Capacity',
            value: service.capacity == null
                ? (isSpanish ? 'Por confirmar' : 'To be confirmed')
                : (isSpanish
                      ? '${service.capacity} pasajeros'
                      : '${service.capacity} passengers'),
          ),
          if (schedule != null)
            TransferInfoRow(
              label: isSpanish ? 'Atiende' : 'Service',
              value: schedule,
            ),
          const SizedBox(height: BcSpace.s1),
          Text(
            isSpanish
                ? 'La tarifa es referencial, no un precio definitivo: confírmala con la empresa.'
                : 'The fare is a reference, not a final price: confirm it with the company.',
            style: BcText.caption(),
          ),
          if (verifiedOn != null) ...[
            const SizedBox(height: BcSpace.s1),
            Text(
              [
                publicSource
                    ? (isSpanish
                          ? 'Datos revisados en fuentes públicas el ${formatDate(verifiedOn)}.'
                          : 'Details checked in public sources on ${formatDate(verifiedOn)}.')
                    : (isSpanish
                          ? 'Habilitación verificada el ${formatDate(verifiedOn)}.'
                          : 'Licence verified on ${formatDate(verifiedOn)}.'),
                if (source != null)
                  isSpanish
                      ? 'Fuente: ${_withoutFinalPeriod(source)}.'
                      : 'Source: ${_withoutFinalPeriod(source)}.',
              ].join(' '),
              style: BcText.caption(),
            ),
          ],
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: BcSpace.s4),
            Wrap(
              spacing: BcSpace.s2,
              runSpacing: BcSpace.s2,
              children: contacts,
            ),
          ],
          if (onPrepare != null) ...[
            const SizedBox(height: BcSpace.s4),
            BcButton(
              label: isSpanish ? 'Preparar solicitud' : 'Prepare request',
              icon: Icons.chevron_right_rounded,
              onPressed: onPrepare,
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón de contacto que abre un enlace (WhatsApp, teléfono o sitio web) en
/// la aplicación correspondiente.
class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.uri,
    required this.isSpanish,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final Uri uri;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: () => _openContact(context, uri, isSpanish),
      semanticLabel: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: BcColors.fog,
          borderRadius: BorderRadius.circular(BcRadius.control),
          border: Border.all(color: BcColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: BcColors.ink),
            const SizedBox(width: 8),
            Text(label, style: BcText.title()),
          ],
        ),
      ),
    );
  }
}

Future<void> _openContact(BuildContext context, Uri uri, bool isSpanish) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (opened) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        isSpanish
            ? 'No se pudo abrir el enlace de contacto.'
            : 'Could not open the contact link.',
      ),
    ),
  );
}

/// Tarjeta informativa con ícono, título, texto y, si se pide, un botón.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BcSpace.s4),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: BcColors.glacierDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title.toUpperCase(), style: BcText.label()),
                ),
              ),
            ],
          ),
          const SizedBox(height: BcSpace.s2),
          Text(text, style: BcText.body(color: BcColors.ink)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: BcSpace.s3),
            BcButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Guía para contratar en el counter del aeropuerto. Los counters solo
/// pueden vender viajes ya pagados (Ley 21.787, art. 9 bis).
class _CounterGuide extends StatelessWidget {
  const _CounterGuide({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final steps = isSpanish
        ? const [
            'Ve al counter del servicio de transporte dentro del terminal.',
            'Indica tu destino y cuántas personas viajan, y confirma la tarifa.',
            'Paga en el counter (la recepción del servicio) antes de viajar y guarda el comprobante.',
            'Sube solo al vehículo de la empresa que te atendió. No aceptes ofertas fuera del counter.',
          ]
        : const [
            'Go to the transport service counter inside the terminal.',
            'Say where you are going and how many people travel, and confirm the fare.',
            'Pay at the counter (the service desk) before you travel and keep the receipt.',
            'Get in only the vehicle of the company that served you. Do not accept offers away from the counter.',
          ];

    return Container(
      padding: const EdgeInsets.all(BcSpace.gutter),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              (isSpanish
                      ? 'Cómo contratar en el aeropuerto'
                      : 'How to book at the airport')
                  .toUpperCase(),
              style: BcText.label(),
            ),
          ),
          const SizedBox(height: BcSpace.s2),
          Text(
            isSpanish
                ? 'Los counters del aeropuerto solo pueden vender viajes ya pagados: el pago se hace ahí, antes de viajar.'
                : 'Airport counters can only sell rides that are already paid: you pay there, before you travel.',
            style: BcText.body(color: BcColors.ink),
          ),
          const SizedBox(height: BcSpace.s4),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: BcColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: BcText.label(color: BcColors.onPhoto),
                  ),
                ),
                const SizedBox(width: BcSpace.s3),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      steps[i],
                      style: BcText.body(color: BcColors.ink),
                    ),
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1) const SizedBox(height: BcSpace.s3),
          ],
        ],
      ),
    );
  }
}

/// Quita el punto final de un texto que se inserta antes de otro punto, para
/// no mostrar «..» cuando la fuente ya termina en punto.
String _withoutFinalPeriod(String text) {
  final trimmed = text.trimRight();
  return trimmed.endsWith('.')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
