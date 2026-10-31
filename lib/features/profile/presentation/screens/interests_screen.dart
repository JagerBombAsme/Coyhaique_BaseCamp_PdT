import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/interests_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../../planner/data/providers/planner_provider.dart'
    show isPlannerCategory;


const String interestsRoute = '/profile/interests';


class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider).languageCode;
    final isSpanish = language == 'es';
    final interests = ref.watch(validInterestsProvider);
    final categoriesAsync = ref.watch(mainCategoriesProvider);
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            BcSpace.gutter,
            top + 14,
            BcSpace.gutter,
            40,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BcCornerButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: isSpanish ? 'Volver' : 'Back',
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            BcKicker(
              interests.isEmpty
                  ? (isSpanish ? 'Sin intereses elegidos' : 'No interests selected')
                  : isSpanish
                      ? '${interests.length} elegidos'
                      : '${interests.length} selected',
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                isSpanish ? 'MIS\nINTERESES' : 'MY\nINTERESTS',
                style: BcText.display(46).copyWith(height: 0.95),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSpanish
                  ? 'Elige lo que te interesa. Se usa para proponerte itinerarios y destacar esas categorías en el inicio. Se guarda solo en este teléfono.'
                  : 'Choose what you are interested in. It is used to suggest itineraries and highlight those categories on the home screen. It is stored only on this phone.',
              style: BcText.body(),
            ),
            const SizedBox(height: 20),
            categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: BcColors.ink),
                ),
              ),
              error: (_, _) => BcMessage(
                icon: Icons.cloud_off_rounded,
                text: isSpanish
                    ? 'No hay conexión ni categorías descargadas.'
                    : 'There is no connection and no downloaded categories.',
                actionLabel: isSpanish ? 'Reintentar' : 'Retry',
                onAction: () => ref.invalidate(categoriesProvider),
              ),
              data: (categories) {
                final visible = categories
                    .where((c) => c.isActive && isPlannerCategory(c.groupType))
                    .toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 54,
                  ),
                  itemBuilder: (context, index) {
                    final category = visible[index];
                    final selected = interests.contains(category.id);
                    return Semantics(
                      selected: selected,
                      child: BcCategoryButton(
                        icon: selected ? Icons.check_rounded : category.icon,
                        label: category.getNombre(language),
                        highlighted: selected,
                        onTap: () => ref
                            .read(interestsProvider.notifier)
                            .toggle(category.id),
                      ),
                    );
                  },
                );
              },
            ),
            if (interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => ref.read(interestsProvider.notifier).clear(),
                  style: TextButton.styleFrom(
                    foregroundColor: BcColors.glacierDeep,
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(isSpanish ? 'Quitar todos' : 'Clear all'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
