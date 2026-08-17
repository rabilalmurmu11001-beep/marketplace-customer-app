import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class ReviewItem {
  final String author;
  final double rating;
  final String comment;
  final String date;

  const ReviewItem({
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  final List<ReviewItem> _reviews = const [
    ReviewItem(
      author: 'Liam G.',
      rating: 5.0,
      comment: 'Exceptional compliance framework. Detergents are completely non-toxic. Highly scannable execution metrics.',
      date: '2 days ago',
    ),
    ReviewItem(
      author: 'Sarah M.',
      rating: 5.0,
      comment: 'Very professional. The sofa looks brand new now and they completed it within an hour.',
      date: '1 week ago',
    ),
    ReviewItem(
      author: 'David K.',
      rating: 4.0,
      comment: 'Great service quality. They were on time and very thorough. Highly recommended.',
      date: '2 weeks ago',
    ),
    ReviewItem(
      author: 'Elena R.',
      rating: 5.0,
      comment: 'Amazing job! Removed stains that had been there for years. The team was super polite and clean.',
      date: '3 weeks ago',
    ),
    ReviewItem(
      author: 'Marcus P.',
      rating: 4.0,
      comment: 'Sofa cleaning was done nicely, the chemical smells vanished after a few hours as promised. Good value.',
      date: '1 month ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Reviews',
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
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          children: [
            // Aggregated Summary Card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4.9',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: BrandColors.accent,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Icon(Icons.star, color: Colors.amber, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Based on 450 reviews',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Progress Bars Breakdown
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingRow(5, 0.9, theme),
                        const SizedBox(height: 4),
                        _buildRatingRow(4, 0.08, theme),
                        const SizedBox(height: 4),
                        _buildRatingRow(3, 0.02, theme),
                        const SizedBox(height: 4),
                        _buildRatingRow(2, 0.00, theme),
                        const SizedBox(height: 4),
                        _buildRatingRow(1, 0.00, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Detailed Feedbacks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            
            // List of reviews
            ...List.generate(_reviews.length, (index) {
              final review = _reviews[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: BrandColors.accent.withValues(alpha: 0.1),
                                child: Text(
                                  review.author[0],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: BrandColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                review.author,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                review.date,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.star,
                                    color: starIndex < review.rating.floor() ? Colors.amber : Colors.grey.shade300,
                                    size: 12,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        review.comment,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(int stars, double percentage, ThemeData theme) {
    return Row(
      children: [
        Text(
          '$stars',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Colors.amber, size: 10),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: theme.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(BrandColors.accent),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percentage * 100).toInt()}%',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}
