import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';
import '../../../../core/widgets/category_card.dart';
import '../../../../core/widgets/home_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(String route) onNavigate;
  final VoidCallback onProfileClick;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.onProfileClick,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final language = locale.languageCode;
    final isSpanish = language == 'es';

    final tabs = isSpanish
        ? ['Todos', 'Gastronomía', 'Alojamiento', 'Rutas', 'Cultura']
        : ['All', 'Gastronomy', 'Accommodation', 'Routes', 'Culture'];

    final filteredCategories = homeCategories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      final name = cat.getNombre(language).toLowerCase();
      final desc = cat.getDescripcion(language).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();


    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          HomeHeader(
            onProfileClick: widget.onProfileClick,
          ),
          const SizedBox(height: 8),

          // Search Bar with Filter icon
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: isSpanish
                        ? 'Buscar destinos, restaurantes, rutas...'
                        : 'Search destinations, restaurants, routes...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF0F1F1),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryDark,
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSpanish ? 'Filtros de búsqueda' : 'Search filters',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final isSelected = tab == _selectedTab || (tab == 'Todos' && _selectedTab == 'All');
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = tab;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18.0),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryDark : Colors.grey,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
                 ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                return CategoryCard(
                  category: category,
                  language: language,
                  onClick: () => widget.onNavigate(category.route),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
