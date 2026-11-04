import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../categories/data/models/place_dto.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../data/models/transfer_service.dart';
import '../../data/providers/transfer_providers.dart';
import '../../domain/transfer_request.dart';
import '../widgets/transfer_widgets.dart';


class TransferRequestScreen extends ConsumerStatefulWidget {
  const TransferRequestScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<TransferRequestScreen> createState() =>
      _TransferRequestScreenState();
}

class _TransferRequestScreenState
    extends ConsumerState<TransferRequestScreen> {
  TransferDestinationKind _kind = TransferDestinationKind.center;
  PlaceDto? _lodging;
  String? _locality;
  int _passengers = 1;
  bool _bigLuggage = false;
  TransferPayment? _payment;

  @override
  Widget build(BuildContext context) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final serviceAsync = ref.watch(
      airportTransferByIdProvider(widget.serviceId),
    );

    return Scaffold(
      backgroundColor: BcColors.fog,
      body: SafeArea(
        child: serviceAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: BcColors.ink),
          ),
          error: (_, _) => BcMessage(
            icon: Icons.wifi_off_rounded,
            text: isSpanish
                ? 'No pudimos cargar esta empresa. Revisa tu conexión.'
                : 'We could not load this company. Check your connection.',
            actionLabel: isSpanish ? 'Volver' : 'Back',
            onAction: () => context.pop(),
          ),
          data: (service) {
            if (service == null) {
              return BcMessage(
                icon: Icons.search_off_rounded,
                text: isSpanish
                    ? 'Esta empresa ya no está disponible.'
                    : 'This company is no longer available.',
                actionLabel: isSpanish ? 'Volver' : 'Back',
                onAction: () => context.pop(),
              );
            }
            return _buildForm(context, service, isSpanish);
          },
        ),
      ),
    );
  }

  TransferPayment _effectivePayment(TransferService service) {
    final chosen = _payment;
    if (chosen == TransferPayment.card && service.acceptsCard) return chosen!;
    if (chosen == TransferPayment.cash && service.acceptsCash) return chosen!;
    return service.acceptsCard ? TransferPayment.card : TransferPayment.cash;
  }

  bool get _destinationComplete => switch (_kind) {
        TransferDestinationKind.lodging => _lodging != null,
        TransferDestinationKind.locality => _locality != null,
        _ => true,
      };

  Widget _buildForm(
    BuildContext context,
    TransferService service,
    bool isSpanish,
  ) {
    final maxPassengers = service.maxPassengers;
    if (_passengers > maxPassengers) _passengers = maxPassengers;
    final payment = _effectivePayment(service);
    final stand = service.standLocation(isSpanish);
    final fare = service.referenceFareClp;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BcSpace.gutter,
        BcSpace.gutter,
        BcSpace.gutter,
        32,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: BcCornerButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: isSpanish ? 'Volver' : 'Back',
            onTap: () => context.pop(),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          [service.name, ?stand].join(' · ').toUpperCase(),
          style: BcText.label(color: BcColors.muted),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            isSpanish ? 'TU TRASLADO' : 'YOUR RIDE',
            style: BcText.displaySection,
          ),
        ),
        const SizedBox(height: BcSpace.section),

        // ¿A dónde vas?
        TransferSectionLabel(isSpanish ? '¿A dónde vas?' : 'Where to?'),
        const SizedBox(height: 10),
        TransferTwoColumns(
          children: [
            for (final kind in TransferDestinationKind.values)
              TransferOption(
                label: _kindLabel(kind, isSpanish),
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
          ],
        ),
        const SizedBox(height: BcSpace.s3),
        _destinationDetail(isSpanish),
        const SizedBox(height: BcSpace.section),

        // ¿Cuántos van?
        TransferSectionLabel(isSpanish ? '¿Cuántos van?' : 'How many?'),
        const SizedBox(height: 10),
        _PassengerStepper(
          value: _passengers,
          max: maxPassengers,
          isSpanish: isSpanish,
          onChanged: (value) => setState(() => _passengers = value),
        ),
        const SizedBox(height: 6),
        Text(
          service.capacity == null
              ? (isSpanish
                  ? 'Capacidad por confirmar con la empresa'
                  : 'Capacity to be confirmed with the company')
              : (isSpanish
                  ? 'Máximo $maxPassengers pasajeros por vehículo'
                  : 'Up to $maxPassengers passengers per vehicle'),
          style: BcText.caption(),
        ),
        const SizedBox(height: BcSpace.section),

        // Equipaje grande.
        TransferSectionLabel(
          isSpanish ? '¿Llevan equipaje grande?' : 'Large luggage?',
        ),
        const SizedBox(height: 10),
        TransferTwoColumns(
          children: [
            TransferOption(
              label: isSpanish ? 'Sí' : 'Yes',
              selected: _bigLuggage,
              inkSelected: true,
              onTap: () => setState(() => _bigLuggage = true),
            ),
            TransferOption(
              label: 'No',
              selected: !_bigLuggage,
              inkSelected: true,
              onTap: () => setState(() => _bigLuggage = false),
            ),
          ],
        ),
        const SizedBox(height: BcSpace.section),

        // ¿Cómo pagas?
        TransferSectionLabel(isSpanish ? '¿Cómo pagas?' : 'How will you pay?'),
        const SizedBox(height: 10),
        TransferTwoColumns(
          children: [
            if (service.acceptsCash)
              TransferOption(
                label: isSpanish ? 'Efectivo' : 'Cash',
                selected: payment == TransferPayment.cash,
                inkSelected: true,
                onTap: () =>
                    setState(() => _payment = TransferPayment.cash),
              ),
            if (service.acceptsCard)
              TransferOption(
                label: isSpanish ? 'Tarjeta' : 'Card',
                selected: payment == TransferPayment.card,
                inkSelected: true,
                onTap: () =>
                    setState(() => _payment = TransferPayment.card),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isSpanish
              ? 'El pago lo recibe el conductor. La app no cobra.'
              : 'You pay the driver. The app does not charge you.',
          style: BcText.caption(),
        ),
        const SizedBox(height: BcSpace.section),

        // Tarifa referencial.
        Container(
          padding: const EdgeInsets.all(BcSpace.s4),
          decoration: BoxDecoration(
            color: BcColors.ink,
            borderRadius: BorderRadius.circular(BcRadius.tile),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish ? 'TARIFA REFERENCIAL' : 'REFERENCE FARE',
                      style: BcText.label(color: BcColors.glacier),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.fareNotes(isSpanish) ??
                          (service.lastVerifiedDate == null
                              ? (isSpanish
                                  ? 'La confirma el conductor.'
                                  : 'The driver confirms it.')
                              : (isSpanish
                                  ? 'Verificada el ${formatDate(service.lastVerifiedDate!)}. La confirma el conductor.'
                                  : 'Verified on ${formatDate(service.lastVerifiedDate!)}. The driver confirms it.')),
                      style: BcText.caption(color: BcColors.line),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BcSpace.s3),
              Text(
                fare == null
                    ? (isSpanish ? 'Por confirmar' : 'TBC')
                    : formatClp(fare),
                style: BcText.display(22, color: BcColors.onPhoto),
              ),
            ],
          ),
        ),
        const SizedBox(height: BcSpace.s3),
        TransferPrivacyNote(isSpanish: isSpanish),
        const SizedBox(height: BcSpace.s3),
        Text(
          isSpanish
              ? 'Generar el código no reserva ni confirma el viaje: el conductor debe leerlo y aceptarlo.'
              : 'Creating the code does not book or confirm the ride: the driver must read and accept it.',
          style: BcText.caption(),
        ),
        const SizedBox(height: BcSpace.gutter),
        BcButton(
          label: isSpanish ? 'Generar código' : 'Create code',
          icon: Icons.qr_code_2_rounded,
          onPressed: _destinationComplete
              ? () => _createCode(context, service, payment)
              : null,
        ),
        if (!_destinationComplete) ...[
          const SizedBox(height: BcSpace.s2),
          Text(
            isSpanish
                ? 'Elige tu destino para continuar.'
                : 'Choose your destination to continue.',
            style: BcText.caption(),
          ),
        ],
      ],
    );
  }

  String _kindLabel(TransferDestinationKind kind, bool isSpanish) =>
      switch (kind) {
        TransferDestinationKind.lodging =>
          isSpanish ? 'Mi alojamiento' : 'My lodging',
        TransferDestinationKind.center =>
          isSpanish ? 'Centro de Coyhaique' : 'Coyhaique centre',
        TransferDestinationKind.terminal =>
          isSpanish ? 'Terminal de buses' : 'Bus terminal',
        TransferDestinationKind.locality =>
          isSpanish ? 'Otra localidad' : 'Another town',
      };

  Widget _destinationDetail(bool isSpanish) {
    switch (_kind) {
      case TransferDestinationKind.center:
        return _FixedPoint(
          label: isSpanish ? 'Punto de referencia' : 'Reference point',
          value: isSpanish
              ? TransferDestinations.centerEs
              : TransferDestinations.centerEn,
        );
      case TransferDestinationKind.terminal:
        return _FixedPoint(
          label: isSpanish ? 'Terminal' : 'Terminal',
          value: isSpanish
              ? TransferDestinations.terminalEs
              : TransferDestinations.terminalEn,
        );
      case TransferDestinationKind.locality:
        return Wrap(
          spacing: BcSpace.s2,
          runSpacing: BcSpace.s2,
          children: [
            for (final locality in TransferDestinations.localities)
              IntrinsicWidth(
                child: TransferOption(
                  label: locality,
                  selected: _locality == locality,
                  inkSelected: true,
                  onTap: () => setState(() => _locality = locality),
                ),
              ),
          ],
        );
      case TransferDestinationKind.lodging:
        final lodgingsAsync = ref.watch(
          placesByCategoryProvider('alojamiento'),
        );
        return lodgingsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(BcSpace.s4),
            child: Center(
              child: CircularProgressIndicator(color: BcColors.ink),
            ),
          ),
          error: (_, _) => _hint(
            isSpanish
                ? 'No pudimos cargar los alojamientos. Elige el centro de Coyhaique y dile tu alojamiento al conductor.'
                : 'We could not load lodgings. Choose Coyhaique centre and tell the driver where you are staying.',
          ),
          data: (lodgings) {
            if (lodgings.isEmpty) {
              return _hint(
                isSpanish
                    ? 'Aún no hay alojamientos en el catálogo. Elige el centro de Coyhaique y dile tu alojamiento al conductor.'
                    : 'There are no lodgings in the catalogue yet. Choose Coyhaique centre and tell the driver where you are staying.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final place in lodgings) ...[
                  TransferOption(
                    label: place.getTitle(isSpanish),
                    selected: _lodging?.id == place.id,
                    inkSelected: true,
                    onTap: () => setState(() => _lodging = place),
                  ),
                  const SizedBox(height: BcSpace.s2),
                ],
              ],
            );
          },
        );
    }
  }

  Widget _hint(String text) => Text(text, style: BcText.caption());

  void _createCode(
    BuildContext context,
    TransferService service,
    TransferPayment payment,
  ) {
    final (destinationEs, destinationEn) = switch (_kind) {
      TransferDestinationKind.lodging => (
          '${_lodging!.getTitle(true)}, Coyhaique',
          '${_lodging!.getTitle(false)}, Coyhaique',
        ),
      TransferDestinationKind.center => (
          TransferDestinations.centerEs,
          TransferDestinations.centerEn,
        ),
      TransferDestinationKind.terminal => (
          TransferDestinations.terminalEs,
          TransferDestinations.terminalEn,
        ),
      TransferDestinationKind.locality => (_locality!, _locality!),
    };

    final request = TransferRequest(
      service: service,
      code: TransferRequest.newCode(),
      destinationKind: _kind,
      destinationEs: destinationEs,
      destinationEn: destinationEn,
      passengers: _passengers,
      bigLuggage: _bigLuggage,
      payment: payment,
      createdAt: DateTime.now(),
    );

    context.push(transferCodeRoute, extra: request);
  }
}

