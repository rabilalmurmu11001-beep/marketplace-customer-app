import 'package:customer_app/store/use_app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../network/services/uploadService.dart';
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
  final List<String> _referenceImages = [];
  bool _isUploadingImage = false;

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

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final uploadService = ref.read(uploadServiceProvider);
      try {
        final result = await uploadService.uploadFile(
          file: photo,
          folder: 'bookings',
        );
        if (result.url.isNotEmpty) {
          setState(() {
            _referenceImages.add(result.url);
          });
        }
      } catch (e) {
        debugPrint('Failed to upload image: $e');
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo. Please try again.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void handleViewBookingSummery() {
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for photos to finish uploading.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final customerAddresses = ref.read(customerAddressProvider) ?? [];
    if (customerAddresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a delivery address first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      context.push('/addresses');
      return;
    }

    final effectiveAddressId = chosenAddressId.isNotEmpty
        ? chosenAddressId
        : customerAddresses.first['id'].toString();

    context.push(
      '/funnel-step2',
      extra: {
        'service': widget.service,
        'addressId': effectiveAddressId,
        'scheduleDate': scheduleDate,
        'timeSlot': chosenTimeSlot.isNotEmpty ? chosenTimeSlot : '02:00 PM',
        'description': _descriptionController.text,
        'referenceImages': _referenceImages,
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
          final validAddressIds =
              customerAddresses.map((a) => a['id'].toString()).toList();
          final effectiveAddressId = validAddressIds.contains(chosenAddressId)
              ? chosenAddressId
              : (validAddressIds.isNotEmpty ? validAddressIds.first : null);

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SERVICE COORDINATES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/addresses'),
                            child: const Text(
                              'Manage Addresses',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (customerAddresses.isEmpty)
                        GestureDetector(
                          onTap: () => context.push('/addresses'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: BrandColors.accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add_location_alt_outlined,
                                  size: 20,
                                  color: BrandColors.accent,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Add delivery address to continue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: BrandColors.accent,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: BrandColors.accent,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
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
                                    value: effectiveAddressId,
                                    isExpanded: true,
                                    dropdownColor: theme.cardColor,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    items: customerAddresses.map((addr) {
                                      final id = addr['id'].toString();
                                      final title = addr['title']?.toString();
                                      final house =
                                          addr['house_number']?.toString();
                                      final street =
                                          addr['street_no_or_name']?.toString();
                                      final city = addr['city']?.toString() ?? '';

                                      final addrText = [
                                        if (house != null && house.isNotEmpty)
                                          house,
                                        if (street != null && street.isNotEmpty)
                                          street,
                                        if (city.isNotEmpty) city,
                                      ].join(', ');

                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(
                                          title != null && title.isNotEmpty
                                              ? '[$title] $addrText'
                                              : addrText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                        'Select from your configured address coordinates.',
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
                      const SizedBox(height: 18),

                      // Reference Photos (Optional)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'REFERENCE PHOTOS (OPTIONAL)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (_referenceImages.isNotEmpty)
                            Text(
                              '${_referenceImages.length} attached',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.accent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Take photos of the problem or space to help your service provider prepare.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 96,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Take photo button
                            InkWell(
                              onTap: _isUploadingImage
                                  ? null
                                  : _takePhoto,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 90,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: BrandColors.accent
                                        .withValues(alpha: 0.4),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: BrandColors.accent
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 20,
                                        color: BrandColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Take Photo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: BrandColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Uploading indicator
                            if (_isUploadingImage) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 90,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          BrandColors.accent,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Uploading...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Attached Images
                            for (int i = 0; i < _referenceImages.length; i++) ...[
                              const SizedBox(width: 10),
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 90,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: theme.dividerColor
                                            .withValues(alpha: 0.2),
                                      ),
                                      child: Image.network(
                                        _referenceImages[i],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _referenceImages.removeAt(i);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
