import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/sevicesService.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  int _activeTab = 0; // 0: Active, 1: History / Settled
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookings();
    });
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref.read(servicesServiceProvider).getAllBookings();
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final bookingsData = response.data['bookings'];
        if (bookingsData is List) {
          ref
              .read(customerBookingsProvider.notifier)
              .setBookings(List<Map<String, dynamic>>.from(bookingsData));
        } else {
          ref.read(customerBookingsProvider.notifier).setBookings([]);
        }
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        ref.read(customerBookingsProvider.notifier).setBookings([]);
      } else {
        setState(() {
          _errorMessage =
              dioErr.response?.data?['message']?.toString() ??
              'Failed to load bookings. Please check your network connection.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while fetching bookings: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Date TBD';
    try {
      final dt =
          rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString());
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
    } catch (_) {
      return rawDate.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return Colors.orangeAccent;
      case 'accepted':
        return BrandColors.accent;
      case 'in_progress':
        return Colors.blueAccent;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return BrandColors.accent;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'REQUESTED';
      case 'accepted':
        return 'CONFIRMED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  bool _isActiveBooking(String status) {
    final s = status.toLowerCase();
    return s == 'requested' || s == 'accepted' || s == 'in_progress';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allBookings = ref.watch(customerBookingsProvider);

    final activeBookings = (allBookings ?? []).where((item) {
      final status =
          item['booking']?['bookingStatus']?.toString() ?? 'requested';
      return _isActiveBooking(status);
    }).toList();

    final settledBookings = (allBookings ?? []).where((item) {
      final status = item['booking']?['bookingStatus']?.toString() ?? '';
      return !_isActiveBooking(status);
    }).toList();

    final displayedList = _activeTab == 0 ? activeBookings : settledBookings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Pipeline',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 0
                              ? (isDark
                                    ? BrandColors.accent.withValues(alpha: 0.15)
                                    : const Color(0xFFE6F4F2))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: _activeTab == 0
                              ? Border.all(
                                  color: BrandColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          allBookings != null
                              ? 'Active (${activeBookings.length})'
                              : 'Active Logs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 0
                                ? BrandColors.accent
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 1
                              ? (isDark
                                    ? BrandColors.accent.withValues(alpha: 0.15)
                                    : const Color(0xFFE6F4F2))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: _activeTab == 1
                              ? Border.all(
                                  color: BrandColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          allBookings != null
                              ? 'History (${settledBookings.length})'
                              : 'Settled Logs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 1
                                ? BrandColors.accent
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading && allBookings == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: BrandColors.accent,
                strokeWidth: 2.5,
              ),
            );
          }

          if (_errorMessage != null && allBookings == null) {
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
                      'Failed to Load Bookings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchBookings,
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

          if (displayedList.isEmpty) {
            final isZeroActive = _activeTab == 0;
            return RefreshIndicator(
              onRefresh: _fetchBookings,
              color: BrandColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
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
                              child: Icon(
                                isZeroActive
                                    ? Icons.calendar_month_outlined
                                    : Icons.history_toggle_off,
                                size: 48,
                                color: BrandColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              isZeroActive
                                  ? 'No Active Bookings'
                                  : 'No Booking History Yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isZeroActive
                                  ? 'Schedule top-tier home services with verified professionals.'
                                  : 'Completed and settled service bookings will appear here.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.go('/home'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BrandColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Explore Services'),
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
            onRefresh: _fetchBookings,
            color: BrandColors.accent,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(20),
              itemCount: displayedList.length,
              itemBuilder: (context, index) {
                final item = displayedList[index];
                final booking =
                    item['booking'] as Map<String, dynamic>? ?? {};
                final service =
                    item['service'] as Map<String, dynamic>? ?? {};
                final address =
                    item['address'] as Map<String, dynamic>? ?? {};
                final provider =
                    item['provider'] as Map<String, dynamic>? ?? {};

                final status =
                    booking['bookingStatus']?.toString() ?? 'requested';
                final statusColor = _getStatusColor(status);
                final statusLabel = _getStatusLabel(status);

                final bookingId = booking['id']?.toString() ?? '';
                final shortId = bookingId.length > 8
                    ? bookingId.substring(0, 8).toUpperCase()
                    : bookingId.toUpperCase();

                final serviceTitle =
                    service['name']?.toString() ?? 'Service Booking';
                final serviceImage = service['image']?.toString() ?? '';
                final price = booking['totalAmount'] ?? service['basePrice'];
                final dateStr = _formatDate(booking['scheduledDate']);
                final timeSlot =
                    booking['scheduledTime']?.toString() ?? 'Flexible Window';

                final house = address['house_number']?.toString();
                final street = address['street_no_or_name']?.toString();
                final city = address['city']?.toString() ?? '';
                final addressText = [
                  if (house != null && house.isNotEmpty) house,
                  if (street != null && street.isNotEmpty) street,
                  if (city.isNotEmpty) city,
                ].join(', ');

                final providerName = provider['name']?.toString();

                return GestureDetector(
                  onTap: () => context.push('/booking-detail', extra: item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with status badge & ID
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (shortId.isNotEmpty)
                              Text(
                                'REF: #$shortId',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Service info row
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                serviceImage.isNotEmpty
                                    ? serviceImage
                                    : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=200&auto=format&fit=crop',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 48,
                                      height: 48,
                                      color: BrandColors.accent.withValues(
                                        alpha: 0.1,
                                      ),
                                      child: const Icon(
                                        Icons.home_repair_service_outlined,
                                        size: 22,
                                        color: BrandColors.accent,
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serviceTitle,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  if (providerName != null &&
                                      providerName.isNotEmpty)
                                    Text(
                                      'Technician: $providerName',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    )
                                  else
                                    Text(
                                      'Matching verified professional...',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 11,
                                            color: BrandColors.accent,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            if (price != null)
                              Text(
                                '₹$price',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: BrandColors.accent,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Date, Time & Address preview
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: BrandColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time_outlined,
                              size: 13,
                              color: BrandColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                timeSlot,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text(
                              'Details ›',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.accent,
                              ),
                            ),
                          ],
                        ),

                        if (addressText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: BrandColors.accent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  addressText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 10.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
