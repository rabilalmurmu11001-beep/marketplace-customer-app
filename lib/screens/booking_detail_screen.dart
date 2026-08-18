import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/sevicesService.dart';
import '../theme/brand_theme.dart';
import '../widgets/map_tracking_mock.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? booking;
  final String? bookingId;

  const BookingDetailScreen({
    super.key,
    this.booking,
    this.bookingId,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _bookingData = widget.booking;
    } else if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchBookingDetail(widget.bookingId!);
      });
    }
  }

  Future<void> _fetchBookingDetail(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ref.read(servicesServiceProvider).getBookingDetail(id);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data['booking'];
        if (data is Map<String, dynamic>) {
          setState(() {
            _bookingData = data;
          });
        }
      }
    } on DioException catch (dioErr) {
      setState(() {
        _errorMessage =
            dioErr.response?.data?['message']?.toString() ??
            'Failed to fetch booking details.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading details: $e';
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
        return 'REQUEST DISPATCHED';
      case 'accepted':
        return 'TECHNICIAN ASSIGNED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'SERVICE COMPLETED';
      case 'cancelled':
        return 'BOOKING CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 0;
      case 'accepted':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _bookingData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: BrandColors.accent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_errorMessage != null && _bookingData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
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
                  'Failed to Load Details',
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
                if (widget.bookingId != null)
                  ElevatedButton(
                    onPressed: () => _fetchBookingDetail(widget.bookingId!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final booking =
        _bookingData?['booking'] as Map<String, dynamic>? ??
        _bookingData ??
        {};
    final service = _bookingData?['service'] as Map<String, dynamic>? ?? {};
    final address = _bookingData?['address'] as Map<String, dynamic>? ?? {};
    final provider = _bookingData?['provider'] as Map<String, dynamic>?;

    final status = booking['bookingStatus']?.toString() ?? 'requested';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final currentStep = _getStatusStepIndex(status);
    final isCancelled = status.toLowerCase() == 'cancelled';

    final bookingId = booking['id']?.toString() ?? '';
    final shortId = bookingId.length > 8
        ? bookingId.substring(0, 8).toUpperCase()
        : bookingId.toUpperCase();

    final serviceTitle = service['name']?.toString() ?? 'Service Booking';
    final serviceImage = service['image']?.toString() ?? '';
    final servicePrice = booking['totalAmount'] ?? service['basePrice'] ?? '0';

    final dateStr = _formatDate(booking['scheduledDate']);
    final timeSlot =
        booking['scheduledTime']?.toString() ?? 'Flexible Window';
    final notes = booking['notes']?.toString() ?? '';

    final house = address['house_number']?.toString();
    final street = address['street_no_or_name']?.toString();
    final city = address['city']?.toString() ?? '';
    final addressDisplay = [
      if (house != null && house.isNotEmpty) house,
      if (street != null && street.isNotEmpty) street,
      if (city.isNotEmpty) city,
    ].join(', ');

    final providerName = provider?['name']?.toString();
    final providerInitials = providerName != null && providerName.isNotEmpty
        ? providerName
              .trim()
              .split(' ')
              .map((s) => s.isNotEmpty ? s[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'PR';

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '← Roster',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'LIVE DISPATCH TRACKER',
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        children: [
          // Mock tracking map
          const MapTrackingMock(),
          const SizedBox(height: 20),

          // Booking Details Card
          Container(
            padding: const EdgeInsets.all(18),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
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
                        'MANIFEST #$shortId',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.6,
                          ),
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Service row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        serviceImage.isNotEmpty
                            ? serviceImage
                            : 'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=200&auto=format&fit=crop',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 46,
                          height: 46,
                          color: BrandColors.accent.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.home_repair_service_outlined,
                            size: 20,
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
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Total Price: ₹$servicePrice',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Date & Time
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: BrandColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: BrandColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        timeSlot,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Target Address
                if (addressDisplay.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: BrandColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addressDisplay,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Special instructions (notes)
                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: BrandColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Instructions:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notes,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Automated Dispatch Progression
          if (!isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BrandColors.accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.accent.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AUTOMATED DISPATCH PROGRESSION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStepItem(
                    title: 'Booking Request Dispatched',
                    subtitle: 'Order submitted to provider pipeline',
                    isCompleted: currentStep >= 0,
                    isActive: currentStep == 0,
                    theme: theme,
                  ),
                  _buildStepDivider(),
                  _buildStepItem(
                    title: 'Technician Assignment',
                    subtitle: providerName != null
                        ? 'Assigned to $providerName'
                        : 'Matching top-rated technician',
                    isCompleted: currentStep >= 1,
                    isActive: currentStep == 1,
                    theme: theme,
                  ),
                  _buildStepDivider(),
                  _buildStepItem(
                    title: 'Job Operations In Progress',
                    subtitle: 'Service execution at your location',
                    isCompleted: currentStep >= 2,
                    isActive: currentStep == 2,
                    theme: theme,
                  ),
                  _buildStepDivider(),
                  _buildStepItem(
                    title: 'Fulfillment & Settlement',
                    subtitle: 'Work verified and completed',
                    isCompleted: currentStep >= 3,
                    isActive: currentStep == 3,
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Technician assigned details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: BrandColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      providerInitials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: BrandColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName ?? 'Assigned Technician Pending',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider != null
                            ? 'Verified Certified Expert'
                            : 'Dispatch matrix assigning professional',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider != null) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => context.push('/chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required ThemeData theme,
  }) {
    final activeColor = isActive
        ? BrandColors.accent
        : (isCompleted ? BrandColors.accent : Colors.grey);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? activeColor : Colors.transparent,
            border: Border.all(color: activeColor, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : (isActive
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor,
                          ),
                        ),
                      )
                    : null),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive || isCompleted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCompleted
                      ? theme.textTheme.bodyLarge?.color
                      : (isActive
                            ? BrandColors.accent
                            : theme.textTheme.bodyMedium?.color),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
      height: 18,
      width: 2,
      color: BrandColors.accent.withValues(alpha: 0.2),
    );
  }
}
