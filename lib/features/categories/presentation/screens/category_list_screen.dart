import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class CategoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageUrl,
  });
}

class CategoryListScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String searchPlaceholder;
  final List<String> tabs;
  final String selectedTab;
  final List<CategoryItem> featuredItems;
  final List<CategoryItem> popularItems;
  final ValueChanged<CategoryItem> onItemClick;

  /// Callback que debe ejecutar la pantalla superior
  /// para volver a consultar los datos.
  final Future<void> Function()? onReload;

  const CategoryListScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchPlaceholder,
    required this.tabs,
    required this.selectedTab,
    required this.featuredItems,
    required this.popularItems,
    required this.onItemClick,
    this.onReload,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  late String _activeTab;

  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.selectedTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================================================================
  // RECARGAR DATOS
  // ================================================================

  Future<void> _handleReload() async {
    if (_isReloading) {
      return;
    }

    final reload = widget.onReload;

    if (reload == null) {
      return;
    }

    setState(() {
      _isReloading = true;
    });

    try {
      await reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información actualizada.'),
          duration: Duration(milliseconds: 900),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible actualizar la información.\n$error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==============================================================
    // FILTRO DE BÚSQUEDA
    // ==============================================================

    final query = _searchQuery.trim().toLowerCase();

    final filteredFeaturedItems = widget.featuredItems.where((item) {
      if (query.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    final filteredPopularItems = widget.popularItems.where((item) {
      if (query.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),

      body: SafeArea(
        // ==========================================================
        // PULL TO REFRESH
        // ==========================================================
        child: RefreshIndicator(
          onRefresh: _handleReload,
          color: AppTheme.primaryDark,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryDark,
                      ),

                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },

                      padding: EdgeInsets.zero,

                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(width: 12),

                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryDark,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    const Expanded(
                      child: Text(
                        'Coyhaique, Aysén',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF26413F),
                        ),
                      ),
                    ),

                    // ==============================================
                    // BOTÓN DE RECARGA
                    // ==============================================
                    if (widget.onReload != null)
                      IconButton(
                        tooltip: 'Actualizar',

                        onPressed: _isReloading ? null : _handleReload,

                        icon: _isReloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryDark,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: AppTheme.primaryDark,
                                size: 21,
                              ),
                      ),

                    const CircleAvatar(
                      radius: 19,
                      backgroundColor: Color(0xFFE8EEEE),
                      child: Icon(
                        Icons.bookmark_border,
                        color: AppTheme.primaryDark,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TÍTULO
                // ==================================================
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6F7E7C),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // BUSCADOR
                // ==================================================
                TextField(
                  controller: _searchController,

                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },

                  decoration: InputDecoration(
                    hintText: widget.searchPlaceholder,

                    prefixIcon: const Icon(Icons.search, color: Colors.grey),

                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),

                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,

                    filled: true,

                    fillColor: const Color(0xFFF0F1F1),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TABS
                // ==================================================
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,

                  child: Row(
                    children: widget.tabs.map((tab) {
                      final isSelected = tab == _activeTab;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = tab;
                          });
                        },

                        child: Padding(
                          padding: const EdgeInsets.only(right: 18),

                          child: Column(
                            children: [
                              Text(
                                tab,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primaryDark
                                      : Colors.grey,

                                  fontSize: 14,

                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),

                              const SizedBox(height: 5),

                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),

                                height: 2,

                                width: isSelected ? 24 : 0,

                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDark,

                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // RECOMENDADOS
                // ==================================================
                const Text(
                  'Recomendados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),

                const SizedBox(height: 14),

                if (filteredFeaturedItems.isEmpty)
                  _buildEmptySearch()
                else
                  SizedBox(
                    height: 230,

                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,

                      itemCount: filteredFeaturedItems.length,

                      itemBuilder: (context, index) {
                        final item = filteredFeaturedItems[index];

                        return GestureDetector(
                          onTap: () {
                            widget.onItemClick(item);
                          },

                          child: Container(
                            width: 180,

                            margin: const EdgeInsets.only(right: 16),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              color: Colors.grey[200],
                            ),

                            clipBehavior: Clip.antiAlias,

                            child: _buildFeaturedCard(item),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 28),

                // ==================================================
                // POPULARES
                // ==================================================
                const Text(
                  'Popular',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),

                const SizedBox(height: 14),

                if (filteredPopularItems.isEmpty)
                  _buildEmptySearch()
                else
                  ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: filteredPopularItems.length,

                    itemBuilder: (context, index) {
                      final item = filteredPopularItems[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),

                        height: 140,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),

                          color: Colors.grey[300],
                        ),

                        clipBehavior: Clip.antiAlias,

                        child: InkWell(
                          onTap: () {
                            widget.onItemClick(item);
                          },

                          child: _buildPopularCard(item),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =================================================================
  // TARJETA RECOMENDADA
  // =================================================================

  Widget _buildFeaturedCard(CategoryItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(item.imageUrl),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,

              end: Alignment.bottomCenter,

              colors: [
                Colors.transparent,

                Colors.black87.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 16,
          left: 16,
          right: 16,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================================================================
  // TARJETA POPULAR
  // =================================================================

  Widget _buildPopularCard(CategoryItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(item.imageUrl),

        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,

              end: Alignment.centerRight,

              colors: [Colors.black87, Colors.black38, Colors.transparent],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 21,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================================================================
  // IMAGEN
  // =================================================================

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        color: AppTheme.primaryDark,

        child: const Center(
          child: Icon(Icons.landscape_rounded, color: Colors.white70, size: 42),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,

      fit: BoxFit.cover,

      placeholder: (context, url) {
        return Container(
          color: const Color(0xFFE8EEEE),

          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,

              color: AppTheme.primaryDark,
            ),
          ),
        );
      },

      errorWidget: (context, url, error) {
        return Container(
          color: AppTheme.primaryDark,

          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,

              color: Colors.white70,

              size: 38,
            ),
          ),
        );
      },
    );
  }

  // =================================================================
  // SIN RESULTADOS
  // =================================================================

  Widget _buildEmptySearch() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),

      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F4),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 34, color: Colors.grey),

          const SizedBox(height: 8),

          Text(
            _searchQuery.isEmpty
                ? 'No hay elementos disponibles.'
                : 'No se encontraron resultados para "$_searchQuery"',

            textAlign: TextAlign.center,

            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
