import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/transfer_service.dart';
import '../../domain/transfer_request.dart';
import '../widgets/transfer_widgets.dart';

/// Solicitud de traslado al aeropuerto lista para enviar (HU-18, pantalla 3).
///
/// El botón y el QR abren WhatsApp con la solicitud ya escrita, dirigida al
/// número de la empresa. Se arma en el teléfono y no se guarda en ningún
/// servidor. Una empresa pendiente de validación no recibe solicitudes.
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
                  ? 'ENVÍA ESTA SOLICITUD A LA EMPRESA'
                  : 'SEND THIS REQUEST TO THE COMPANY',
              style: BcText.label(color: BcColors.muted),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(request.code, style: BcText.display(64)),
            ),
            const SizedBox(height: BcSpace.gutter),
            if (uri != null) ...[
              BcButton(
                label: isSpanish ? 'Enviar por WhatsApp' : 'Send by WhatsApp',
                icon: Icons.send_rounded,
                onPressed: () => _sendByWhatsApp(context, uri, isSpanish),
              ),
              const SizedBox(height: BcSpace.gutter),
            ],

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
                          ? 'La empresa puede escanearlo para abrir la solicitud en WhatsApp'
                          : 'The company can scan it to open the request in WhatsApp',
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
                          ? 'Esta empresa aún no recibe solicitudes desde la app. Contáctala directamente y entrégale estos datos.'
                          : 'This company does not receive requests from the app yet. Contact it directly and give it these details.',
                      textAlign: TextAlign.center,
                      style: BcText.body(color: BcColors.ink),
                    ),
                  ],
                  const SizedBox(height: BcSpace.s2),
                  Text(
                    service.name,
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
                    label: isSpanish ? 'Recogida' : 'Pickup',
                    value: request.pickup(isSpanish),
                    divider: false,
                  ),
                  TransferInfoRow(
                    label: isSpanish ? 'Destino' : 'Destination',
                    value: service.origin(isSpanish),
                  ),
                  TransferInfoRow(
                    label: isSpanish ? 'Fecha y hora' : 'Date and time',
                    value:
                        '${formatDate(request.pickupAt)} · ${formatTime(request.pickupAt)}',
                  ),
                  if (request.flight != null && request.flight!.isNotEmpty)
                    TransferInfoRow(
                      label: isSpanish ? 'Vuelo' : 'Flight',
                      value: request.flight!,
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
            if (request.pickupIsTyped) ...[
              Text(
                isSpanish
                    ? 'Escribiste esta recogida tú mismo: confírmala con la empresa.'
                    : 'You typed this pickup yourself: confirm it with the company.',
                style: BcText.caption(color: BcColors.glacierDeep),
              ),
              const SizedBox(height: BcSpace.s2),
            ],
            Text(
              isSpanish
                  ? 'Creado en tu teléfono el ${formatDate(request.createdAt)} a las ${formatTime(request.createdAt)}. No contiene tu nombre ni tus datos de contacto y la app no la guarda en ningún servidor. Si la envías por WhatsApp, la empresa verá tu número, como en cualquier chat.'
                  : 'Created on your phone on ${formatDate(request.createdAt)} at ${formatTime(request.createdAt)}. It has no name or contact details and the app does not store it on any server. If you send it by WhatsApp, the company will see your number, as in any chat.',
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

/// Abre WhatsApp con la solicitud ya escrita. Si no se puede abrir, avisa y
/// deja el QR y los datos en pantalla.
Future<void> _sendByWhatsApp(
  BuildContext context,
  Uri uri,
  bool isSpanish,
) async {
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
            ? 'No se pudo abrir WhatsApp. Escanea el QR o contacta a la empresa.'
            : 'Could not open WhatsApp. Scan the QR or contact the company.',
      ),
    ),
  );
}
