import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../network/services/addressServices.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAddresses();
    });
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ref.read(addressServiceProvider).getAllUserAddress();
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final addressData = response.data['address'];
        if (addressData is List) {
          ref
              .read(customerAddressProvider.notifier)
              .setCustomerAddress(List<Map<String, dynamic>>.from(addressData));
        } else {
          ref.read(customerAddressProvider.notifier).setCustomerAddress([]);
        }
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        // 404 indicates no address found for the current user
        ref.read(customerAddressProvider.notifier).setCustomerAddress([]);
      } else {
        setState(() {
          _errorMessage =
              dioErr.response?.data?['message']?.toString() ??
              'Failed to load addresses. Please check your network.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getAddressIcon(String? title) {
    final lower = (title ?? '').toLowerCase().trim();
    if (lower.contains('home')) {
      return Icons.home_outlined;
    } else if (lower.contains('office') || lower.contains('work')) {
      return Icons.business_outlined;
    } else if (lower.contains('apartment') || lower.contains('flat')) {
      return Icons.apartment_outlined;
    }
    return Icons.location_on_outlined;
  }

  void _showAddEditAddressSheet({Map<String, dynamic>? addressToEdit}) {
    final theme = Theme.of(context);
    final isEditing = addressToEdit != null;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: addressToEdit?['title']?.toString() ?? '',
    );
    final houseNumberController = TextEditingController(
      text: addressToEdit?['house_number']?.toString() ?? '',
    );
    final streetController = TextEditingController(
      text: addressToEdit?['street_no_or_name']?.toString() ?? '',
    );
    final cityController = TextEditingController(
      text: addressToEdit?['city']?.toString() ?? '',
    );
    final stateController = TextEditingController(
      text: addressToEdit?['state']?.toString() ?? '',
    );
    final pinCodeController = TextEditingController(
      text: addressToEdit?['pin_code']?.toString() ?? '',
    );
    final countryController = TextEditingController(
      text: addressToEdit?['country']?.toString() ?? '',
    );

    final titlePresets = ['Home', 'Office', 'Apartment', 'Other'];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(builderContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'EDIT ADDRESS' : 'ADD NEW ADDRESS',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BrandColors.accent,
                              letterSpacing: 1.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Tag presets
                      Text(
                        'ADDRESS LABEL',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: titlePresets.map((tag) {
                            final isSelected =
                                titleController.text.trim().toLowerCase() ==
                                tag.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: BrandColors.accent,
                                backgroundColor: theme.cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? BrandColors.accent
                                        : theme.dividerColor,
                                  ),
                                ),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      titleController.text = tag;
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title input
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _buildInputDecoration(
                          'Custom Label (e.g. Home, Warehouse)',
                          theme,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // House / Flat Number & Street in Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HOUSE / FLAT NO.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: houseNumberController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'e.g. Flat 4B',
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STREET / AREA',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: streetController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'e.g. 821 West End Dr',
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // City & State (Row)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CITY *',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: cityController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'e.g. New York',
                                    theme,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'City is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATE *',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: stateController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'e.g. NY',
                                    theme,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'State is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Pin Code & Country (Row)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PIN / POSTAL CODE *',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: pinCodeController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'e.g. 10025',
                                    theme,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'PIN code is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COUNTRY',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: countryController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'e.g. United States',
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setModalState(() {
                                    isSubmitting = true;
                                  });

                                  // Build payload strictly conforming to backend JSON schema
                                  final Map<String, dynamic> payload = {
                                    'city': cityController.text.trim(),
                                    'state': stateController.text.trim(),
                                    'pin_code': pinCodeController.text.trim(),
                                  };

                                  if (titleController.text.trim().isNotEmpty) {
                                    payload['title'] =
                                        titleController.text.trim();
                                  }
                                  if (houseNumberController.text
                                      .trim()
                                      .isNotEmpty) {
                                    payload['house_number'] =
                                        houseNumberController.text.trim();
                                  }
                                  if (streetController.text.trim().isNotEmpty) {
                                    payload['street_no_or_name'] =
                                        streetController.text.trim();
                                  }
                                  if (countryController.text
                                      .trim()
                                      .isNotEmpty) {
                                    payload['country'] =
                                        countryController.text.trim();
                                  }

                                  final messenger =
                                      ScaffoldMessenger.of(context);

                                  try {
                                    if (isEditing) {
                                      final id = addressToEdit['id'].toString();
                                      await ref
                                          .read(addressServiceProvider)
                                          .saveUpdatedAddress(payload, id);
                                    } else {
                                      await ref
                                          .read(addressServiceProvider)
                                          .saveNewAddress(payload);
                                    }

                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing
                                              ? 'Address updated successfully'
                                              : 'Address added successfully',
                                        ),
                                        backgroundColor: BrandColors.accent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    _fetchAddresses();
                                  } on DioException catch (dioErr) {
                                    final String errMessage =
                                        (dioErr.response?.data is Map &&
                                                dioErr.response?.data[
                                                      'message'
                                                    ] !=
                                                    null)
                                            ? dioErr
                                                .response!
                                                .data['message']
                                                .toString()
                                            : 'Failed to save address. Please try again.';

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(errMessage),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (err) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $err'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } finally {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: BrandColors.accent
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'Update Address'
                                      : 'Save Address Coordinates',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAddress(Map<String, dynamic> address) {
    final theme = Theme.of(context);
    final addressId = address['id']?.toString() ?? '';
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Address?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove "${address['title'] ?? address['street_no_or_name'] ?? 'this address'}" from your saved locations?',
            style: const TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref
                      .read(addressServiceProvider)
                      .deleteAddress(addressId);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Address deleted successfully'),
                      backgroundColor: BrandColors.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _fetchAddresses();
                } on DioException catch (dioErr) {
                  final String errMessage =
                      (dioErr.response?.data is Map &&
                              dioErr.response?.data['message'] != null)
                          ? dioErr.response!.data['message'].toString()
                          : 'Failed to delete address.';
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(errMessage),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $err'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String hint, ThemeData theme) {
    return InputDecoration(
      filled: true,
      fillColor: theme.cardColor,
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = ref.watch(customerAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading && addresses == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: BrandColors.accent,
                strokeWidth: 2.5,
              ),
            );
          }

          if (_errorMessage != null && addresses == null) {
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
                      'Failed to Load Addresses',
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
                      onPressed: _fetchAddresses,
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

          final addressList = addresses ?? [];

          if (addressList.isEmpty) {
            return RefreshIndicator(
              onRefresh: _fetchAddresses,
              color: BrandColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
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
                              child: const Icon(
                                Icons.location_off_outlined,
                                size: 48,
                                color: BrandColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Saved Addresses Found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your location coordinates to streamline service scheduling and booking manifests.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditAddressSheet(),
                              icon: const Icon(
                                Icons.add_location_alt_outlined,
                                size: 18,
                              ),
                              label: const Text('Add Address'),
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
            onRefresh: _fetchAddresses,
            color: BrandColors.accent,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(20.0),
              itemCount: addressList.length,
              itemBuilder: (context, index) {
                final addr = addressList[index];
                final title = addr['title']?.toString() ?? 'Address';
                final houseNumber = addr['house_number']?.toString();
                final street = addr['street_no_or_name']?.toString();
                final city = addr['city']?.toString() ?? '';
                final state = addr['state']?.toString() ?? '';
                final pinCode = addr['pin_code']?.toString() ?? '';
                final country = addr['country']?.toString();

                final streetLine = [
                  if (houseNumber != null && houseNumber.isNotEmpty)
                    houseNumber,
                  if (street != null && street.isNotEmpty) street,
                ].join(', ');

                final cityStateLine = [
                  if (city.isNotEmpty) city,
                  if (state.isNotEmpty) state,
                  if (pinCode.isNotEmpty) pinCode,
                ].join(', ');

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: BrandColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getAddressIcon(title),
                          size: 20,
                          color: BrandColors.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandColors.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    title.toUpperCase(),
                                    style: const TextStyle(
                                      color: BrandColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (streetLine.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                streetLine,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              cityStateLine,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            if (country != null && country.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                country,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: BrandColors.accent,
                            ),
                            tooltip: 'Edit Address',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showAddEditAddressSheet(addressToEdit: addr);
                            },
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete Address',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _confirmDeleteAddress(addr);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditAddressSheet(),
        backgroundColor: BrandColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined, size: 18),
        label: const Text(
          'Add Address',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
