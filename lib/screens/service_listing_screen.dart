import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class DiscoveryService {
  final String title;
  final String expert;
  final String distance;
  final String rating;
  final String price;
  final String quoteType;
  final String imageUrl;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String category;

  const DiscoveryService({
    required this.title,
    required this.expert,
    required this.distance,
    required this.rating,
    required this.price,
    required this.quoteType,
    required this.imageUrl,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.category,
  });
}

class ServiceListingScreen extends StatefulWidget {
  final String initialCategory;
  const ServiceListingScreen({super.key, this.initialCategory = 'All'});

  @override
  State<ServiceListingScreen> createState() => _ServiceListingScreenState();
}

class _ServiceListingScreenState extends State<ServiceListingScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void didUpdateWidget(ServiceListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _selectedCategory = widget.initialCategory;
    }
  }

  final List<Map<String, String>> _categories = [
    {'key': 'All', 'label': 'All Services', 'emoji': '✨'},
    {'key': 'Cleaning', 'label': 'Cleaning', 'emoji': '🧹'},
    {'key': 'Sofa', 'label': 'Sofa Care', 'emoji': '🛋️'},
    {'key': 'AC', 'label': 'AC Service', 'emoji': '❄️'},
    {'key': 'Electric', 'label': 'Electrician', 'emoji': '⚡'},
    {'key': 'Plumbing', 'label': 'Plumbing', 'emoji': '🚰'},
    {'key': 'Painting', 'label': 'Painting', 'emoji': '🎨'},
    {'key': 'Garden', 'label': 'Garden Care', 'emoji': '🪴'},
    {'key': 'Pest Control', 'label': 'Pest Control', 'emoji': '🐜'},
  ];

  final List<DiscoveryService> _services = [
    DiscoveryService(
      title: 'Sofa Deep Chemical Wash',
      expert: 'John Hanson',
      distance: '2.4 miles away',
      rating: '★ 4.9 (450 reviews)',
      price: r'$49.00',
      quoteType: 'Fixed Quote',
      imageUrl: 'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=200&auto=format&fit=crop',
      badgeText: 'Vetted Super Partner',
      badgeColor: const Color(0xFFE6F4F2),
      badgeTextColor: BrandColors.accent,
      category: 'Sofa',
    ),
    DiscoveryService(
      title: 'Upholstery Sanitization Suite',
      expert: 'Sophia Rodriguez',
      distance: '1.1 miles away',
      rating: '★ 4.8 (320 reviews)',
      price: r'$85.00',
      quoteType: 'Fixed Quote',
      imageUrl: 'https://images.unsplash.com/photo-1540518614846-7eded433c457?q=80&w=200&auto=format&fit=crop',
      badgeText: 'Elite Expert',
      badgeColor: const Color(0xFFEFF6FF),
      badgeTextColor: Colors.blue,
      category: 'Cleaning',
    ),
    DiscoveryService(
      title: 'AC Deep Jet Wash',
      expert: 'Alex Rivera',
      distance: '3.0 miles away',
      rating: '★ 4.7 (180 reviews)',
      price: r'$59.00',
      quoteType: 'Fixed Quote',
      imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=200&auto=format&fit=crop',
      badgeText: 'Rapid Responder',
      badgeColor: const Color(0xFFFEF3C7),
      badgeTextColor: Colors.amber,
      category: 'AC',
    ),
    DiscoveryService(
      title: 'Kitchen Premium Sterilization',
      expert: 'Maya Lin',
      distance: '1.8 miles away',
      rating: '★ 4.9 (90 reviews)',
      price: r'$75.00',
      quoteType: 'Fixed Quote',
      imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=200&auto=format&fit=crop',
      badgeText: 'Top Vetted',
      badgeColor: const Color(0xFFF3E8FF),
      badgeTextColor: Colors.purple,
      category: 'Cleaning',
    ),
  ];

  List<DiscoveryService> get _filteredServices {
    if (_selectedCategory == 'All') {
      return _services;
    }
    return _services.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              '${_filteredServices.length} Available Near You',
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
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat['key'] == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['key']!;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? BrandColors.accent.withValues(alpha: 0.12) : const Color(0xFFE6F4F2))
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
                          cat['emoji']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? BrandColors.accent : theme.textTheme.bodyMedium?.color,
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
      body: _filteredServices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_outlined, size: 48, color: BrandColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'No Services Available',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
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
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildServiceCard(
                    context: context,
                    badgeText: service.badgeText,
                    badgeColor: service.badgeColor,
                    badgeTextColor: service.badgeTextColor,
                    title: service.title,
                    imageUrl: service.imageUrl,
                    expert: service.expert,
                    distance: service.distance,
                    rating: service.rating,
                    price: service.price,
                    quoteType: service.quoteType,
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
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String imageUrl,
    required String expert,
    required String distance,
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
        onTap: () => context.push('/service-detail'),
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
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 70,
                      height: 70,
                      color: isDark ? BrandColors.darkBorder : BrandColors.lightBorder,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(BrandColors.accent),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      color: isDark ? BrandColors.darkBorder : BrandColors.lightBorder,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                      'Expert: $expert • $distance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
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
                    price,
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
