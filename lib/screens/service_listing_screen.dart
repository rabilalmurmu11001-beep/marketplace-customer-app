import 'package:customer_app/network/services/sevicesService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';
import '../store/use_app_store.dart';

class ServiceListingScreen extends ConsumerStatefulWidget {
  final String initialCategory;
  const ServiceListingScreen({super.key, this.initialCategory = 'All'});

  @override
  ConsumerState<ServiceListingScreen> createState() =>
      _ServiceListingScreenState();
}

class _ServiceListingScreenState extends ConsumerState<ServiceListingScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final services = ref.read(serviceListingServiceProvider);

      if (services == null) {
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
    });
  }

  @override
  void didUpdateWidget(ServiceListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _selectedCategory = widget.initialCategory;
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    final allServices = ref.watch(serviceListingServiceProvider) ?? [];
    if (_selectedCategory == 'All') {
      return allServices;
    }
    return allServices
        .where((s) => s['category']['id'] == _selectedCategory)
        .toList();
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
        final name = cat['name'] ?? '';
        final key = cat['id'] ?? '';
        return {'key': key, 'label': name};
      }),
    ];

    final filteredServices = _filteredServices;

    print("filtered $filteredServices");

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sanitization Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${filteredServices.length} Available Near You',
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
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categoriesList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categoriesList[index];
                  final isSelected = cat['key'] == _selectedCategory;

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
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
                                  ? BrandColors.accent.withValues(alpha: 0.12)
                                  : const Color(0xFFE6F4F2))
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? BrandColors.accent.withValues(alpha: 0.3)
                              : theme.dividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? BrandColors.accent
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: filteredServices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_outlined,
                    size: 48,
                    color: BrandColors.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Services Available',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing your category filter.',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
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
                    rating: _asString(
                      '★ ${service['rating']} (${service['reviewCount']} reviewers)',
                    ),
                    price: _asString(service['basePrice']),
                    quoteType: _asString(service['quoteType']),
                    theme: theme,
                    isDark: isDark,
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
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
                            Icons.image_not_supported_outlined,
                            size: 20,
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
                                Icons.image_not_supported_outlined,
                                size: 20,
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
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
                    '₹ $price',
                    style: const TextStyle(
                      fontSize: 16,
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
