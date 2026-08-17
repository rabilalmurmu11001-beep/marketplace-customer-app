import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _aptController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDefaultTarget = false;

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _aptController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _showAddAddressSheet(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    _labelController.clear();
    _streetController.clear();
    _aptController.clear();
    _cityController.clear();
    _isDefaultTarget = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ADD NEW COORDINATES',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BrandColors.accent,
                              letterSpacing: 1.0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Label
                      Text(
                        'LOCATION LABEL',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _labelController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _buildInputDecoration('e.g. Vacation Home', theme),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Label is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Street
                      Text(
                        'STREET ADDRESS',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _streetController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _buildInputDecoration('e.g. 100 Broadway St', theme),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Street address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Apt & City (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'APT / SUITE',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _aptController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration('e.g. Apt 3C', theme),
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
                                  'CITY',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cityController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration('e.g. New York', theme),
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Default Switch
                      SwitchListTile(
                        value: _isDefaultTarget,
                        title: const Text(
                          'Set as Default Location Target',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        contentPadding: EdgeInsets.zero,
                        activeColor: BrandColors.accent,
                        onChanged: (val) {
                          setModalState(() {
                            _isDefaultTarget = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              appState.addAddress(
                                label: _labelController.text.trim(),
                                street: _streetController.text.trim(),
                                apt: _aptController.text.trim(),
                                city: _cityController.text.trim(),
                                isDefault: _isDefaultTarget,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coordinates added successfully.'),
                                  backgroundColor: BrandColors.accent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save Location Coords',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Coordinates',
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
      body: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          final appState = AppState();
          final addresses = appState.customerAddresses;

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off_outlined, size: 48, color: BrandColors.accent),
                    const SizedBox(height: 16),
                    Text(
                      'No saved coordinates found',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add location targets to streamline your booking manifest.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: addr.isDefault ? BrandColors.accent : theme.dividerColor,
                    width: addr.isDefault ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: BrandColors.accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                addr.label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (addr.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BrandColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: BrandColors.accent,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${addr.street}${addr.apt.isNotEmpty ? ', ${addr.apt}' : ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                          Text(
                            addr.city,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                          if (!addr.isDefault) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => appState.setDefaultAddress(addr.id),
                              child: const Text(
                                'Set as Default Target',
                                style: TextStyle(
                                  color: BrandColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: theme.cardColor,
                              title: const Text(
                                'Remove Coordinates?',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Are you sure you want to delete these location coordinates?',
                                style: TextStyle(fontSize: 12),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Keep',
                                    style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    appState.removeAddress(addr.id);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
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
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddAddressSheet(context, AppState()),
            backgroundColor: BrandColors.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add Coordinates',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
