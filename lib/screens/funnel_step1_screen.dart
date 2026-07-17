import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class FunnelStep1Screen extends StatefulWidget {
  const FunnelStep1Screen({super.key});

  @override
  State<FunnelStep1Screen> createState() => _FunnelStep1ScreenState();
}

class _FunnelStep1ScreenState extends State<FunnelStep1Screen> {
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: AppState().bookingDescription);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  IconData _getTimeSlotIcon(String groupName) {
    switch (groupName.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.sunny;
      case 'evening':
        return Icons.nights_stay_outlined;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, List<String>> timeSlotsGrouped = {
      'Morning': ['08:00 AM', '10:00 AM', '11:30 AM'],
      'Afternoon': ['01:00 PM', '02:30 PM', '04:00 PM'],
      'Evening': ['05:30 PM', '07:00 PM'],
    };

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
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: BrandColors.accent,
                            ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CALENDAR DATE TARGET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_outlined, size: 20, color: BrandColors.accent),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: appState.chosenDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.fromSeed(
                                        seedColor: BrandColors.accent,
                                        primary: BrandColors.accent,
                                        brightness: Theme.of(context).brightness,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                appState.selectDate(picked);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Horizontal scrollable calendar strip (Next 14 days)
                      SizedBox(
                        height: 64,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: 14,
                          itemBuilder: (context, index) {
                            final date = DateTime.now().add(Duration(days: index));
                            final isSelected = DateUtils.isSameDay(appState.chosenDate, date);
                            final weekday = _getWeekdayName(date.weekday).toUpperCase();
                            final day = date.day.toString();

                            return GestureDetector(
                              onTap: () => appState.selectDate(date),
                              child: Container(
                                width: 56,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? BrandColors.accent : theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? BrandColors.accent : theme.dividerColor,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: BrandColors.accent.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      weekday,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Time Slot Allocation Matrix
                      const Text(
                        'TIME SLOT ALLOCATION MATRIX',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Loop through time slot groups
                      ...timeSlotsGrouped.entries.map((group) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getTimeSlotIcon(group.key),
                                  size: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  group.key.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.2,
                              ),
                              itemCount: group.value.length,
                              itemBuilder: (context, index) {
                                final time = group.value[index];
                                final isSelected = appState.chosenTimeSlot == time;
                                return GestureDetector(
                                  onTap: () => appState.selectTimeSlot(time),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? BrandColors.accent : theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? BrandColors.accent : theme.dividerColor,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: BrandColors.accent.withValues(alpha: 0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                          ],
                        );
                      }),

                      const SizedBox(height: 10),

                      // Special Instructions / Description Input
                      const Text(
                        'ADDITIONAL SERVICE DESCRIPTION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (val) {
                          appState.updateBookingDescription(val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.cardColor,
                          hintText: 'Describe details, specific instructions, or what you want done...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: BrandColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        shadowColor: BrandColors.accent.withValues(alpha: 0.3),
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
