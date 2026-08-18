import 'package:customer_app/network/services/addressServices.dart';
import 'package:customer_app/network/services/categoryService.dart';
import 'package:customer_app/network/services/couponsService.dart';
import 'package:customer_app/network/services/sevicesService.dart';
import 'package:customer_app/network/services/userService.dart';
import 'package:customer_app/store/use_app_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/recommended_service_card.dart';
import '../widgets/promo_banner_card.dart';
import '../widgets/active_bookings_section.dart';
import '../utils/categoryIcons.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the active address and data when the HomeScreen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final Map<String, dynamic>? customerProfile = ref.read(
        customerProfileProvider,
      );
      if (customerProfile == null) {
        _refreshData();
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

      // Fetch user addresses from backend API
      try {
        final addressResponse =
            await ref.read(addressServiceProvider).getAllUserAddress();
        final addressData = addressResponse.data;
        if (addressData is Map<String, dynamic> &&
            addressData.containsKey('address')) {
          final addressesList = addressData['address'] as List?;
          if (addressesList != null) {
            ref
                .read(customerAddressProvider.notifier)
                .setCustomerAddress(
                  List<Map<String, dynamic>>.from(addressesList),
                );
          }
        }
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          ref.read(customerAddressProvider.notifier).setCustomerAddress([]);
        }
      }

      // Fetch user bookings from backend API
      try {
        final bookingResponse =
            await ref.read(servicesServiceProvider).getAllBookings();
        final bookingData = bookingResponse.data;
        if (bookingData is Map<String, dynamic> &&
            bookingData.containsKey('bookings')) {
          final bookingsList = bookingData['bookings'] as List?;
          if (bookingsList != null) {
            ref
                .read(customerBookingsProvider.notifier)
                .setBookings(List<Map<String, dynamic>>.from(bookingsList));
          }
        }
      } catch (_) {}

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

      final couponsResponse = await ref
          .read(couponsServiceProvider)
          .getAllCoupons();
      final couponsData = couponsResponse.data;

      List<dynamic>? couponsList;
      if (couponsData is List) {
        couponsList = couponsData;
      } else if (couponsData is Map<String, dynamic> &&
          couponsData.containsKey('coupons')) {
        couponsList = couponsData['coupons'] as List?;
      }

      if (couponsList != null) {
        ref
            .read(homeCouponsProvider.notifier)
            .setCoupons(List<Map<String, dynamic>>.from(couponsList));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerProfile = ref.watch(customerProfileProvider);
    final categories = ref.watch(homeCategoriesProvider);
    final recommendedServices = ref.watch(homeRecommendedServicesProvider);
    final coupons = ref.watch(homeCouponsProvider);

    print('Coupon Data: $coupons'); // Debugging line to check coupon data

    final customerAddresses = ref.watch(customerAddressProvider);
    final currentAddress =
        customerAddresses != null && customerAddresses.isNotEmpty
            ? customerAddresses.first
            : null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
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
                GestureDetector(
                  onTap: () => context.push('/addresses'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: BrandColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          currentAddress != null
                              ? '${currentAddress['title'] ?? 'Address'} • ${currentAddress['house_number'] != null && currentAddress['house_number'].toString().isNotEmpty ? "${currentAddress['house_number']}, " : ""}${currentAddress['street_no_or_name'] ?? currentAddress['city']}'
                              : 'Add delivery address',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 16,
                        color: BrandColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                    // Dynamic Context-Sensitive Banner
                    coupons == null || coupons.isEmpty
                        ? const PromoBannerCard()
                        : SizedBox(
                            height: 160,
                            child: PageView.builder(
                              itemCount: coupons.length,
                              itemBuilder: (context, index) {
                                return PromoBannerCard(coupon: coupons[index]);
                              },
                            ),
                          ),
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
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.08,
                      children:
                          categories
                              ?.map(
                                (dynamic data) => CategoryCard(
                                  title: data['name'] ?? '',
                                  icon: getCategoryIcon(data['name'] ?? ''),
                                  label: data['name'] ?? '',
                                  onTap: () => context.push(
                                    '/search?category=${data['id']}',
                                  ),
                                ),
                              )
                              .toList() ??
                          [],
                    ),

                    const SizedBox(height: 28),

                    // Today's / Active Bookings Section
                    const ActiveBookingsSection(),

                    Text(
                      'Recommended Services',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    recommendedServices == null || recommendedServices.isEmpty
                        ? Center(
                            child: Text(
                              'No recommended services available.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          )
                        : Column(
                            children: recommendedServices.map((service) {
                              final title = service['name'] ?? '';
                              final price = service['basePrice'] != null
                                  ? '₹${service['basePrice']}'
                                  : '₹ 0';
                              final rating = service['rating'] != null
                                  ? '★ ${service['rating']}'
                                  : '★ 5.0';
                              final imageUrl = service['image'] ?? '';
                              final serviceId = service['id'] ?? '';
                              return RecommendedServiceCard(
                                title: title,
                                price: price,
                                rating: rating,
                                imageUrl: imageUrl,
                                serviceId: serviceId,
                              );
                            }).toList(),
                          ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
