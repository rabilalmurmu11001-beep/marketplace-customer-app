import 'package:customer_app/network/services/categoryService.dart';
import 'package:customer_app/network/services/sevicesService.dart';
import 'package:customer_app/network/services/userService.dart';
import 'package:customer_app/store/use_app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/recommended_service_card.dart';
import '../widgets/promo_banner_card.dart';
import '../widgets/active_bookings_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the active address when the HomeScreen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final Map<String, dynamic>? customerProfile = ref.read(
        customerProfileProvider,
      );
      if (customerProfile == null) {
        _refreshData();
        _refreshRecommendedServices();
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      final userProfile = await ref.read(userServiceProvider).getUserProfile();
      final userData = userProfile.data;
      if (userData is Map<String, dynamic>) {
        ref.read(customerProfileProvider.notifier).setProfile(userData['user']);
      }

      final categoriesResponse = await ref
          .read(categoryServiceProvider)
          .getCategories();
      final categoriesData = categoriesResponse.data;
      if (categoriesData is Map<String, dynamic> &&
          categoriesData.containsKey('categories')) {
        ref
            .read(homeCategoriesProvider.notifier)
            .setCategories(
              List<Map<String, dynamic>>.from(categoriesData['categories']),
            );
      }

      await _refreshRecommendedServices();
    } catch (_) {
      // Gracefully ignore refresh network failure in pull-to-refresh
    }
  }

  Future<void> _refreshRecommendedServices() async {
    try {
      final recommendedServicesResponse = await ref
          .read(servicesServiceProvider)
          .getRecommendedServices();
      final recommendedServicesData = recommendedServicesResponse.data;
      
      List<dynamic>? servicesList;
      if (recommendedServicesData is List) {
        servicesList = recommendedServicesData;
      } else if (recommendedServicesData is Map<String, dynamic> &&
          recommendedServicesData.containsKey('services')) {
        servicesList = recommendedServicesData['services'] as List?;
      }

      if (servicesList != null) {
        ref
            .read(homeRecommendedServicesProvider.notifier)
            .setRecommendedServices(
              List<Map<String, dynamic>>.from(servicesList),
            );
      }
    } catch (_) {
      // Gracefully ignore refresh network failure in pull-to-refresh
    }
  }

  // Helper method to get the dynamic greeting based on the current time
  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  IconData _getCategoryIcon(String label) {
    switch (label.toLowerCase().trim()) {
      case 'cleaning':
      case 'home cleaning':
        return Icons.cleaning_services_outlined;
      case 'repair':
        return Icons.build_outlined;
      case 'painting':
        return Icons.format_paint_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'electric':
      case 'electrician':
      case 'electrical':
        return Icons.electrical_services_outlined;
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'appliance':
        return Icons.kitchen_outlined;
      case 'beauty':
        return Icons.spa_outlined;
      case 'sofa':
      case 'sofa care':
      case 'sofa cleaning':
        return Icons.weekend_outlined;
      case 'ac':
      case 'ac servicing':
      case 'ac service':
        return Icons.ac_unit_outlined;
      case 'garden':
      case 'garden care':
        return Icons.yard_outlined;
      case 'pest control':
      case 'pest':
        return Icons.bug_report_outlined;
      default:
        return Icons.construction_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerProfile = ref.watch(customerProfileProvider);
    final categories = ref.watch(homeCategoriesProvider);
    final recommendedServices = ref.watch(homeRecommendedServicesProvider);

    print('Recommended Services: $recommendedServices'); // Debugging line

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppState(),
          builder: (context, _) {
            final appState = AppState();
            final address = appState.activeAddress;

            return RefreshIndicator(
              onRefresh: _refreshData,
              color: BrandColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Header & Notification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDynamicGreeting(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${customerProfile?['username'] ?? 'User'}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Icon(
                              Icons.notifications_none_outlined,
                              size: 18,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location Selector
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: BrandColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${address.label.split(' ').first} • ${address.street}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Context-Sensitive Banner
                    const PromoBannerCard(),
                    const SizedBox(height: 24),

                    // Categories Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/categories'),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: BrandColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children:
                          categories
                              ?.map(
                                (dynamic data) => CategoryCard(
                                  title: data['name'] ?? '',
                                  icon: _getCategoryIcon(data['name'] ?? ''),
                                  label: data['name'] ?? '',
                                ),
                              )
                              .toList() ??
                          [],
                    ),

                    const SizedBox(height: 28),

                    // Today's / Active Bookings Section
                    ActiveBookingsSection(appState: appState),

                     Text(
                      'Recommended Services',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    recommendedServices == null || recommendedServices.isEmpty
                        ? const Column(
                            children: [
                              RecommendedServiceCard(
                                title: 'Sofa Deep Cleaning',
                                price: '₹499',
                                rating: '★ 4.9',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=200&auto=format&fit=crop',
                              ),
                              RecommendedServiceCard(
                                title: 'AC Service',
                                price: '₹799',
                                rating: '★ 4.8',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=200&auto=format&fit=crop',
                              ),
                              RecommendedServiceCard(
                                title: 'Bathroom Cleaning',
                                price: '₹599',
                                rating: '★ 4.7',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=200&auto=format&fit=crop',
                              ),
                            ],
                          )
                        : Column(
                            children: recommendedServices.map((service) {
                              final title = service['name'] ?? '';
                              final price = service['basePrice'] != null ? '₹${service['basePrice']}' : '₹0';
                              final rating = service['rating'] != null ? '★ ${service['rating']}' : '★ 5.0';
                              final imageUrl = service['image'] ?? '';
                              return RecommendedServiceCard(
                                title: title,
                                price: price,
                                rating: rating,
                                imageUrl: imageUrl,
                              );
                            }).toList(),
                          ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
