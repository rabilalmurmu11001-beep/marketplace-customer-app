import 'package:customer_app/network/services/sevicesService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  Map<String, dynamic>? _serviceData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServiceDetail();
    });
  }

  @override
  void didUpdateWidget(ServiceDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceId != widget.serviceId) {
      _loadServiceDetail();
    }
  }

  Future<void> _loadServiceDetail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await ref
          .read(servicesServiceProvider)
          .getServiceDetail(widget.serviceId);

      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        setState(() {
          _serviceData = (data['service'] ?? data) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError || _serviceData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: BrandColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Service',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadServiceDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final service = _serviceData!;
    final imageUrl = _asString(
      service['image'],
      'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=800&auto=format&fit=crop',
    );
    final title = _asString(service['name'], 'Sofa Deep Chemical Wash');
    final badgeText = _asString(service['badgeText'], 'PREMIUM SANITIZATION');
    final description = _asString(service['description'], '');
    final price = _asString(service['basePrice'], '\$49.00');
    final List reviews = service['reviews'] ?? [];

    return Scaffold(
      body: Column(
        children: [
          // Hero Header Image & Details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Hero Container
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          color: theme.scaffoldBackgroundColor,
                          child: Stack(
                            children: [
                              // The Background Image
                              Positioned.fill(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF0F172A),
                                                BrandColors.primary,
                                                Color(0xFF0D9488),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color?
                                                    >(BrandColors.accent),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF0F172A),
                                            BrandColors.primary,
                                            Color(0xFF0D9488),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: Colors.white30,
                                          size: 48,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Gradient Overlay for Text Legibility
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.1),
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // Text details overlay
                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      badgeText.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white70,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Back Button
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '←',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Back',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? BrandColors.accent.withValues(alpha: 0.12)
                                : const Color(0xFFE6F4F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? BrandColors.accent.withValues(alpha: 0.2)
                                  : BrandColors.accent.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: isDark
                                    ? BrandColors.accent
                                    : const Color(0xFF0F766E),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Fully Bonded Identity Verification & Compliance Audits Confirmed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? BrandColors.accent
                                        : const Color(0xFF0F766E),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Operator Portfolio
                        const Text(
                          'SERVICE DESCRIPTION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Reviews Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AGGREGATED CUSTOMER REVIEWS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                '/reviews?service_id=${widget.serviceId}&service_title=${Uri.encodeComponent(title)}',
                                extra: {
                                  'serviceId': widget.serviceId,
                                  'serviceTitle': title,
                                },
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'See All',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: BrandColors.accent,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 9,
                                    color: BrandColors.accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ...reviews.map((data) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${data['user']['name']}',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                    ),
                                    Text(
                                      '★ ${data['ratings']}',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${data['note']}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pricing Footer Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GUARANTEED COST',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹ $price',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: BrandColors.accent,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        context.push('/funnel-step1', extra: _serviceData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: BrandColors.accent.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Configure Schedule',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
