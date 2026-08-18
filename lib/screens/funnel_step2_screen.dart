import 'package:dio/dio.dart';
import 'package:customer_app/network/services/sevicesService.dart';
import 'package:customer_app/store/use_app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class FunnelStep2Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? bookingSummery;
  const FunnelStep2Screen({super.key, required this.bookingSummery});

  @override
  ConsumerState<FunnelStep2Screen> createState() => _FunnelStep2ScreenState();
}

class _FunnelStep2ScreenState extends ConsumerState<FunnelStep2Screen> {
  double _swipeProgress = 0.0;
  bool _isBooked = false;

  String _getDateString(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> bookService() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final scheduleDate = widget.bookingSummery?['scheduleDate'];
      final String dateParam = scheduleDate is DateTime
          ? scheduleDate.toIso8601String()
          : (scheduleDate?.toString() ?? DateTime.now().toIso8601String());

      final res = await ref.read(servicesServiceProvider).bookService({
        "addresId": widget.bookingSummery?['addressId'],
        "date": dateParam,
        "serviceId": widget.bookingSummery?['service']?['id'],
        "timeSlot": widget.bookingSummery?['timeSlot'],
        "notes": widget.bookingSummery?['description'],
        if (widget.bookingSummery?['couponCode'] != null)
          "couponCode": widget.bookingSummery?['couponCode'],
      });

      if (res.statusCode == 201) {
        if (!mounted) return;

        // Refresh bookings in background
        try {
          final bookingsRes =
              await ref.read(servicesServiceProvider).getAllBookings();
          if (bookingsRes.statusCode == 200 &&
              bookingsRes.data is Map<String, dynamic>) {
            final list = bookingsRes.data['bookings'] as List?;
            if (list != null) {
              ref
                  .read(customerBookingsProvider.notifier)
                  .setBookings(List<Map<String, dynamic>>.from(list));
            }
          }
        } catch (_) {}

        messenger.showSnackBar(
          const SnackBar(
            content: Text('🎉 Booking Dispatched Successfully!'),
            backgroundColor: BrandColors.accent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            context.go('/bookings');
          }
        });
      }
    } on DioException catch (dioErr) {
      final String errMessage = (dioErr.response?.data is Map &&
              dioErr.response?.data['message'] != null)
          ? dioErr.response!.data['message'].toString()
          : 'Failed to dispatch booking. Please try again.';

      messenger.showSnackBar(
        SnackBar(
          content: Text(errMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        setState(() {
          _isBooked = false;
          _swipeProgress = 0.0;
        });
      }
    } catch (err) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $err'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        setState(() {
          _isBooked = false;
          _swipeProgress = 0.0;
        });
      }
    }
  }

  void _onSwipeComplete() {
    if (_isBooked) return;
    setState(() {
      _isBooked = true;
    });

    bookService();
  }

  String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerAddresses = ref.watch(customerAddressProvider) ?? [];
    final targetAddressId = widget.bookingSummery?['addressId']?.toString();

    final selectedAddress = customerAddresses.firstWhere(
      (a) => a['id'].toString() == targetAddressId,
      orElse: () => customerAddresses.isNotEmpty ? customerAddresses.first : <String, dynamic>{},
    );

    final addressHouse = selectedAddress['house_number']?.toString();
    final addressStreet = selectedAddress['street_no_or_name']?.toString();
    final addressCity = selectedAddress['city']?.toString();

    final addressDisplay = [
      if (addressHouse != null && addressHouse.isNotEmpty) addressHouse,
      if (addressStreet != null && addressStreet.isNotEmpty) addressStreet,
      if (addressCity != null && addressCity.isNotEmpty) addressCity,
    ].join(', ');

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '← Back',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'FUNNELS: MANIFEST',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Card 1: Professional details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _asString(
                                widget.bookingSummery?['service']?['image'],
                                'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=200&auto=format&fit=crop',
                              ),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  color: BrandColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.cleaning_services_outlined,
                                    size: 20,
                                    color: BrandColors.accent,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.bookingSummery?['service']?['name'],
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget
                                      .bookingSummery?['service']?['description'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Summary details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryRow(
                            'Target Date:',
                            _getDateString(
                              widget.bookingSummery?['scheduleDate'],
                            ),
                            theme,
                            valueColor: theme.textTheme.bodyLarge?.color,
                          ),
                          const SizedBox(height: 10),
                          _buildSummaryRow(
                            'Window Arrival:',
                            widget.bookingSummery?['timeSlot'],
                            theme,
                            valueColor: BrandColors.accent,
                          ),
                          const SizedBox(height: 10),
                          _buildSummaryRow(
                            'Address Target:',
                            addressDisplay.isNotEmpty ? addressDisplay : 'Address Selected',
                            theme,
                            valueColor: theme.textTheme.bodyLarge?.color,
                          ),
                          if (widget.bookingSummery?['description']
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SPECIAL REQUEST:',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: BrandColors.accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.bookingSummery?['description'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Transparent receipt details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Base Rate Quote:',
                            '₹ ${widget.bookingSummery?['service']?['basePrice']}',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Sanitization Materials Fee:',
                            '₹ 5.00',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Ecosystem Regulatory Taxes:',
                            '₹ 2.40',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Price Aggregation:',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                '₹ 56.40',
                                style: TextStyle(
                                  color: BrandColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Swipe to Confirm Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double sliderWidth = 52.0;
                final double maxSlideDistance = width - sliderWidth - 8.0;

                return Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background Track Text
                      Center(
                        child: Text(
                          _isBooked
                              ? 'BOOKING DISPATCHED'
                              : 'SWIPE TO CONFIRM BOOKING',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: BrandColors.accent,
                          ),
                        ),
                      ),
                      // Swipe Handle
                      AnimatedPositioned(
                        duration: _swipeProgress == 0.0 || _swipeProgress == 1.0
                            ? const Duration(milliseconds: 200)
                            : Duration.zero,
                        left: _swipeProgress * maxSlideDistance,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            if (_isBooked) return;
                            setState(() {
                              _swipeProgress +=
                                  details.primaryDelta! / maxSlideDistance;
                              if (_swipeProgress < 0.0) _swipeProgress = 0.0;
                              if (_swipeProgress > 1.0) _swipeProgress = 1.0;
                            });
                          },
                          onHorizontalDragEnd: (details) {
                            if (_isBooked) return;
                            if (_swipeProgress >= 0.9) {
                              setState(() {
                                _swipeProgress = 1.0;
                              });
                              _onSwipeComplete();
                            } else {
                              setState(() {
                                _swipeProgress = 0.0;
                              });
                            }
                          },
                          child: Container(
                            width: sliderWidth,
                            height: 52,
                            decoration: BoxDecoration(
                              color: BrandColors.accent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.accent.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '➔',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
