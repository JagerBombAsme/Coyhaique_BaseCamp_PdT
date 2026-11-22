import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/transfer_service.dart';
import '../../data/providers/transfer_providers.dart';
import '../widgets/transfer_widgets.dart';

/// Transfers hacia y desde el aeropuerto de Balmaceda (HU-18, pantalla 1).
///
/// «Hacia el aeropuerto» va primero: se reserva con anticipación por
/// WhatsApp con una empresa autorizada. «Desde el aeropuerto» es una guía:
/// se contrata y se paga en el counter antes de viajar. En ambos casos la
/// información es referencial y se recuerda contratar solo servicios
/// autorizados.
class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key, this.fromAirport = false});

  /// true para abrir directamente la guía «desde el aeropuerto» (por ejemplo,
  /// cuando el usuario está en el aeropuerto). Por defecto se abre «hacia».
  final bool fromAirport;

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  static const String _heroPhoto = 'assets/images/miradores_coyhaique.jpg';

  late bool _toAirport = !widget.fromAirport;

  @override
  Widget build(BuildContext context) {
    final toAirport = _toAirport;
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final transfersAsync = ref.watch(airportTransfersProvider);
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: RefreshIndicator(
          color: BcColors.ink,
          backgroundColor: BcColors.surface,
          edgeOffset: topPadding,
          onRefresh: () => ref.refresh(airportTransfersProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320 + topPadding,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const BcPhotoImage(source: _heroPhoto),
                      const BcPhotoShade(topShade: 0.35),
                      Positioned(
                        top: topPadding + 12,
                        left: BcSpace.gutter,
                        child: BcCornerButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: isSpanish ? 'Volver' : 'Back',
                          onTap: () => context.pop(),
                        ),
                      ),
                      Positioned(
                        left: BcSpace.gutter,
                        right: BcSpace.gutter,
                        bottom: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BcTag(
                              isSpanish
                                  ? 'Aeropuerto Balmaceda · Coyhaique'
                                  : 'Balmaceda Airport · Coyhaique',
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
                  child: TransferTwoColumns(
                    children: [
                      TransferOption(
                        label: isSpanish
                            ? 'Hacia el aeropuerto'
                            : 'To the airport',
                        selected: toAirport,
                        onTap: () => setState(() => _toAirport = true),
                      ),
                      TransferOption(
                        label: isSpanish
                            ? 'Desde el aeropuerto'
                            : 'From the airport',
                        selected: !toAirport,
                        onTap: () => setState(() => _toAirport = false),
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
                    text: isSpanish
                        ? 'Contrata solo empresas con vehículos habilitados y no aceptes ofertas de quienes te abordan en el terminal. Usar un servicio ilegal a sabiendas puede tener multa de 1 a 3 UTM (Ley 21.787).'
                        : 'Book only companies with licensed vehicles and do not accept offers from people who approach you at the terminal. Knowingly using an illegal service can carry a fine of 1 to 3 UTM (Law 21,787).',
                  ),
                ),
              ),

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

              if (toAirport) ...[
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
                          isSpanish ? 'EMPRESAS' : 'COMPANIES',
                          style: BcText.displaySection,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSpanish
                            ? 'Reserva con anticipación; la empresa confirma la hora'
                            : 'Book ahead; the company confirms the time',
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
                data: (result) => [
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
                  if (result.services.isEmpty)
                    SliverToBoxAdapter(
                      child: BcMessage(
                        icon: Icons.airport_shuttle_rounded,
                        text: isSpanish
                            ? 'Todavía no hay empresas de transfer publicadas.'
                            : 'No transfer companies are listed yet.',
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: result.services.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: BcSpace.s3),
                      itemBuilder: (context, index) {
                        final service = result.services[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BcSpace.gutter,
                          ),
                          child: _TransferCard(
                            service: service,
                            isSpanish: isSpanish,
                            onPrepare: () =>
                                context.push(transferRequestRoute(service.id)),
                          ),
                        );
                      },
                    ),
                ],
              ),
              ] else ...[
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
    );
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
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    final schedule = service.schedule(isSpanish);
    final fare = service.referenceFareClp;

    final payments = [
      if (service.acceptsCash) isSpanish ? 'Efectivo' : 'Cash',
      if (service.acceptsCard) isSpanish ? 'Tarjeta' : 'Card',
    ].join(' · ');

    final (tagLead, tagText) = switch (service.verificationLevel) {
      'establecimiento' => (
        isSpanish ? 'Verificado' : 'Verified',
        isSpanish ? 'por la empresa' : 'by the company',
      ),
      'fuente_publica' => (
        isSpanish ? 'Fuente' : 'Source',
        isSpanish ? 'pública' : 'public',
      ),
      _ => (
        isSpanish ? 'Pendiente' : 'Pending',
        isSpanish ? 'de validación' : 'validation',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(BcSpace.gutter),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BcTag(tagText, lead: tagLead, style: BcTagStyle.ink),
          const SizedBox(height: BcSpace.s2),
          Text(service.name.toUpperCase(), style: BcText.display(27)),
          const SizedBox(height: BcSpace.s4),
          TransferInfoRow(
            label: isSpanish ? 'Tarifa al centro' : 'Fare to the centre',
            value: fare == null
                ? (isSpanish ? 'Por confirmar' : 'To be confirmed')
                : formatClp(fare),
          ),
          TransferInfoRow(
            label: isSpanish ? 'Pago' : 'Payment',
            value: payments,
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
          if (service.lastVerifiedDate != null) ...[
            const SizedBox(height: BcSpace.s1),
            Text(
              isSpanish
                  ? 'Verificada el ${formatDate(service.lastVerifiedDate!)}'
                  : 'Verified on ${formatDate(service.lastVerifiedDate!)}',
              style: BcText.caption(),
            ),
          ],
          const SizedBox(height: BcSpace.s4),
          BcButton(
            label: isSpanish ? 'Preparar solicitud' : 'Prepare request',
            icon: Icons.chevron_right_rounded,
            onPressed: onPrepare,
          ),
        ],
      ),
    );
  }
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
