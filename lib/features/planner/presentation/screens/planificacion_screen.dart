import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';

class PlanificacionScreen extends ConsumerStatefulWidget {
  const PlanificacionScreen({super.key});

  @override
  ConsumerState<PlanificacionScreen> createState() => _PlanificacionScreenState();
}

class _PlanificacionScreenState extends ConsumerState<PlanificacionScreen> {
  int _step = 1;
  String _selectedDestination = 'Cerro Castillo';
  String _date = '12/01/2027';
  int _people = 2;

  final List<String> _destinations = [
    'Cerro Castillo',
    'Reserva Nacional Coyhaique',
    'Lago General Carrera',
    'Puerto Chacabuco',
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(isSpanish),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isSpanish) {
    switch (_step) {
      case 1:
        return Column(
          key: const ValueKey(1),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.directions_bus, size: 64, color: AppTheme.primaryDark),
            const SizedBox(height: 24),
            Text(
              isSpanish ? '¿Ya sabes\ndónde ir?' : 'Do you know\nwhere to go?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isSpanish
                  ? 'Planifica tu viaje en pocos pasos. Selecciona el destino, tipo de transporte, fecha y cantidad de personas.'
                  : 'Plan your trip in a few steps. Select destination, transport type, date and number of people.',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => setState(() => _step = 2),
                child: Text(
                  isSpanish ? 'Comenzar planificación' : 'Start planning',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );

      case 2:
        return SingleChildScrollView(
          key: const ValueKey(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpanish ? 'Configura tu viaje' : 'Configure your trip',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSpanish ? 'Selecciona tu destino' : 'Select your destination',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDestination,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _destinations
                    .map((dest) => DropdownMenuItem(value: dest, child: Text(dest)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDestination = val);
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                isSpanish ? 'Fecha del viaje' : 'Travel date',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: _date,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _date = '${picked.day}/${picked.month}/${picked.year}';
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                isSpanish ? 'Número de personas' : 'Number of people',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _people > 1 ? () => setState(() => _people--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 16),
                  Text('$_people', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: _people < 20 ? () => setState(() => _people++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => setState(() => _step = 3),
                  child: Text(
                    isSpanish ? 'Buscar disponibilidad' : 'Search availability',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );

      case 3:
        return Column(
          key: const ValueKey(3),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _step = 2),
            ),
            Text(
              isSpanish ? 'Disponibilidad' : 'Availability',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Destino: $_selectedDestination'),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildRouteOptionCard('Ruta Directa Expresa', '09:00 AM - 11:30 AM', '\$15.000'),
                  const SizedBox(height: 12),
                  _buildRouteOptionCard('Ruta Panorámica Reserva', '11:00 AM - 02:00 PM', '\$18.000'),
                ],
              ),
            ),
          ],
        );

      case 4:
      default:
        return Column(
          key: const ValueKey(4),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              isSpanish ? '¡Reserva Confirmada!' : 'Booking Confirmed!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Destino: $_selectedDestination'),
            Text('Fecha: $_date | Personas: $_people'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Column(
                children: [
                  Icon(Icons.qr_code_2, size: 140),
                  SizedBox(height: 8),
                  Text(
                    'Presenta este código al subir al transporte',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => setState(() => _step = 1),
                child: Text(
                  isSpanish ? 'Finalizar' : 'Finish',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildRouteOptionCard(String name, String time, String price) {
    return InkWell(
      onTap: () => setState(() => _step = 4),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(
          children: [
            const Icon(Icons.airport_shuttle, size: 36, color: AppTheme.primaryDark),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
          ],
        ),
      ),
    );
  }
}
