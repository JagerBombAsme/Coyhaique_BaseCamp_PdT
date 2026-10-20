import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/providers/planner_provider.dart';

class PlanificacionScreen extends ConsumerStatefulWidget {
  const PlanificacionScreen({super.key});

  @override
  ConsumerState<PlanificacionScreen> createState() =>
      _PlanificacionScreenState();
}

class _PlanificacionScreenState extends ConsumerState<PlanificacionScreen> {
  int _step = 1;
  String _selectedDestination = 'Cerro Castillo';
  DateTime? _selectedDate;
  int _people = 2;

  String get _formattedDate {
    final date = _selectedDate;

    if (date == null) {
      return '12/01/2027';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final destinationsAsync = ref.watch(plannerDestinationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(isSpanish, destinationsAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isSpanish, AsyncValue destinationsAsync) {
    switch (_step) {
      case 1:
        return _buildIntroStep(isSpanish);

      case 2:
        return _buildConfigurationStep(isSpanish, destinationsAsync);

      case 3:
        return _buildAvailabilityStep(isSpanish);

      case 4:
      default:
        return _buildConfirmationStep(isSpanish);
    }
  }

  Widget _buildIntroStep(bool isSpanish) {
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
              ? 'Planifica tu viaje en pocos pasos. Selecciona el destino, la fecha y la cantidad de personas.'
              : 'Plan your trip in a few steps. Select the destination, date and number of people.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              setState(() {
                _step = 2;
              });
            },
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
  }

  Widget _buildConfigurationStep(bool isSpanish, AsyncValue destinationsAsync) {
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
          destinationsAsync.when(
            data: (destinations) {
              final List<String> list = (destinations as Iterable)
                  .map<String>(
                    (destination) => destination.name.toString().trim(),
                  )
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList();

              if (list.isEmpty) {
                return _buildDestinationFallbackField(isSpanish);
              }

              final String effectiveDestination =
                  list.contains(_selectedDestination)
                  ? _selectedDestination
                  : list.first;

              return DropdownButtonFormField<String>(
                initialValue: effectiveDestination,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: list.map<DropdownMenuItem<String>>((String destination) {
                  return DropdownMenuItem<String>(
                    value: destination,
                    child: Text(destination),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedDestination = value;
                    });
                  }
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) =>
                _buildDestinationFallbackField(isSpanish),
          ),
          const SizedBox(height: 20),
          Text(
            isSpanish ? 'Fecha del viaje' : 'Travel date',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                _formattedDate,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
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
                onPressed: _people > 1
                    ? () {
                        setState(() {
                          _people--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Text(
                '$_people',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: _people < 20
                    ? () {
                        setState(() {
                          _people++;
                        });
                      }
                    : null,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                setState(() {
                  _step = 3;
                });
              },
              child: Text(
                isSpanish ? 'Buscar disponibilidad' : 'Search availability',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationFallbackField(bool isSpanish) {
    return TextFormField(
      initialValue: _selectedDestination,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: isSpanish ? 'Ingresa un destino' : 'Enter a destination',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        _selectedDestination = value;
      },
    );
  }

  Widget _buildAvailabilityStep(bool isSpanish) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _step = 2;
            });
          },
        ),
        Text(
          isSpanish ? 'Disponibilidad' : 'Availability',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isSpanish
              ? 'Destino: $_selectedDestination'
              : 'Destination: $_selectedDestination',
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              _buildRouteOptionCard(
                name: isSpanish
                    ? 'Ruta Directa Expresa'
                    : 'Direct Express Route',
                time: '09:00 AM - 11:30 AM',
                price: '\$15.000',
              ),
              const SizedBox(height: 12),
              _buildRouteOptionCard(
                name: isSpanish
                    ? 'Ruta Panorámica Reserva'
                    : 'Scenic Reserve Route',
                time: '11:00 AM - 02:00 PM',
                price: '\$18.000',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(bool isSpanish) {
    return SingleChildScrollView(
      key: const ValueKey(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            isSpanish ? '¡Reserva confirmada!' : 'Booking confirmed!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isSpanish
                ? 'Destino: $_selectedDestination'
                : 'Destination: $_selectedDestination',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Fecha: $_formattedDate | Personas: $_people'
                : 'Date: $_formattedDate | People: $_people',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 140),
                const SizedBox(height: 8),
                Text(
                  isSpanish
                      ? 'Presenta este código al subir al transporte'
                      : 'Show this code when boarding the transport',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                setState(() {
                  _step = 1;
                  _people = 2;
                  _selectedDate = null;
                });
              },
              child: Text(
                isSpanish ? 'Finalizar' : 'Finish',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  Widget _buildRouteOptionCard({
    required String name,
    required String time,
    required String price,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _step = 4;
        });
      },
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
            const Icon(
              Icons.airport_shuttle,
              size: 36,
              color: AppTheme.primaryDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
