import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/recommended_service_card.dart';
import '../widgets/promo_banner_card.dart';
import '../widgets/active_bookings_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppState(),
          builder: (context, _) {
            final appState = AppState();
            final address = appState.activeAddress;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                            'Good Morning',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Emma Watson',
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
                    children: const [
                      CategoryCard(
                        icon: Icons.cleaning_services_outlined,
                        label: 'Cleaning',
                      ),
                      CategoryCard(
                        icon: Icons.electrical_services_outlined,
                        label: 'Electric',
                      ),
                      CategoryCard(
                        icon: Icons.plumbing_outlined,
                        label: 'Plumbing',
                      ),
                      CategoryCard(icon: Icons.ac_unit_outlined, label: 'AC'),
                      CategoryCard(icon: Icons.weekend_outlined, label: 'Sofa'),
                      CategoryCard(
                        icon: Icons.format_paint_outlined,
                        label: 'Painting',
                      ),
                      CategoryCard(icon: Icons.yard_outlined, label: 'Garden'),
                      CategoryCard(
                        icon: Icons.bug_report_outlined,
                        label: 'Pest Control',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Today's / Active Bookings Section
                  ActiveBookingsSection(appState: appState),

                  // Recommended Services
                  Text(
                    'Recommended Services',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const RecommendedServiceCard(
                    title: 'Sofa Deep Cleaning',
                    price: '₹499',
                    rating: '★ 4.9',
                    imageUrl:
                        'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=200&auto=format&fit=crop',
                  ),
                  const RecommendedServiceCard(
                    title: 'AC Service',
                    price: '₹799',
                    rating: '★ 4.8',
                    imageUrl:
                        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=200&auto=format&fit=crop',
                  ),
                  const RecommendedServiceCard(
                    title: 'Bathroom Cleaning',
                    price: '₹599',
                    rating: '★ 4.7',
                    imageUrl:
                        'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=200&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
