import 'package:customer_app/store/use_app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class FunnelStep1Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? service;
  const FunnelStep1Screen({super.key, required this.service});

  @override
  ConsumerState<FunnelStep1Screen> createState() => _FunnelStep1ScreenState();
}

class _FunnelStep1ScreenState extends ConsumerState<FunnelStep1Screen> {
  late TextEditingController _descriptionController;
  late DateTime scheduleDate = DateTime.now();
  late String chosenAddressId = '';
  late String chosenTimeSlot = '';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  void handleViewBookingSummery() {
    context.push(
      '/funnel-step2',
      extra: {
        'service': widget.service,
        'addressId': chosenAddressId,
        'scheduleDate': scheduleDate,
        'timeSlot': chosenTimeSlot,
        'description': _descriptionController.text,
      },
    );
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
          'SCHEDULE: SERVICE',
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
      body: Builder(
        builder: (context) {
          final customerAddresses = ref.watch(customerAddressProvider) ?? [];

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
                        'SERVICE COORDINATES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                                child: DropdownButton<String>(
                                  value: chosenAddressId,
                                  isExpanded: true,
                                  dropdownColor: theme.cardColor,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                  items: customerAddresses.map((addr) {
                                    return DropdownMenuItem<String>(
                                      value: addr['id'],
                                      child: Text(
                                        '${addr['house_number']}, ${addr['street_no_or_name']}, ${addr['city']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        chosenAddressId = val;
                                      });
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
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(
                              primary: BrandColors.accent,
                              onPrimary: Colors.white,
                              surface: theme.cardColor,
                              onSurface: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: scheduleDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                            onDateChanged: (picked) {
                              setState(() {
                                scheduleDate = picked;
                              });
                            },
                          ),
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
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 2.2,
                                  ),
                              itemCount: group.value.length,
                              itemBuilder: (context, index) {
                                final time = group.value[index];
                                final isSelected = chosenTimeSlot == time;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    chosenTimeSlot = time;
                                  }),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? BrandColors.accent
                                          : theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? BrandColors.accent
                                            : theme.dividerColor,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: BrandColors.accent
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : theme.textTheme.bodyLarge?.color,
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
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.cardColor,
                          hintText:
                              'Describe details, specific instructions, or what you want done...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: BrandColors.accent,
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: handleViewBookingSummery,
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
                        'Review Booking Details',
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
