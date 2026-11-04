import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';

/// Rutas del flujo de transfer (HU-18).
const String transfersRoute = '/transport/transfers';
const String transferCodeRoute = '/transport/transfer-code';
String transferRequestRoute(String serviceId) =>
    '$transfersRoute/$serviceId';

/// Acceso al flujo desde la categoría Transporte.
class TransferEntryCard extends StatelessWidget {
  const TransferEntryCard({
    super.key,
    required this.isSpanish,
    required this.onTap,
  });

  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BcInfoTile(
      icon: Icons.airport_shuttle_rounded,
      dark: true,
      title: isSpanish
          ? 'Transfer desde el aeropuerto'
          : 'Airport transfer',
      subtitle: isSpanish
          ? 'Prepara tu traslado y muéstrale un código al conductor'
          : 'Set up your ride and show the driver a code',
      onTap: onTap,
    );
  }
}

/// Etiqueta de sección en mayúsculas (¿A DÓNDE VAS?).
class TransferSectionLabel extends StatelessWidget {
  const TransferSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text.toUpperCase(), style: BcText.label()),
    );
  }
}

/// Opción seleccionable. [inkSelected] usa tinta en vez de glaciar para
/// grupos secundarios (equipaje, pago), como en el mockup.
class TransferOption extends StatelessWidget {
  const TransferOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.inkSelected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool inkSelected;

  @override
  Widget build(BuildContext context) {
    final bg = !selected
        ? BcColors.surface
        : (inkSelected ? BcColors.ink : BcColors.glacier);
    final fg = selected && inkSelected ? BcColors.onPhoto : BcColors.ink;

    return Semantics(
      button: true,
      selected: selected,
      child: BcPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(BcRadius.control),
          ),
          child: Text(label, style: BcText.title(color: fg)),
        ),
      ),
    );
  }
}

/// Dos columnas que se ajustan al ancho y al tamaño de texto del sistema.
class TransferTwoColumns extends StatelessWidget {
  const TransferTwoColumns({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - BcSpace.s2) / 2;
        return Wrap(
          spacing: BcSpace.s2,
          runSpacing: BcSpace.s2,
          children: [
            for (final child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Fila «etiqueta · valor» dentro de una tarjeta clara.
class TransferInfoRow extends StatelessWidget {
  const TransferInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.divider = true,
  });

  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: BcColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: BcText.body()),
          ),
          const SizedBox(width: BcSpace.s3),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: BcText.title(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de privacidad del flujo: no se piden datos personales.
class TransferPrivacyNote extends StatelessWidget {
  const TransferPrivacyNote({super.key, required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 20,
            color: BcColors.glacierDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSpanish
                  ? 'No te pedimos nombre ni datos de contacto. El código se crea en tu teléfono y no se guarda en ningún servidor.'
                  : 'We do not ask for your name or contact details. The code is created on your phone and is not stored on any server.',
              style: BcText.body(color: BcColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso: generar el código no reserva ni confirma el viaje.
class TransferNotConfirmedNote extends StatelessWidget {
  const TransferNotConfirmedNote({super.key, required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: BcColors.ink,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_rounded,
            size: 20,
            color: BcColors.glacier,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: isSpanish
                        ? 'El código no confirma el viaje. '
                        : 'The code does not confirm the ride. ',
                    style: BcText.title(color: BcColors.onPhoto),
                  ),
                  TextSpan(
                    text: isSpanish
                        ? 'El conductor debe leerlo y aceptarlo. Si no puede llevarte, pregunta en otro puesto.'
                        : 'The driver must read and accept it. If they cannot take you, ask at another stand.',
                    style: BcText.body(color: BcColors.line),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
