import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/transfer_service.dart';
import '../../domain/transfer_request.dart';
import '../widgets/transfer_widgets.dart';

/// Código para el conductor (HU-18, pantalla 3).
///
/// El QR abre WhatsApp en el teléfono del conductor con el viaje ya escrito,
/// dirigido al número de la empresa. Se genera en el teléfono, funciona sin
/// conexión y no se guarda en ningún servidor.
class TransferCodeScreen extends ConsumerWidget {
  const TransferCodeScreen({super.key, required this.request});

  /// null si la pantalla se abrió sin solicitud (por ejemplo, al restaurar
  /// la app): se ofrece volver a armarla.
  final TransferRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final request = this.request;

    if (request == null) {
      return Scaffold(
        backgroundColor: BcColors.fog,
        body: SafeArea(
          child: BcMessage(
            icon: Icons.qr_code_2_rounded,
            text: isSpanish
                ? 'Este código ya no está disponible. Vuelve a preparar tu traslado.'
                : 'This code is no longer available. Set up your ride again.',
            actionLabel: isSpanish ? 'Ver transfers' : 'See transfers',
            onAction: () => context.go(transfersRoute),
          ),
        ),
      );
    }

    final service = request.service;
    final uri = request.whatsappUri();
    final stand = service.standLocation(isSpanish);

    return Scaffold(
      backgroundColor: BcColors.fog,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BcSpace.gutter,
            BcSpace.gutter,
            BcSpace.gutter,
            32,
          ),
          children: [
            Row(
              children: [
                BcCornerButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: isSpanish
                      ? 'Volver a tu traslado'
                      : 'Back to your ride',
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                BcTag(
                  isSpanish ? 'funciona igual' : 'still works',
                  lead: isSpanish ? 'Sin conexión' : 'Offline',
                  style: BcTagStyle.ink,
                ),
              ],
            ),
            const SizedBox(height: BcSpace.gutter),
            Text(
              isSpanish
                  ? 'MUESTRA ESTE CÓDIGO AL CONDUCTOR'
                  : 'SHOW THIS CODE TO THE DRIVER',
              style: BcText.label(color: BcColors.muted),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(request.code, style: BcText.display(64)),
            ),
            const SizedBox(height: BcSpace.gutter),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BcColors.surface,
                borderRadius: BorderRadius.circular(BcRadius.card),
              ),
              child: Column(
                children: [
                  if (uri != null) ...[
                    QrImageView(
                      data: uri.toString(),
                      size: 262,
                      backgroundColor: BcColors.surface,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: BcColors.ink,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: BcColors.ink,
                      ),
                      semanticsLabel: isSpanish
                          ? 'Código QR del traslado ${request.code}'
                          : 'QR code for ride ${request.code}',
                    ),
                    const SizedBox(height: BcSpace.s3),
                    Text(
                      isSpanish
                          ? 'Conductor: escanea para registrar el viaje en WhatsApp'
                          : 'Driver: scan to log the ride in WhatsApp',
                      textAlign: TextAlign.center,
                      style: BcText.title(),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.info_rounded,
                      color: BcColors.glacierDeep,
                    ),
                    const SizedBox(height: BcSpace.s2),
                    Text(
                      isSpanish
                          ? 'Esta empresa aún no recibe viajes por código. Muéstrale estos datos al conductor.'
                          : 'This company does not take rides by code yet. Show these details to the driver.',
                      textAlign: TextAlign.center,
                      style: BcText.body(color: BcColors.ink),
                    ),
                  ],
                  const SizedBox(height: BcSpace.s2),
                  Text(
                    [service.name, ?stand].join(' · '),
                    textAlign: TextAlign.center,
                    style: BcText.caption(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BcSpace.s3),
            TransferNotConfirmedNote(isSpanish: isSpanish),
            const SizedBox(height: BcSpace.gutter),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BcSpace.s4,
                vertical: BcSpace.s1,
              ),
              decoration: BoxDecoration(
                color: BcColors.surface,
                borderRadius: BorderRadius.circular(BcRadius.tile),
              ),
              child: Column(
                children: [
                  TransferInfoRow(
                    label: isSpanish ? 'Destino' : 'Destination',
                    value: request.destination(isSpanish),
                    divider: false,
                  ),
                  TransferInfoRow(
                    label: isSpanish ? 'Pasajeros' : 'Passengers',
                    value: '${request.passengers}',
                  ),
                  TransferInfoRow(
                    label: isSpanish ? 'Equipaje grande' : 'Large luggage',
                    value: request.bigLuggage
                        ? (isSpanish ? 'Sí' : 'Yes')
                        : 'No',
                  ),
                  TransferInfoRow(
                    label: isSpanish ? 'Pago' : 'Payment',
                    value: request.paymentLabel(isSpanish),
                  ),
                  TransferInfoRow(
                    label: isSpanish ? 'Tarifa referencial' : 'Reference fare',
                    value: request.fareLabel(isSpanish),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BcSpace.gutter),
            Text(
              isSpanish
                  ? 'Creado en tu teléfono el ${formatDate(request.createdAt)} a las ${formatTime(request.createdAt)}. No contiene tu nombre ni tus datos y no se guarda en ningún servidor.'
                  : 'Created on your phone on ${formatDate(request.createdAt)} at ${formatTime(request.createdAt)}. It has no name or personal details and is not stored on any server.',
              style: BcText.caption(),
            ),
            const SizedBox(height: BcSpace.gutter),
            Row(
              children: [
                Expanded(
                  child: BcButton(
                    label: isSpanish ? 'Editar datos' : 'Edit details',
                    style: BcButtonStyle.surface,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: BcSpace.s2),
                Expanded(
                  child: BcButton(
                    label: isSpanish ? 'Listo' : 'Done',
                    onPressed: () {
                      // Vuelve a la lista de transfers: cierra el código y
                      // el formulario.
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      if (navigator.canPop()) navigator.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
