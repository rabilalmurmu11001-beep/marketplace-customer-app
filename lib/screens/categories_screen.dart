import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/categoryService.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';
import '../utils/categoryIcons.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final List<List<Color>> _presetGradients = const [
    [Color(0xFF0D9488), Color(0xFF0F766E)],
    [Color(0xFFE11D48), Color(0xFFBE123C)],
    [Color(0xFF06B6D4), Color(0xFF0891B2)],
    [Color(0xFFD97706), Color(0xFFB45309)],
    [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    [Color(0xFF059669), Color(0xFF047857)],
    [Color(0xFF4B5563), Color(0xFF374151)],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (ref.read(homeCategoriesProvider) == null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final catRes = await ref.read(categoryServiceProvider).getCategories();
        final catData = catRes.data;
        if (catData is Map<String, dynamic> &&
            catData.containsKey('categories')) {
          final list = catData['categories'] as List?;
          if (list != null) {
            ref
                .read(homeCategoriesProvider.notifier)
                .setCategories(List<Map<String, dynamic>>.from(list));
          }
        }
      } catch (_) {
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredCategories(
    List<Map<String, dynamic>> categories,
  ) {
    if (_searchQuery.trim().isEmpty) {
      return categories;
    }
    final query = _searchQuery.toLowerCase();
    return categories.where((c) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      final desc = c['description']?.toString().toLowerCase() ?? '';
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(homeCategoriesProvider) ?? [];
    final filteredCategories = _getFilteredCategories(categories);

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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                child: _isLoading && categories.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: BrandColors.accent,
                          strokeWidth: 2.5,
                        ),
                      )
                    : filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 48,
                              color: theme.dividerColor,
                            ),
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final name = cat['name']?.toString() ?? 'Category';
                          final id = cat['id']?.toString() ?? '';
                          final desc = cat['description']?.toString() ??
                              'Explore services in $name';
                          final gradient =
                              _presetGradients[index % _presetGradients.length];
                          final icon = getCategoryIcon(name);

                          return InkWell(
                            onTap: () {
                              context.go('/search?category=$id');
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
                                        colors: gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
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
