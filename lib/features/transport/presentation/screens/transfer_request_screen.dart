import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  /// null hasta que el pasajero elige: no se preselecciona ninguna recogida.
  TransferPickupKind? _kind;
  PlaceDto? _lodging;

  /// Whether el pasajero eligió «Otro alojamiento» (o no hay catálogo) y
  /// escribe la dirección.
  bool _lodgingOther = false;
  final TextEditingController _lodgingText = TextEditingController();
  final TextEditingController _otherPickupText = TextEditingController();
  final TextEditingController _flightText = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _passengers = 1;
  bool _bigLuggage = false;
  TransferPayment? _payment;

  @override
  void dispose() {
    _lodgingText.dispose();
    _otherPickupText.dispose();
    _flightText.dispose();
    super.dispose();
  }

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

  /// Fecha y hora elegidas, o null si falta alguna.
  DateTime? get _pickupAt {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool get _whenComplete {
    final at = _pickupAt;
    return at != null && at.isAfter(DateTime.now());
  }

  bool get _requestComplete => _pickupComplete && _whenComplete;

  /// Lo primero que falta para poder preparar la solicitud, o null si está
  /// completa. Se muestra junto al botón.
  String? _missing(bool isSpanish) {
    if (_kind == null) {
      return isSpanish
          ? 'Falta elegir dónde te recogen'
          : 'Choose where you will be picked up';
    }
    if (!_pickupComplete) {
      return isSpanish
          ? 'Falta escribir la dirección de recogida'
          : 'Enter the pickup address';
    }
    if (_date == null) {
      return isSpanish ? 'Falta elegir la fecha' : 'Choose the date';
    }
    if (_time == null) {
      return isSpanish ? 'Falta elegir la hora' : 'Choose the time';
    }
    if (!_whenComplete) {
      return isSpanish
          ? 'La fecha y hora elegidas ya pasaron'
          : 'The chosen date and time have passed';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  bool get _pickupComplete => switch (_kind) {
        null => false,
        TransferPickupKind.lodging => _lodgingOther
            ? TransferPickupPoints.isTypedValid(_lodgingText.text)
            : _lodging != null,
        TransferPickupKind.other =>
          TransferPickupPoints.isTypedValid(_otherPickupText.text),
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
    final fare = service.referenceFareClp;

    final missing = _missing(isSpanish);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(
        BcSpace.gutter,
        BcSpace.gutter,
        BcSpace.gutter,
        BcSpace.gutter,
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
          service.name.toUpperCase(),
          style: BcText.label(color: BcColors.muted),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            isSpanish ? 'TU TRASLADO AL AEROPUERTO' : 'YOUR RIDE TO THE AIRPORT',
            style: BcText.displaySection,
          ),
        ),
        const SizedBox(height: BcSpace.section),

        // ¿Dónde te recogen?
        TransferSectionLabel(
          isSpanish ? '¿Dónde te recogen?' : 'Where will you be picked up?',
        ),
        const SizedBox(height: 10),
        TransferTwoColumns(
          children: [
            for (final kind in TransferPickupKind.values)
              TransferOption(
                label: _kindLabel(kind, isSpanish),
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
          ],
        ),
        const SizedBox(height: BcSpace.s3),
        _pickupDetail(isSpanish),
        const SizedBox(height: BcSpace.section),

        // Fecha y hora de recogida, y vuelo (opcional).
        TransferSectionLabel(
          isSpanish ? '¿Cuándo te recogen?' : 'When will you be picked up?',
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PickerField(
                icon: Icons.calendar_today_rounded,
                label: isSpanish ? 'Fecha' : 'Date',
                value: _date == null ? null : formatDate(_date!),
                placeholder: isSpanish ? 'Elegir fecha' : 'Choose date',
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: BcSpace.s3),
            Expanded(
              child: _PickerField(
                icon: Icons.schedule_rounded,
                label: isSpanish ? 'Hora' : 'Time',
                value: _time == null
                    ? null
                    : formatTime(
                        DateTime(2000, 1, 1, _time!.hour, _time!.minute),
                      ),
                placeholder: isSpanish ? 'Elegir hora' : 'Choose time',
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: BcSpace.s3),
        _FlightField(
          controller: _flightText,
          label: isSpanish ? 'Número de vuelo (opcional)' : 'Flight number (optional)',
          hint: isSpanish ? 'Aerolínea y número' : 'Airline and number',
          helper: isSpanish
              ? 'La empresa confirma la disponibilidad y la hora. Reserva con anticipación.'
              : 'The company confirms availability and time. Book ahead.',
        ),
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
              ? 'El pago se acuerda con la empresa. La app no cobra.'
              : 'Payment is arranged with the company. The app does not charge you.',
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
              ? 'Preparar la solicitud no reserva ni confirma el viaje: la empresa debe aceptarla. Contrata solo servicios autorizados.'
              : 'Preparing the request does not book or confirm the ride: the company must accept it. Book only authorized services.',
          style: BcText.caption(),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(child: list),
        if (!keyboardOpen)
          Container(
            padding: const EdgeInsets.fromLTRB(
              BcSpace.gutter,
              BcSpace.s3,
              BcSpace.gutter,
              BcSpace.s3,
            ),
            decoration: const BoxDecoration(
              color: BcColors.fog,
              border: Border(top: BorderSide(color: BcColors.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      missing,
                      textAlign: TextAlign.center,
                      style: BcText.caption(),
                    ),
                  ),
                  const SizedBox(height: BcSpace.s2),
                ],
                BcButton(
                  label: isSpanish ? 'Preparar solicitud' : 'Prepare request',
                  icon: Icons.send_rounded,
                  onPressed: _requestComplete
                      ? () => _createRequest(context, service, payment)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _kindLabel(TransferPickupKind kind, bool isSpanish) =>
      switch (kind) {
        TransferPickupKind.lodging =>
          isSpanish ? 'Mi alojamiento' : 'My lodging',
        TransferPickupKind.center =>
          isSpanish ? 'Centro de Coyhaique' : 'Coyhaique centre',
        TransferPickupKind.terminal =>
          isSpanish ? 'Terminal de buses' : 'Bus terminal',
        TransferPickupKind.other =>
          isSpanish ? 'Otro lugar' : 'Another place',
      };

  Widget _pickupDetail(bool isSpanish) {
    switch (_kind) {
      case null:
        return const SizedBox.shrink();
      case TransferPickupKind.center:
        return _FixedPoint(
          label: isSpanish ? 'Punto de referencia' : 'Reference point',
          value: isSpanish
              ? TransferPickupPoints.centerEs
              : TransferPickupPoints.centerEn,
        );
      case TransferPickupKind.terminal:
        return _FixedPoint(
          label: isSpanish ? 'Terminal' : 'Terminal',
          value: isSpanish
              ? TransferPickupPoints.terminalEs
              : TransferPickupPoints.terminalEn,
        );
      case TransferPickupKind.other:
        return _TypedTextField(
          controller: _otherPickupText,
          label: isSpanish ? 'Dirección de recogida' : 'Pickup address',
          hint: isSpanish
              ? 'Dirección o lugar donde te recogen'
              : 'Address or place where you are picked up',
          helper: isSpanish
              ? 'Escribe la dirección o el lugar de recogida y confírmalo con la empresa. No escribas tu nombre ni tu teléfono.'
              : 'Write the pickup address or place and confirm it with the company. Do not write your name or phone number.',
          onChanged: (_) => setState(() {}),
        );
      case TransferPickupKind.lodging:
        // Solo los alojamientos registrados en el catálogo, y la opción de
        // escribir otro. Si el catálogo no carga o está vacío, queda solo el
        // campo para escribir la dirección.
        final lodgingsAsync = ref.watch(
          placesByCategoryProvider('alojamiento'),
        );
        final typedField = _TypedTextField(
          controller: _lodgingText,
          label: isSpanish
              ? 'Dirección de tu alojamiento'
              : 'Your lodging address',
          hint: isSpanish ? 'Calle y número, o nombre' : 'Street and number, or name',
          helper: isSpanish
              ? '¿Tienes reserva en tu alojamiento? Ingresa su dirección y verifica con el conductor. No escribas tu nombre ni tu teléfono.'
              : 'Do you have a booking at your lodging? Enter its address and confirm it with the driver. Do not write your name or phone number.',
          onChanged: (_) => setState(() {
            _lodgingOther = true;
            _lodging = null;
          }),
        );
        return lodgingsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(BcSpace.s4),
            child: Center(
              child: CircularProgressIndicator(color: BcColors.ink),
            ),
          ),
          error: (_, _) => typedField,
          data: (lodgings) {
            if (lodgings.isEmpty) return typedField;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final place in lodgings) ...[
                  TransferOption(
                    label: place.getTitle(isSpanish),
                    selected: !_lodgingOther && _lodging?.id == place.id,
                    inkSelected: true,
                    onTap: () => setState(() {
                      _lodging = place;
                      _lodgingOther = false;
                    }),
                  ),
                  const SizedBox(height: BcSpace.s2),
                ],
                TransferOption(
                  label: isSpanish ? 'Otro alojamiento' : 'Another lodging',
                  selected: _lodgingOther,
                  inkSelected: true,
                  onTap: () => setState(() {
                    _lodgingOther = true;
                    _lodging = null;
                  }),
                ),
                if (_lodgingOther) ...[
                  const SizedBox(height: BcSpace.s3),
                  typedField,
                ],
              ],
            );
          },
        );
    }
  }

  void _createRequest(
    BuildContext context,
    TransferService service,
    TransferPayment payment,
  ) {
    final kind = _kind;
    final pickupAt = _pickupAt;
    if (kind == null || pickupAt == null) return;
    final lodgingTyped = kind == TransferPickupKind.lodging && _lodgingOther;
    final typed = lodgingTyped || kind == TransferPickupKind.other;
    final (pickupEs, pickupEn) = switch (kind) {
      TransferPickupKind.lodging when lodgingTyped => (
          TransferPickupPoints.cleanTyped(_lodgingText.text),
          TransferPickupPoints.cleanTyped(_lodgingText.text),
        ),
      TransferPickupKind.lodging => (
          '${_lodging!.getTitle(true)}, Coyhaique',
          '${_lodging!.getTitle(false)}, Coyhaique',
        ),
      TransferPickupKind.center => (
          TransferPickupPoints.centerEs,
          TransferPickupPoints.centerEn,
        ),
      TransferPickupKind.terminal => (
          TransferPickupPoints.terminalEs,
          TransferPickupPoints.terminalEn,
        ),
      TransferPickupKind.other => (
          TransferPickupPoints.cleanTyped(_otherPickupText.text),
          TransferPickupPoints.cleanTyped(_otherPickupText.text),
        ),
    };

    final request = TransferRequest(
      service: service,
      code: TransferRequest.newCode(),
      pickupKind: kind,
      pickupEs: pickupEs,
      pickupEn: pickupEn,
      pickupAt: pickupAt,
      flight: TransferPickupPoints.cleanFlight(_flightText.text),
      passengers: _passengers,
      bigLuggage: _bigLuggage,
      payment: payment,
      createdAt: DateTime.now(),
      pickupIsTyped: typed,
    );

    context.push(transferCodeRoute, extra: request);
  }
}

/// Campo para que el pasajero escriba un texto (dirección de recogida, fecha
/// y vuelo). Una sola línea, sin caracteres de formato de
/// WhatsApp, con el largo máximo de [TransferPickupPoints.maxTypedLength].
class _TypedTextField extends StatelessWidget {
  const _TypedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(BcRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: TransferPickupPoints.maxTypedLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.streetAddress,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'[\n\r*_~`]')),
      ],
      style: BcText.title(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 4,
        helperStyle: BcText.caption(),
        counterText: '',
        filled: true,
        fillColor: BcColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(BcColors.line),
        enabledBorder: border(BcColors.line),
        focusedBorder: border(BcColors.glacierDeep, 2),
      ),
    );
  }
}

/// Botón con forma de campo que abre un selector (fecha u hora). Muestra el
/// valor elegido o, mientras no hay, un texto que invita a elegir.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = value != null;
    return BcPressable(
      onTap: onTap,
      semanticLabel: '$label: ${value ?? placeholder}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.field),
          border: Border.all(
            color: chosen ? BcColors.glacierDeep : BcColors.line,
            width: chosen ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: BcColors.glacierDeep),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: BcText.caption()),
                  Text(
                    value ?? placeholder,
                    style: chosen
                        ? BcText.title()
                        : BcText.title(color: BcColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo del número de vuelo: opcional, en mayúsculas, solo letras, números,
/// espacio y guion.
class _FlightField extends StatelessWidget {
  const _FlightField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(BcRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      maxLength: TransferPickupPoints.maxFlightLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
      ],
      style: BcText.title(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        helperStyle: BcText.caption(),
        counterText: '',
        filled: true,
        fillColor: BcColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(BcColors.line),
        enabledBorder: border(BcColors.line),
        focusedBorder: border(BcColors.glacierDeep, 2),
      ),
    );
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