class _FixedPoint extends StatelessWidget {
  const _FixedPoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BcText.caption()),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: BcColors.surface,
            borderRadius: BorderRadius.circular(BcRadius.field),
            border: Border.all(color: BcColors.line),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_rounded,
                size: 20,
                color: BcColors.glacierDeep,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(value, style: BcText.title())),
            ],
          ),
        ),
      ],
    );
  }
}

class _PassengerStepper extends StatelessWidget {
  const _PassengerStepper({
    required this.value,
    required this.max,
    required this.isSpanish,
    required this.onChanged,
  });

  final int value;
  final int max;
  final bool isSpanish;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final unit = isSpanish
        ? (value == 1 ? 'pasajero' : 'pasajeros')
        : (value == 1 ? 'passenger' : 'passengers');

    return Container(
      padding: const EdgeInsets.all(BcSpace.s2),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.field),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            semanticLabel:
                isSpanish ? 'Quitar un pasajero' : 'Remove a passenger',
            dark: false,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$value ', style: BcText.display(32)),
                    TextSpan(text: unit, style: BcText.body()),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            semanticLabel:
                isSpanish ? 'Agregar un pasajero' : 'Add a passenger',
            dark: true,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: BcPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: dark ? BcColors.ink : BcColors.fog,
            borderRadius: BorderRadius.circular(BcRadius.control),
          ),
          child: Icon(
            icon,
            color: dark ? BcColors.onPhoto : BcColors.ink,
          ),
        ),
      ),
    );
  }
}
