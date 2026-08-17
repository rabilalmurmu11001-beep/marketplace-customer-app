import 'package:flutter/material.dart';

class PromoBannerCard extends StatelessWidget {
  final Map<String, dynamic>? coupon;
  const PromoBannerCard({super.key, this.coupon});

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      String hex = hexString.replaceFirst('#', '').trim();
      if (hex.length == 3) {
        // Expand shorthand (e.g. "FFF" -> "FFFFFF")
        hex = hex.split('').map((c) => c + c).join();
      }
      if (hex.length == 6) {
        buffer.write('ff'); // Default alpha
        buffer.write(hex);
      } else if (hex.length == 8) {
        // If it already has alpha channel, check ordering
        buffer.write(hex);
      } else {
        return const Color(0xFF0F766E); // Fallback color
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF0F766E); // Fallback color
    }
  }

  @override
  Widget build(BuildContext context) {

    final title = coupon?['title'] ?? '30% OFF Home Cleaning';
    final subtitle = coupon?['subtitle'] ?? 'Book today and save more.';
    final imageUrl = coupon?['banner'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=600&auto=format&fit=crop';
    final code = coupon?['code'];
    final bgColorStr = coupon?['backgroundColor'];

    DecorationImage? decorationImage;
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      decorationImage = DecorationImage(
        image: NetworkImage(imageUrl),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.62),
          BlendMode.darken,
        ),
      );
    }

    Color resolvedBgColor = Colors.transparent;
    if (decorationImage == null && bgColorStr != null) {
      resolvedBgColor = _parseHexColor(bgColorStr);
    } else if (decorationImage == null) {
      resolvedBgColor = const Color(0xFF0D9488);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: BorderRadius.circular(20),
        image: decorationImage,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SPECIAL OFFER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white70,
                ),
              ),
              if (code != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
