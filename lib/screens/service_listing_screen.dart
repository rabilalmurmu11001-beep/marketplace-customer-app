import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/categoryService.dart';
import '../network/services/sevicesService.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class ServiceListingScreen extends ConsumerStatefulWidget {
  final String initialCategory;
  const ServiceListingScreen({super.key, this.initialCategory = 'All'});

  @override
  ConsumerState<ServiceListingScreen> createState() =>
      _ServiceListingScreenState();
}

class _ServiceListingScreenState extends ConsumerState<ServiceListingScreen> {
  late String _selectedCategory;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ServiceListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      setState(() {
        _selectedCategory = widget.initialCategory;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch categories if not yet present in store
      if (ref.read(homeCategoriesProvider) == null) {
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
      }

      // 2. Fetch services if not yet present in store
      if (ref.read(serviceListingServiceProvider) == null) {
        final res = await ref.read(servicesServiceProvider).getAllServices();
        final data = res.data;
        List<dynamic>? servicesList;
        if (data is List) {
          servicesList = data;
        } else if (data is Map<String, dynamic> &&
            data.containsKey('services')) {
          servicesList = data['services'] as List?;
        }

        if (servicesList != null) {
          ref
              .read(serviceListingServiceProvider.notifier)
              .setServices(List<Map<String, dynamic>>.from(servicesList));
        }
      }
    } catch (_) {
      // Handled gracefully with fallback UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshServices() async {
    try {
      final res = await ref.read(servicesServiceProvider).getAllServices();
      final data = res.data;
      List<dynamic>? servicesList;
      if (data is List) {
        servicesList = data;
      } else if (data is Map<String, dynamic> && data.containsKey('services')) {
        servicesList = data['services'] as List?;
      }

      if (servicesList != null) {
        ref
            .read(serviceListingServiceProvider.notifier)
            .setServices(List<Map<String, dynamic>>.from(servicesList));
      }
    } catch (_) {}
  }

  bool _isCategoryActive(String key, String label) {
    if (key == 'All') {
      return _selectedCategory == 'All' || _selectedCategory.isEmpty;
    }

    final sel = _selectedCategory.trim().toLowerCase();
    if (key.toLowerCase() == sel) return true;
    if (label.toLowerCase() == sel) return true;
    if (label.toLowerCase().contains(sel) || sel.contains(label.toLowerCase())) {
      return true;
    }

    return false;
  }

  List<Map<String, dynamic>> get _filteredServices {
    final allServices = ref.watch(serviceListingServiceProvider) ?? [];
    var list = allServices;

    // Filter by selected category
    if (_selectedCategory != 'All' && _selectedCategory.isNotEmpty) {
      final target = _selectedCategory.trim().toLowerCase();

      // Find any matching category in categories store for cross-resolution
      final categoriesState = ref.watch(homeCategoriesProvider) ?? [];
      final matchedCat = categoriesState.firstWhere(
        (c) {
          final cId = c['id']?.toString().toLowerCase() ?? '';
          final cName = c['name']?.toString().toLowerCase() ?? '';
          return cId == target ||
              cName == target ||
              cName.contains(target) ||
              target.contains(cName);
        },
        orElse: () => <String, dynamic>{},
      );

      final matchedCatId = matchedCat['id']?.toString().toLowerCase() ?? '';
      final matchedCatName = matchedCat['name']?.toString().toLowerCase() ?? '';

      list = list.where((s) {
        // Direct category_id match
        final catId = s['category_id']?.toString().toLowerCase() ?? '';
        if (catId.isNotEmpty &&
            (catId == target ||
                (matchedCatId.isNotEmpty && catId == matchedCatId))) {
          return true;
        }

        // Nested category map match
        if (s['category'] is Map) {
          final nestedId = s['category']['id']?.toString().toLowerCase() ?? '';
          if (nestedId.isNotEmpty &&
              (nestedId == target ||
                  (matchedCatId.isNotEmpty && nestedId == matchedCatId))) {
            return true;
          }

          final nestedName =
              s['category']['name']?.toString().toLowerCase() ?? '';
          if (nestedName.isNotEmpty &&
              (nestedName == target ||
                  nestedName.contains(target) ||
                  target.contains(nestedName) ||
                  (matchedCatName.isNotEmpty &&
                      (nestedName == matchedCatName ||
                          nestedName.contains(matchedCatName))))) {
            return true;
          }
        } else if (s['category'] is String) {
          final catStr = s['category'].toString().toLowerCase();
          if (catStr == target ||
              catStr.contains(target) ||
              target.contains(catStr) ||
              (matchedCatName.isNotEmpty && catStr.contains(matchedCatName))) {
            return true;
          }
        }

        // Match service name / description fallback
        final serviceName = s['name']?.toString().toLowerCase() ?? '';
        if (serviceName.contains(target) ||
            (matchedCatName.isNotEmpty &&
                serviceName.contains(matchedCatName))) {
          return true;
        }

        return false;
      }).toList();
    }

    // Filter by text search query if provided
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final name = s['name']?.toString().toLowerCase() ?? '';
        final desc = s['description']?.toString().toLowerCase() ?? '';
        return name.contains(q) || desc.contains(q);
      }).toList();
    }

    return list;
  }

  Color _parseColor(dynamic value, Color fallback) {
    if (value is String && value.isNotEmpty) {
      var hex = value.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    if (value is int) return Color(value);
    return fallback;
  }

  String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoriesState = ref.watch(homeCategoriesProvider) ?? [];
    final List<Map<String, String>> categoriesList = [
      {'key': 'All', 'label': 'All Services'},
      ...categoriesState.map((cat) {
        final name = cat['name']?.toString() ?? '';
        final key = cat['id']?.toString() ?? name;
        return {'key': key, 'label': name};
      }),
    ];

    final filteredServices = _filteredServices;
    final allServices = ref.watch(serviceListingServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Services',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${filteredServices.length} Results Near You',
              style: const TextStyle(
                fontSize: 11,
                color: BrandColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.cardColor,
                      hintText: 'Search services...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: BrandColors.accent,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: BrandColors.accent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Category Horizontal Filter Pills
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categoriesList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categoriesList[index];
                    final isSelected = _isCategoryActive(
                      cat['key']!,
                      cat['label']!,
                    );

                    return Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['key']!;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? BrandColors.accent.withValues(
                                          alpha: 0.15,
                                        )
                                      : const Color(0xFFE6F4F2))
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? BrandColors.accent
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? BrandColors.accent
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading && allServices == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: BrandColors.accent,
                strokeWidth: 2.5,
              ),
            );
          }

          if (filteredServices.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshServices,
              color: BrandColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: BrandColors.accent.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_outlined,
                                size: 48,
                                color: BrandColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Services Found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try selecting "All Services" or clearing your search.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BrandColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Show All Services'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshServices,
            color: BrandColors.accent,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: _buildServiceCard(
                    context: context,
                    serviceId: _asString(service['id']),
                    badgeText: _asString(service['badgeText']),
                    badgeColor: _parseColor(
                      service['badgeColor'],
                      BrandColors.accent,
                    ),
                    badgeTextColor: _parseColor(
                      service['badgeTextColor'],
                      Colors.white,
                    ),
                    title: _asString(service['name']),
                    imageUrl: _asString(service['image']),
                    description: _asString(service['description']),
                    rating: service['rating'] != null
                        ? '★ ${service['rating']}${service['reviewCount'] != null ? ' (${service['reviewCount']})' : ''}'
                        : '★ 4.9 (120+)',
                    price: _asString(service['basePrice']),
                    quoteType: _asString(service['quoteType'], 'Fixed'),
                    theme: theme,
                    isDark: isDark,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String serviceId,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String imageUrl,
    required String description,
    required String rating,
    required String price,
    required String quoteType,
    required ThemeData theme,
    required bool isDark,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: () => context.push('/service-detail?service_id=$serviceId'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Service Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isEmpty
                    ? Container(
                        width: 70,
                        height: 70,
                        color: isDark
                            ? BrandColors.darkBorder
                            : BrandColors.lightBorder,
                        child: const Center(
                          child: Icon(
                            Icons.home_repair_service_outlined,
                            size: 24,
                            color: BrandColors.accent,
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 70,
                            height: 70,
                            color: isDark
                                ? BrandColors.darkBorder
                                : BrandColors.lightBorder,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    BrandColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            color: isDark
                                ? BrandColors.darkBorder
                                : BrandColors.lightBorder,
                            child: const Center(
                              child: Icon(
                                Icons.home_repair_service_outlined,
                                size: 24,
                                color: BrandColors.accent,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 14),

              // Service details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Price and Quote Type
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quoteType.toUpperCase(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
