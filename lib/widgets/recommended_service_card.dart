import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class RecommendedServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final String rating;
  final String imageUrl;
  final String serviceId;

  const RecommendedServiceCard({
    super.key,
    required this.title,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Service Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 60,
                  height: 60,
                  color: isDark
                      ? BrandColors.darkBorder
                      : BrandColors.lightBorder,
                  child: const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
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
                  width: 60,
                  height: 60,
                  color: isDark
                      ? BrandColors.darkBorder
                      : BrandColors.lightBorder,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 18,
                      color: BrandColors.accent,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Service Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Price and Book Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.accent,
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () =>
                    context.go('/service-detail?service_id=$serviceId'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Book',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
