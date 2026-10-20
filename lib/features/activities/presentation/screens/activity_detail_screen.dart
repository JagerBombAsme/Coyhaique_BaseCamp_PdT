import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../routes/data/models/activity_dto.dart';
import '../../../routes/data/providers/activity_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  static const Color _background = Color(0xFFF8FCFE);

  static const Color _surface = Color(0xFFFFFFFF);

  static const Color _iceBlue = Color(0xFFDFF4FF);

  static const Color _iceBlueMedium = Color(0xFFBFE8F8);

  static const Color _iceAccent = Color(0xFF5FA8C6);

  static const Color _iceDark = Color(0xFF2E5F73);

  static const Color _textPrimary = Color(0xFF244652);

  static const Color _textSecondary = Color(0xFF6F8792);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    final isSpanish = locale.languageCode == 'es';

    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, color: _iceDark),
        ),

        title: Text(
          isSpanish ? 'Actividades' : 'Activities',
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),

        centerTitle: true,
      ),

      body: activitiesAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return _buildEmptyState(isSpanish);
          }

          return RefreshIndicator(
            color: _iceDark,
            backgroundColor: Colors.white,

            onRefresh: () async {
              ref.invalidate(activitiesProvider);

              await ref.read(activitiesProvider.future);
            },

            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),

              itemCount: activities.length,

              separatorBuilder: (context, index) {
                return const SizedBox(height: 14);
              },

              itemBuilder: (context, index) {
                final activity = activities[index];

                return _ActivityCard(
                  activity: activity,
                  isSpanish: isSpanish,

                  onTap: () {
                    debugPrint('ACTIVIDAD: ${activity.id}');

                    context.push('/attractions/${activity.id}');
                  },
                );
              },
            ),
          );
        },

        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: _iceAccent),
          );
        },

        error: (error, stackTrace) {
          debugPrint('ERROR ACTIVITIES: $error');

          return _buildErrorState(ref, isSpanish);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isSpanish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _iceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: _iceDark,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isSpanish
                  ? 'No hay actividades disponibles'
                  : 'No activities available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSpanish
                  ? 'Actualmente no existen actividades turísticas activas para mostrar.'
                  : 'There are currently no active tourist activities to display.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, bool isSpanish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _iceBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: _iceDark,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isSpanish
                  ? 'No fue posible cargar las actividades'
                  : 'Unable to load activities',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSpanish
                  ? 'Comprueba tu conexión e inténtalo nuevamente.'
                  : 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 14),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                ref.invalidate(activitiesProvider);
              },

              style: FilledButton.styleFrom(
                backgroundColor: _iceDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
              ),

              icon: const Icon(Icons.refresh_rounded),

              label: Text(isSpanish ? 'Reintentar' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// TARJETA
// ===================================================================

class _ActivityCard extends StatelessWidget {
  final ActivityDto activity;
  final bool isSpanish;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.isSpanish,
    required this.onTap,
  });

  static const Color _surface = Color(0xFFFFFFFF);

  static const Color _iceBlue = Color(0xFFDFF4FF);

  static const Color _iceBlueMedium = Color(0xFFBFE8F8);

  static const Color _iceAccent = Color(0xFF5FA8C6);

  static const Color _iceDark = Color(0xFF2E5F73);

  static const Color _textPrimary = Color(0xFF244652);

  static const Color _textSecondary = Color(0xFF6F8792);

  @override
  Widget build(BuildContext context) {
    final name = activity.getName(isSpanish);

    final description = activity.getDescription(isSpanish);

    final price = _cleanText(activity.referencePrice);

    final schedule = _cleanText(activity.schedule);

    final meetingPoint = _cleanText(activity.meetingPoint);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(24),

        child: Ink(
          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(24),

            border: Border.all(color: _iceBlueMedium.withValues(alpha: 0.65)),

            boxShadow: [
              BoxShadow(
                color: _iceAccent.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =====================================================
                // ENCABEZADO
                // =====================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      width: 54,
                      height: 54,

                      decoration: BoxDecoration(
                        color: _iceBlue,

                        borderRadius: BorderRadius.circular(17),
                      ),

                      child: const Icon(
                        Icons.explore_rounded,
                        color: _iceDark,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: _iceBlue,

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              isSpanish ? 'Actividad' : 'Activity',

                              style: const TextStyle(
                                color: _iceDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Icon(Icons.chevron_right_rounded, color: _iceDark),
                  ],
                ),

                // =====================================================
                // DESCRIPCIÓN
                // =====================================================
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),

                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],

                // =====================================================
                // PRECIO
                // =====================================================
                if (price != null && !_isAvailabilityText(price)) ...[
                  const SizedBox(height: 16),

                  _InfoRow(icon: Icons.payments_outlined, value: price),
                ],

                // =====================================================
                // HORARIO
                // =====================================================
                if (schedule != null) ...[
                  const SizedBox(height: 10),

                  _InfoRow(icon: Icons.schedule_rounded, value: schedule),
                ],

                // =====================================================
                // PUNTO DE ENCUENTRO
                // =====================================================
                if (meetingPoint != null) ...[
                  const SizedBox(height: 10),

                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    value: meetingPoint,
                  ),
                ],

                const SizedBox(height: 18),

                // =====================================================
                // VER DETALLE
                // =====================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [
                    Text(
                      isSpanish ? 'Ver actividad' : 'View activity',

                      style: const TextStyle(
                        color: _iceDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: _iceDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _cleanText(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'n/a') {
      return null;
    }

    return text;
  }

  static bool _isAvailabilityText(String value) {
    final normalized = value.trim().toLowerCase();

    return normalized == 'ver disponibilidad con el operador' ||
        normalized == 'ver disponibilidad con el operador.';
  }
}

// ===================================================================
// FILA DE INFORMACIÓN
// ===================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  static const Color _iceDark = Color(0xFF2E5F73);

  static const Color _textSecondary = Color(0xFF6F8792);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 18, color: _iceDark),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
