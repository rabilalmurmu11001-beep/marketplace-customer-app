import 'package:flutter/material.dart';
import '../theme/brand_theme.dart';

class MapTrackingMock extends StatelessWidget {
  const MapTrackingMock({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Abstract Grid lines representing streets
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: GridPaper(
                  color: isDark ? Colors.white : Colors.black,
                  interval: 60,
                  subdivisions: 1,
                ),
              ),
            ),
            // Mock Route line
            Positioned(
              left: 40,
              top: 90,
              child: Container(
                width: 160,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BrandColors.accent, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 196,
              top: 90,
              child: Container(
                width: 4,
                height: 40,
                color: Colors.blue,
              ),
            ),
            // Destination Marker (Customer Address)
            Positioned(
              left: 186,
              top: 120,
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // En-route Technician Marker
            Positioned(
              left: 90,
              top: 78,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: BrandColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bike,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            // Live Status Tag
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE TRACKING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
