import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/reviewServices.dart';
import '../network/services/sevicesService.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final String? serviceId;
  final String? serviceTitle;

  const ReviewsScreen({
    super.key,
    this.serviceId,
    this.serviceTitle,
  });

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _resolvedServiceId;
  String? _resolvedServiceTitle;

  @override
  void initState() {
    super.initState();
    _resolvedServiceId = widget.serviceId;
    _resolvedServiceTitle = widget.serviceTitle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReviews();
    });
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? targetServiceId = _resolvedServiceId;

      // If no service ID provided, retrieve first available service
      if (targetServiceId == null || targetServiceId.isEmpty) {
        final servicesRes =
            await ref.read(servicesServiceProvider).getAllServices();
        if (servicesRes.data is Map<String, dynamic> &&
            servicesRes.data['services'] is List &&
            (servicesRes.data['services'] as List).isNotEmpty) {
          final firstService =
              (servicesRes.data['services'] as List).first as Map<String, dynamic>;
          targetServiceId = firstService['id']?.toString();
          _resolvedServiceTitle = firstService['name']?.toString();
          _resolvedServiceId = targetServiceId;
        }
      }

      if (targetServiceId != null && targetServiceId.isNotEmpty) {
        final response = await ref
            .read(reviewServiceProvider)
            .getReviewsByServiceId(targetServiceId);

        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          final rawReviews = response.data['reviews'];
          if (rawReviews is List) {
            setState(() {
              _reviews = List<Map<String, dynamic>>.from(rawReviews);
            });
          } else {
            setState(() {
              _reviews = [];
            });
          }
        }
      } else {
        setState(() {
          _reviews = [];
        });
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        setState(() {
          _reviews = [];
        });
      } else {
        setState(() {
          _errorMessage =
              dioErr.response?.data?['message']?.toString() ??
              'Failed to load reviews. Please check your network connection.';
        });
      }
    } catch (err) {
      setState(() {
        _errorMessage = 'An error occurred: $err';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 5.0;
    double sum = 0.0;
    int count = 0;
    for (final r in _reviews) {
      final rating = r['ratings'] ?? r['rating'];
      if (rating != null) {
        sum += (rating is num)
            ? rating.toDouble()
            : double.tryParse(rating.toString()) ?? 5.0;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 5.0;
  }

  double _getStarPercentage(int star) {
    if (_reviews.isEmpty) return 0.0;
    int count = 0;
    for (final r in _reviews) {
      final rating = r['ratings'] ?? r['rating'];
      final numVal = (rating is num)
          ? rating.round()
          : int.tryParse(rating?.toString() ?? '5') ?? 5;
      if (numVal == star) {
        count++;
      }
    }
    return count / _reviews.length;
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent';
    try {
      final dt =
          rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return 'Just now';
        }
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return '${weeks}w ago';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {
      return rawDate.toString();
    }
  }

  void _showAddReviewModal() {
    final theme = Theme.of(context);
    final bookings = ref.read(customerBookingsProvider) ?? [];

    final completedBookings = bookings.where((b) {
      final status =
          b['booking']?['bookingStatus']?.toString().toLowerCase() ?? '';
      return status == 'completed' ||
          status == 'accepted' ||
          status == 'in_progress' ||
          status == 'requested';
    }).toList();

    int selectedRating = 5;
    final noteController = TextEditingController();
    String? selectedBookingId;
    if (completedBookings.isNotEmpty) {
      final firstB = completedBookings.first['booking'];
      if (firstB is Map) {
        selectedBookingId = firstB['id']?.toString();
      }
    }
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WRITE A REVIEW',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: BrandColors.accent,
                            letterSpacing: 1.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Star Rating Picker
                    Text(
                      'RATING',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedRating = star;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.star,
                              size: 32,
                              color: star <= selectedRating
                                  ? Colors.amber
                                  : theme.dividerColor,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Associated Booking (if multiple)
                    if (completedBookings.length > 1) ...[
                      Text(
                        'SELECT BOOKING MANIFEST',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedBookingId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: BrandColors.accent),
                          ),
                        ),
                        items: completedBookings.map((b) {
                          final id =
                              b['booking']?['id']?.toString() ?? '';
                          final serviceName =
                              b['service']?['name']?.toString() ?? 'Service';
                          final shortId = id.length > 6 ? id.substring(0, 6) : id;
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              '$serviceName (#$shortId)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedBookingId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Review Note / Feedback input
                    Text(
                      'YOUR FEEDBACK',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: noteController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        hintText:
                            'Share your experience with the service, timeliness, and technician quality...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: BrandColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final note = noteController.text.trim();
                                if (note.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please enter your review feedback.'),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                final finalBookingId = selectedBookingId;
                                if (finalBookingId == null ||
                                    finalBookingId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'A booking manifest reference is required to post a verified review.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                final messenger =
                                    ScaffoldMessenger.of(context);

                                try {
                                  await ref
                                      .read(reviewServiceProvider)
                                      .createReview(
                                        bookingId: finalBookingId,
                                        ratings: selectedRating,
                                        note: note,
                                      );

                                  if (modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                  }

                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '🎉 Review submitted successfully! Thank you.',
                                      ),
                                      backgroundColor: BrandColors.accent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  _fetchReviews();
                                } on DioException catch (dioErr) {
                                  final String err =
                                      dioErr.response?.data?['message']
                                          ?.toString() ??
                                      'Failed to post review. Please try again.';
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(err),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } finally {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Post Review',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avg = _averageRating;
    final reviewCount = _reviews.length;
    final titleText =
        _resolvedServiceTitle != null && _resolvedServiceTitle!.isNotEmpty
            ? _resolvedServiceTitle!
            : 'Customer Reviews';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Reviews',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_resolvedServiceTitle != null &&
                _resolvedServiceTitle!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 11,
                  color: BrandColors.accent,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.rate_review_outlined,
              size: 20,
              color: BrandColors.accent,
            ),
            tooltip: 'Write Review',
            onPressed: _showAddReviewModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_isLoading && _reviews.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: BrandColors.accent,
                  strokeWidth: 2.5,
                ),
              );
            }

            if (_errorMessage != null && _reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to Load Reviews',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchReviews,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _fetchReviews,
              color: BrandColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                              avg.toStringAsFixed(1),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: BrandColors.accent,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  Icons.star,
                                  color: index < avg.floor()
                                      ? Colors.amber
                                      : (index < avg
                                          ? Colors.amber.withValues(alpha: 0.5)
                                          : theme.dividerColor),
                                  size: 15,
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reviewCount > 0
                                  ? 'Based on $reviewCount ${reviewCount == 1 ? "review" : "reviews"}'
                                  : 'Verified Community Rating',
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
                              _buildRatingRow(5, _getStarPercentage(5), theme),
                              const SizedBox(height: 4),
                              _buildRatingRow(4, _getStarPercentage(4), theme),
                              const SizedBox(height: 4),
                              _buildRatingRow(3, _getStarPercentage(3), theme),
                              const SizedBox(height: 4),
                              _buildRatingRow(2, _getStarPercentage(2), theme),
                              const SizedBox(height: 4),
                              _buildRatingRow(1, _getStarPercentage(1), theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Customer Feedback',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewModal,
                        icon: const Icon(
                          Icons.add,
                          size: 14,
                          color: BrandColors.accent,
                        ),
                        label: const Text(
                          'Add Review',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_reviews.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            size: 40,
                            color: BrandColors.accent,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Reviews Yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Be the first to share your experience after completing your appointment!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddReviewModal,
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text('Write First Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // List of real reviews from backend
                    ..._reviews.map((review) {
                      final rawRatings =
                          review['ratings'] ?? review['rating'] ?? 5;
                      final ratingVal = (rawRatings is num)
                          ? rawRatings.toDouble()
                          : double.tryParse(rawRatings.toString()) ?? 5.0;

                      final note = review['note']?.toString() ??
                          review['comment']?.toString() ??
                          'Great service experience!';

                      final user = review['user'] as Map<String, dynamic>?;
                      final author = user?['name']?.toString() ??
                          review['author']?.toString() ??
                          'Verified Customer';
                      final photo = user?['photo']?.toString();
                      final dateStr = _formatDate(
                        review['createdAt'] ?? review['date'],
                      );

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor: BrandColors.accent
                                            .withValues(alpha: 0.12),
                                        backgroundImage: (photo != null &&
                                                photo.isNotEmpty)
                                            ? NetworkImage(photo)
                                            : null,
                                        child: (photo == null || photo.isEmpty)
                                            ? Text(
                                                author.isNotEmpty
                                                    ? author[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: BrandColors.accent,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            author,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                          ),
                                          Text(
                                            dateStr,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontSize: 9.5,
                                                  color: theme.textTheme
                                                      .bodyMedium?.color
                                                      ?.withValues(
                                                        alpha: 0.6,
                                                      ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        Icons.star,
                                        color: starIndex < ratingVal.floor()
                                            ? Colors.amber
                                            : theme.dividerColor,
                                        size: 13,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                note,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark
                                      ? BrandColors.darkTextPrimary
                                      : BrandColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
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
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: theme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(BrandColors.accent),
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
