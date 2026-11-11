import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/guest_profile.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';

/// Perfil animal típico de Aysén que el invitado elige antes de registrarse.
class GuestAnimal {
  const GuestAnimal({
    required this.id,
    required this.nameEs,
    required this.nameEn,
    required this.roleEs,
    required this.roleEn,
    required this.asset,
  });

  final String id;
  final String nameEs;
  final String nameEn;
  final String roleEs;
  final String roleEn;

  final String asset;
}

const List<GuestAnimal> guestAnimals = [
  GuestAnimal(
    id: 'mochilero',
    nameEs: 'Zorro culpeo',
    nameEn: 'Culpeo fox',
    roleEs: 'Mochilero',
    roleEn: 'Backpacker',
    asset: 'assets/images/animal_culpeo.png',
  ),
  GuestAnimal(
    id: 'campista',
    nameEs: 'Huemul',
    nameEn: 'Huemul',
    roleEs: 'Campista',
    roleEn: 'Camper',
    asset: 'assets/images/animal_huemul.png',
  ),
  GuestAnimal(
    id: 'escalador',
    nameEs: 'Puma',
    nameEn: 'Puma',
    roleEs: 'Escalador',
    roleEn: 'Climber',
    asset: 'assets/images/animal_puma.png',
  ),
  GuestAnimal(
    id: 'casero',
    nameEs: 'Chucao',
    nameEn: 'Chucao tapaculo',
    roleEs: 'Casero',
    roleEn: 'Homebody',
    asset: 'assets/images/animal_chucao.png',
  ),
];

/// Pregunta cómo quiere aparecer el invitado antes de registrarse.
class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';

    Future<void> choose(GuestAnimal animal) async {
      await GuestStore.setAnimal(animal.id);
      if (context.mounted) context.go('/home');
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(BcSpace.gutter, 24, BcSpace.gutter, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BcTag(
                  isSpanish ? 'Antes de registrarte' : 'Before signing up',
                  lead: 'Aysén',
                  style: BcTagStyle.glacier,
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isSpanish
                          ? 'CÓMO QUIERES\nAPARECER'
                          : 'HOW DO YOU\nWANT TO APPEAR',
                      style: BcText.display(40),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isSpanish
                      ? 'Elige un perfil. Podrás cambiarlo después.'
                      : 'Pick a profile. You can change it later.',
                  style: BcText.body(color: BcColors.muted),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: [
                      for (final animal in guestAnimals)
                        _AnimalTile(
                          animal: animal,
                          isSpanish: isSpanish,
                          onTap: () => choose(animal),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  const _AnimalTile({
    required this.animal,
    required this.isSpanish,
    required this.onTap,
  });

  final GuestAnimal animal;
  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = isSpanish ? animal.roleEs : animal.roleEn;
    final name = isSpanish ? animal.nameEs : animal.nameEn;

    return BcPressable(
      onTap: onTap,
      semanticLabel: '$role, $name',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  animal.asset,
                  fit: BoxFit.contain,
                  semanticLabel: name,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: BcText.label(color: BcColors.glacierDeep),
                ),
                const SizedBox(height: 4),
                Text(name, style: BcText.title()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
