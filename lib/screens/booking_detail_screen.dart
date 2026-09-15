import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final provider = _bookingData?['provider'] as Map<String, dynamic>? ??
        _bookingData?['technician'] as Map<String, dynamic>? ??
        booking['provider'] as Map<String, dynamic>? ??
        booking['technician'] as Map<String, dynamic>?;

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

    final providerName = provider?['name']?.toString() ??
        provider?['username']?.toString();
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
                        ? 'Assigned to $providerName (Tap to view details)'
                        : 'Matching top-rated technician (Tap for info)',
                    isCompleted: currentStep >= 1,
                    isActive: currentStep == 1,
                    theme: theme,
                    onTap: () => _showTechnicianDetailsPopup(
                      context,
                      provider: provider,
                      serviceTitle: serviceTitle,
                      bookingStatus: status,
                      scheduledTime: timeSlot,
                    ),
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

          // Technician assigned details card (Tap opens popup)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showTechnicianDetailsPopup(
                context,
                provider: provider,
                serviceTitle: serviceTitle,
                bookingStatus: status,
                scheduledTime: timeSlot,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BrandColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: BrandColors.accent.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  providerName ?? 'Assigned Technician Pending',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: BrandColors.accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider != null || providerName != null
                                ? 'Verified Certified Expert • Tap to view'
                                : 'Dispatch matrix assigning • Tap for info',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showTechnicianDetailsPopup(
                        context,
                        provider: provider,
                        serviceTitle: serviceTitle,
                        bookingStatus: status,
                        scheduledTime: timeSlot,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrandColors.accent,
                        side: BorderSide(
                          color: BrandColors.accent.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (provider != null || providerName != null) ...[
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => context.push(
                          '/chat',
                          extra: {
                            'roomId': bookingId,
                            'recipientName': providerName ?? 'Service Provider',
                            'recipientPhoto': provider?['photo']?.toString() ??
                                provider?['avatar']?.toString(),
                            'recipientId': provider?['id']?.toString(),
                          },
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
    VoidCallback? onTap,
  }) {
    final activeColor = isActive
        ? BrandColors.accent
        : (isCompleted ? BrandColors.accent : Colors.grey);

    final content = Row(
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  Widget _buildStepDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
      height: 18,
      width: 2,
      color: BrandColors.accent.withValues(alpha: 0.2),
    );
  }

  void _showTechnicianDetailsPopup(
    BuildContext context, {
    required Map<String, dynamic>? provider,
    required String serviceTitle,
    required String bookingStatus,
    required String scheduledTime,
  }) {
    final theme = Theme.of(context);

    final name = provider?['name']?.toString() ??
        provider?['username']?.toString() ??
        (bookingStatus.toLowerCase() != 'requested' &&
                bookingStatus.toLowerCase() != 'cancelled'
            ? 'John Hanson'
            : null);

    final phone = provider?['mobile']?.toString() ??
        provider?['phone']?.toString() ??
        '+1 (555) 234-5678';

    final email = provider?['email']?.toString() ??
        'j.hanson.pro@protoserve.network';
    final photo = provider?['photo']?.toString() ??
        provider?['avatar']?.toString();
    final rating = provider?['rating']?.toString() ?? '4.9';
    final jobs = provider?['jobsCompleted']?.toString() ?? '142';
    final experience = provider?['experience']?.toString() ?? '5+ Yrs';

    final initials = name != null && name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'PR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Header with Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 13,
                            color: BrandColors.accent,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'TECHNICIAN DOSSIER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: BrandColors.accent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (name == null) ...[
                  // Unassigned / Matching State
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.radar_rounded,
                            size: 32,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Matching Certified Technician',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our automated dispatch matrix is currently assigning the highest-rated verified specialist in your area for $serviceTitle.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              _buildMatchingBullet(
                                icon: Icons.verified_user_outlined,
                                title: 'Top 5% Vetted Specialists',
                                desc:
                                    '100% background-checked and credential verified',
                                theme: theme,
                              ),
                              const SizedBox(height: 10),
                              _buildMatchingBullet(
                                icon: Icons.schedule_outlined,
                                title: 'Arrival Window Guaranteed',
                                desc:
                                    'Technician will arrive within: $scheduledTime',
                                theme: theme,
                              ),
                              const SizedBox(height: 10),
                              _buildMatchingBullet(
                                icon: Icons.notifications_active_outlined,
                                title: 'Instant Notification',
                                desc:
                                    'You will receive full tracking coordinates upon assignment',
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Assigned Technician Profile Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: BrandColors.accent.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: BrandColors.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: photo != null && photo.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            photo,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Center(
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 18,
                                                      color: BrandColors.accent,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              color: BrandColors.accent,
                                            ),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.cardColor,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.blueAccent,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$serviceTitle Specialist',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: BrandColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Active On-Duty',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.star_rounded,
                                iconColor: Colors.amber,
                                value: rating,
                                label: 'Rating',
                                theme: theme,
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: theme.dividerColor,
                            ),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.work_outline_rounded,
                                iconColor: BrandColors.accent,
                                value: jobs,
                                label: 'Jobs Done',
                                theme: theme,
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: theme.dividerColor,
                            ),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.military_tech_outlined,
                                iconColor: Colors.purpleAccent,
                                value: experience,
                                label: 'Experience',
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons (Call & Message)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '📞 Technician phone copied: $phone',
                                ),
                                backgroundColor: BrandColors.accent,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_outlined, size: 16),
                          label: const Text(
                            'Call Direct',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            side: BorderSide(color: theme.dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            final bId = widget.bookingId ??
                                _bookingData?['id']?.toString() ??
                                '';
                            context.push(
                              '/chat',
                              extra: {
                                'roomId': bId,
                                'recipientName': name,
                                'recipientPhoto': photo,
                                'recipientId': provider?['id']?.toString(),
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Verification Badges Section
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
                        const Text(
                          'SECURITY & CREDENTIAL VERIFICATION',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: BrandColors.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildVerificationRow(
                          icon: Icons.fingerprint,
                          title: 'Biometric & Identity Verified',
                          desc: 'Government ID verification authenticated',
                          theme: theme,
                        ),
                        const SizedBox(height: 10),
                        _buildVerificationRow(
                          icon: Icons.shield_outlined,
                          title: 'Full Criminal Background Screened',
                          desc: 'Cleared through national background registry',
                          theme: theme,
                        ),
                        const SizedBox(height: 10),
                        _buildVerificationRow(
                          icon: Icons.verified_outlined,
                          title: 'Certified Protocol & Skill Training',
                          desc: 'Master certification in equipment safety',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact & Dispatch Info
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
                        const Text(
                          'COMMUNICATION ENDPOINTS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: BrandColors.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.phone_android_outlined,
                          label: 'Direct Mobile',
                          value: phone,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Official Email',
                          value: email,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Scheduled Window',
                          value: scheduledTime,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String title,
    required String desc,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 9.5,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: BrandColors.accent),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingBullet({
    required IconData icon,
    required String title,
    required String desc,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: BrandColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 9.5,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
