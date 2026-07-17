import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class FunnelStep1Screen extends StatelessWidget {
  const FunnelStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '← Cancel',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'FUNNELS: LOGISTICS',
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
      body: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          final appState = AppState();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address coordinates anchor selector
                      const Text(
                        'DELIVERY COORDINATES ANCHOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            const Text('📍', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: appState.chosenAddressId,
                                  isExpanded: true,
                                  dropdownColor: theme.cardColor,
                                  icon: Icon(Icons.arrow_drop_down, color: theme.textTheme.bodyMedium?.color),
                                  items: appState.customerAddresses.map((addr) {
                                    return DropdownMenuItem<int>(
                                      value: addr.id,
                                      child: Text(
                                        '${addr.label}: ${addr.street}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      appState.selectAddress(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select from your configured ledger repositories above.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Calendar Date Target
                      const Text(
                        'CALENDAR DATE TARGET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(3, (i) {
                          final days = ['Sun 24', 'Mon 25', 'Tue 26'];
                          final dayStr = days[i];
                          final parts = dayStr.split(' ');
                          final isSelected = appState.chosenDateIndex == i;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => appState.selectDate(i),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: i == 2 ? 0 : 10,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? BrandColors.accent : theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? BrandColors.accent : theme.dividerColor,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: BrandColors.accent.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      parts[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      parts[1],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Time Slot Allocation Matrix
                      const Text(
                        'TIME SLOT ALLOCATION MATRIX',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: ['09:00 AM', '12:00 PM', '02:00 PM', '05:00 PM'].map((time) {
                          final isSelected = appState.chosenTimeSlot == time;

                          return GestureDetector(
                            onTap: () => appState.selectTimeSlot(time),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? BrandColors.accent : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? BrandColors.accent : theme.dividerColor,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: BrandColors.accent.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                               ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.push('/funnel-step2'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: BrandColors.accent.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Review Manifest Order',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
