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

/// Transfers desde el aeropuerto de Balmaceda (HU-18, pantalla 1).
///
/// Lista las empresas con ficha activa. La información es referencial y se
/// confirma con el conductor.
class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  static const String _heroPhoto = 'assets/images/miradores_coyhaique.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                                    ? 'DEL AEROPUERTO AL CENTRO DE COYHAIQUE'
                                    : 'FROM THE AIRPORT TO COYHAIQUE',
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
                                isSpanish
                                    ? 'Eliges destino, pasajeros y pago. Le muestras el código al conductor.'
                                    : 'Choose destination, passengers and payment. Show the code to the driver.',
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
                            ? 'Puestos en el hall de llegada'
                            : 'Stands in the arrivals hall',
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
                            onPrepare: () => context.push(
                              transferRequestRoute(service.id),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    BcSpace.s4,
                    BcSpace.gutter,
                    40,
                  ),
                  child: Text(
                    isSpanish
                        ? 'Información referencial. Confirma la tarifa con el conductor antes de subir.'
                        : 'Reference information. Confirm the fare with the driver before getting in.',
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
    final stand = service.standLocation(isSpanish);
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
          if (stand != null) ...[
            const SizedBox(height: BcSpace.s2),
            Text(stand, style: BcText.caption()),
          ],
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
            label: isSpanish ? 'Preparar mi traslado' : 'Set up my ride',
            icon: Icons.chevron_right_rounded,
            onPressed: onPrepare,
          ),
        ],
      ),
    );
  }
}
