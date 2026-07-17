import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class CategoryItem {
  final String label;
  final String description;
  final IconData icon;
  final String routeKey;
  final List<Color> gradientColors;

  const CategoryItem({
    required this.label,
    required this.description,
    required this.icon,
    required this.routeKey,
    required this.gradientColors,
  });
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<CategoryItem> _allCategories = const [
    CategoryItem(
      label: 'Cleaning',
      description: 'Home sanitization, sterilization & disinfection',
      icon: Icons.cleaning_services_outlined,
      routeKey: 'Cleaning',
      gradientColors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    ),
    CategoryItem(
      label: 'Sofa Care',
      description: 'Deep shampooing, fabric treatment & vacuuming',
      icon: Icons.weekend_outlined,
      routeKey: 'Sofa',
      gradientColors: [Color(0xFFE11D48), Color(0xFFBE123C)],
    ),
    CategoryItem(
      label: 'AC Servicing',
      description: 'Filter jet washing, coolant top-up & repair',
      icon: Icons.ac_unit_outlined,
      routeKey: 'AC',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    ),
    CategoryItem(
      label: 'Electrician',
      description: 'Wiring fixes, switchboards & lighting setup',
      icon: Icons.electrical_services_outlined,
      routeKey: 'Electric',
      gradientColors: [Color(0xFFD97706), Color(0xFFB45309)],
    ),
    CategoryItem(
      label: 'Plumbing',
      description: 'Leak repair, tap install & pipe sanitizing',
      icon: Icons.plumbing_outlined,
      routeKey: 'Plumbing',
      gradientColors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    CategoryItem(
      label: 'Painting',
      description: 'Interior wall paint, coatings & color styling',
      icon: Icons.format_paint_outlined,
      routeKey: 'Painting',
      gradientColors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    ),
    CategoryItem(
      label: 'Garden Care',
      description: 'Pruning, lawn clearing & soil maintenance',
      icon: Icons.yard_outlined,
      routeKey: 'Garden',
      gradientColors: [Color(0xFF059669), Color(0xFF047857)],
    ),
    CategoryItem(
      label: 'Pest Control',
      description: 'Eco-friendly termite, bug & rodent control',
      icon: Icons.bug_report_outlined,
      routeKey: 'Pest Control',
      gradientColors: [Color(0xFF4B5563), Color(0xFF374151)],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryItem> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return _allCategories;
    }
    final query = _searchQuery.toLowerCase();
    return _allCategories.where((c) {
      return c.label.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.cardColor,
                  hintText: 'Search categories...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: BrandColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Explore Service Domains',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Grid
              Expanded(
                child: _filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_outlined, size: 48, color: theme.dividerColor),
                            const SizedBox(height: 16),
                            Text(
                              'No Categories Match Search',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try spelling in another way.',
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = _filteredCategories[index];
                          return InkWell(
                            onTap: () {
                              context.go('/search?category=${cat.routeKey}');
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.dividerColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.01),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Styled Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: cat.gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    cat.label,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 10,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
