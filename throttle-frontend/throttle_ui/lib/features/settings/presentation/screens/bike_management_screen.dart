import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/bikes/data/models/bike_catalog_item.dart';
import 'package:throttle_ui/features/bikes/data/services/bike_registry_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/features/settings/presentation/screens/subscription_screen.dart';

class BikeManagementScreen extends StatefulWidget {
  const BikeManagementScreen({super.key});

  @override
  State<BikeManagementScreen> createState() => _BikeManagementScreenState();
}

class _BikeManagementScreenState extends State<BikeManagementScreen> {
  static const _bikeTypes = [
    'Motorcycle',
    'Electric Scooter',
    'Scooter',
    'Tourer',
    'Custom Build',
  ];
  static const _bikeCategories = ['Cruiser', 'Sport', 'Commuter', 'ADV'];

  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _bikeActionLoading = false;

  List<Map<String, dynamic>> get _bikes =>
      _userData != null && _userData!['bikes'] != null
      ? List<Map<String, dynamic>>.from(_userData!['bikes'])
      : [];

  bool get _subscriptionActive =>
      (_userData?['subscriptionActive'] ?? false) == true;

  int get _bikeLimit =>
      int.tryParse((_userData?['bikeLimit'] ?? 3).toString()) ?? 3;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _loading = true);
    final freshUser = await UserService.getMe();
    if (!mounted) return;
    setState(() {
      _userData = freshUser;
      _loading = false;
    });
  }

  void _openSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          onClose: () => Navigator.pop(context),
          title: 'Need More Bike Slots?',
          description:
              'Free riders can keep up to 3 bikes. Upgrade to Premium for more bike slots, or remove an existing bike to add another one.',
        ),
      ),
    );
  }

  Future<void> _showBikeLimitDialog() async {
    final theme = ThemeController.instance.theme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Bike limit reached',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          'You can keep up to $_bikeLimit bikes on the free plan. Remove an existing bike or upgrade your subscription to add more.',
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openSubscriptionScreen();
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  String _bikeTitle(Map<String, dynamic> bike) {
    final year = bike['year']?.toString() ?? '';
    final brand = (bike['brand'] ?? bike['make'] ?? bike['title'] ?? '')
        .toString();
    final model = (bike['model'] ?? '').toString();
    final variant = (bike['variant'] ?? '').toString();
    return [year, brand, model, variant]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
  }

  String _bikeSubtitle(Map<String, dynamic> bike) {
    final category = (bike['category'] ?? '').toString();
    final type = (bike['bikeType'] ?? bike['type'] ?? '').toString();
    final engineCc = bike['engineCc']?.toString();
    return [
      if (category.isNotEmpty) category,
      if (type.isNotEmpty) type,
      if (engineCc != null && engineCc.isNotEmpty) '${engineCc}cc',
    ].join(' • ');
  }

  Future<void> _removeBike(Map<String, dynamic> bike) async {
    final bikeId = int.tryParse((bike['id'] ?? '').toString());
    if (bikeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove this bike')),
      );
      return;
    }

    setState(() => _bikeActionLoading = true);
    final result = await UserService.deleteBike(bikeId);
    if (!mounted) return;
    setState(() => _bikeActionLoading = false);

    if (result['success'] == true) {
      await _refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Bike removed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Failed to remove bike',
          ),
        ),
      );
    }
  }

  Future<String?> _pickStringOption({
    required String title,
    required Future<List<String>> Function(String query) loader,
  }) async {
    final searchController = TextEditingController();
    List<String> filteredOptions = const [];
    bool isLoading = true;
    bool didInitialLoad = false;
    int requestId = 0;

    Future<void> loadOptions(
      StateSetter setSheetState, {
      String query = '',
    }) async {
      final currentRequestId = ++requestId;
      setSheetState(() => isLoading = true);
      final results = await loader(query);
      if (!mounted || currentRequestId != requestId) return;
      setSheetState(() {
        filteredOptions = results;
        isLoading = false;
      });
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeController.instance.theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!didInitialLoad) {
              didInitialLoad = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                loadOptions(setSheetState);
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        color: ThemeController.instance.theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        loadOptions(setSheetState, query: value);
                      },
                      decoration: const InputDecoration(hintText: 'Search'),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredOptions.isEmpty
                          ? const Center(child: Text('No matches found'))
                          : ListView.builder(
                              itemCount: filteredOptions.length,
                              itemBuilder: (context, index) {
                                final option = filteredOptions[index];
                                return ListTile(
                                  title: Text(option),
                                  onTap: () => Navigator.pop(context, option),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return result;
  }

  Future<BikeCatalogItem?> _pickVariantOption(
    String brand,
    String model,
  ) async {
    final searchController = TextEditingController();
    List<BikeCatalogItem> filteredVariants = const [];
    bool isLoading = true;
    bool didInitialLoad = false;
    int requestId = 0;

    Future<void> loadVariants(
      StateSetter setSheetState, {
      String query = '',
    }) async {
      final currentRequestId = ++requestId;
      setSheetState(() => isLoading = true);
      final results = await BikeRegistryService.fetchVariants(
        brand,
        model,
        query,
      );
      if (!mounted || currentRequestId != requestId) return;
      setSheetState(() {
        filteredVariants = results;
        isLoading = false;
      });
    }

    final result = await showModalBottomSheet<BikeCatalogItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeController.instance.theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!didInitialLoad) {
              didInitialLoad = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                loadVariants(setSheetState);
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Variant',
                      style: GoogleFonts.lexend(
                        color: ThemeController.instance.theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        loadVariants(setSheetState, query: value);
                      },
                      decoration: const InputDecoration(hintText: 'Search'),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredVariants.isEmpty
                          ? const Center(child: Text('No variants found'))
                          : ListView.builder(
                              itemCount: filteredVariants.length,
                              itemBuilder: (context, index) {
                                final item = filteredVariants[index];
                                final subtitle = [
                                  if (item.category.isNotEmpty) item.category,
                                  if (item.bikeType.isNotEmpty) item.bikeType,
                                  if (item.engineCc != null)
                                    '${item.engineCc}cc',
                                ].join(' • ');
                                return ListTile(
                                  title: Text(item.label),
                                  subtitle: subtitle.isEmpty
                                      ? null
                                      : Text(subtitle),
                                  onTap: () => Navigator.pop(context, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    return result;
  }

  Widget _selectorTile(String label, String value, VoidCallback onTap) {
    final theme = ThemeController.instance.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x52B8C6DA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? 'Select $label' : value,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textPrimary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBikeSheet() async {
    if (!_subscriptionActive && _bikes.length >= _bikeLimit) {
      await _showBikeLimitDialog();
      return;
    }

    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final variantController = TextEditingController();
    final yearController = TextEditingController();
    final engineController = TextEditingController();
    String selectedBrand = '';
    String selectedModel = '';
    BikeCatalogItem? selectedVariant;
    bool useCustomBike = false;
    String customBikeCategory = '';
    String customBikeType = '';
    bool setAsPrimary = _bikes.isEmpty;
    String? modalError;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeController.instance.theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = ThemeController.instance.theme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            void setModalError(String? message) {
              setModalState(() => modalError = message);
            }

            Future<void> saveBike() async {
              final brand = brandController.text.trim();
              final model = modelController.text.trim();
              final variant = variantController.text.trim();
              final year = int.tryParse(yearController.text.trim());
              final engineCc = int.tryParse(engineController.text.trim());

              final invalidCatalog =
                  !useCustomBike &&
                  (selectedVariant == null ||
                      year == null ||
                      year < 1950 ||
                      year > 2100);
              final invalidCustom =
                  useCustomBike &&
                  (customBikeCategory.isEmpty ||
                      customBikeType.isEmpty ||
                      brand.isEmpty ||
                      model.isEmpty ||
                      variant.isEmpty ||
                      year == null ||
                      year < 1950 ||
                      year > 2100 ||
                      engineCc == null ||
                      engineCc < 50 ||
                      engineCc > 5000);

              if (invalidCatalog || invalidCustom) {
                setModalError(
                  invalidCatalog
                      ? 'Select brand, model, variant, and a valid year'
                      : 'Fill all custom bike details with valid values',
                );
                return;
              }

              setModalError(null);
              setState(() => _bikeActionLoading = true);
              final result = await UserService.addBike({
                'bikeMasterId': useCustomBike ? null : selectedVariant?.id,
                'brand': useCustomBike ? brand : selectedVariant?.brand,
                'model': useCustomBike ? model : selectedVariant?.model,
                'variant': useCustomBike ? variant : selectedVariant?.variant,
                'year': year,
                'category': useCustomBike
                    ? customBikeCategory.toLowerCase()
                    : selectedVariant?.category,
                'bikeType': useCustomBike
                    ? customBikeType
                    : selectedVariant?.bikeType,
                'engineCc': useCustomBike
                    ? engineCc
                    : selectedVariant?.engineCc,
                'primary': setAsPrimary,
              });
              if (!mounted) return;
              setState(() => _bikeActionLoading = false);

              if (result['success'] == true) {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
                await _refreshProfile();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Bike added')),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message']?.toString() ?? 'Failed to add bike',
                    ),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Bike',
                      style: GoogleFonts.lexend(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bike ${_bikes.length + 1}${_subscriptionActive ? '' : ' of $_bikeLimit on free plan'}',
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!useCustomBike) ...[
                      _selectorTile('Brand', selectedBrand, () async {
                        final brand = await _pickStringOption(
                          title: 'Select Brand',
                          loader: BikeRegistryService.fetchBrands,
                        );
                        if (brand == null) return;
                        setModalState(() {
                          modalError = null;
                          selectedBrand = brand;
                          selectedModel = '';
                          selectedVariant = null;
                        });
                      }),
                      const SizedBox(height: 14),
                      _selectorTile('Model', selectedModel, () async {
                        if (selectedBrand.isEmpty) {
                          setModalError('Select brand first');
                          return;
                        }
                        final model = await _pickStringOption(
                          title: 'Select Model',
                          loader: (query) =>
                              BikeRegistryService.fetchModels(
                                selectedBrand,
                                query,
                              ),
                        );
                        if (model == null) return;
                        setModalState(() {
                          modalError = null;
                          selectedModel = model;
                          selectedVariant = null;
                        });
                      }),
                      const SizedBox(height: 14),
                      _selectorTile(
                        'Variant',
                        selectedVariant?.variant ?? '',
                        () async {
                          if (selectedBrand.isEmpty || selectedModel.isEmpty) {
                            setModalError('Select brand and model first');
                            return;
                          }
                          final variantItem = await _pickVariantOption(
                            selectedBrand,
                            selectedModel,
                          );
                          if (variantItem == null) {
                            setModalError(
                              'No variants found for the selected brand and model',
                            );
                            return;
                          }
                          setModalState(() {
                            modalError = null;
                            selectedVariant = variantItem;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            modalError = null;
                            useCustomBike = true;
                            selectedVariant = null;
                            selectedBrand = '';
                            selectedModel = '';
                          });
                        },
                        child: const Text(
                          "Can't find your bike? Add Custom Bike",
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: brandController,
                        decoration: const InputDecoration(
                          labelText: 'Bike Brand',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Bike Model',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: variantController,
                        decoration: const InputDecoration(
                          labelText: 'Bike Variant',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Category',
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bikeCategories.map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: customBikeCategory == category,
                            onSelected: (_) {
                              setModalState(() => customBikeCategory = category);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Bike Type',
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bikeTypes.map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: customBikeType == type,
                            onSelected: (_) {
                              setModalState(() => customBikeType = type);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Custom bikes are saved as unverified',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            modalError = null;
                            useCustomBike = false;
                            brandController.clear();
                            modelController.clear();
                            variantController.clear();
                            engineController.clear();
                            customBikeCategory = '';
                            customBikeType = '';
                          });
                        },
                        child: const Text('Use Bike Registry Instead'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                    if (useCustomBike) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: engineController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Engine CC',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: setAsPrimary,
                      onChanged: (value) {
                        setModalState(() => setAsPrimary = value);
                      },
                      title: const Text('Set as primary bike'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          modalError!,
                          style: TextStyle(color: theme.textPrimary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bikeActionLoading ? null : saveBike,
                        child: Text(
                          _bikeActionLoading ? 'Saving...' : 'Add Bike',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    brandController.dispose();
    modelController.dispose();
    variantController.dispose();
    yearController.dispose();
    engineController.dispose();

    if (added == true && mounted) {
      await _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textPrimary),
            title: Text(
              'My Bikes',
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _bikeActionLoading ? null : _showAddBikeSheet,
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Bike'),
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshProfile,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _subscriptionActive
                                    ? '${_bikes.length} bikes registered'
                                    : '${_bikes.length}/$_bikeLimit bikes on free plan',
                                style: GoogleFonts.lexend(
                                  color: theme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add bikes from the registry or create a custom entry. Swipe down any time to refresh your garage.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  height: 1.35,
                                ),
                              ),
                              if (!_subscriptionActive &&
                                  _bikes.length >= _bikeLimit) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _openSubscriptionScreen,
                                  child: const Text('Upgrade for more slots'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_bikes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0x52B8C6DA)),
                            ),
                            child: Text(
                              'No bikes registered yet. Use Add Bike to build your garage.',
                              style: TextStyle(
                                color: theme.textPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                          )
                        else
                          ..._bikes.map((bike) {
                            final title = _bikeTitle(bike);
                            final subtitle = _bikeSubtitle(bike);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0x52B8C6DA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.two_wheeler,
                                      color: theme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              title.isEmpty ? 'Bike' : title,
                                              style: TextStyle(
                                                color: theme.textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if ((bike['primary'] ?? false) ==
                                                true)
                                              _pill(
                                                theme,
                                                text: 'Primary',
                                                color: theme.primary,
                                              ),
                                            if ((bike['verified'] ?? false) !=
                                                true)
                                              _pill(
                                                theme,
                                                text: 'Unverified',
                                                color: Colors.orange,
                                              ),
                                          ],
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              color: theme.textPrimary
                                                  .withValues(alpha: 0.65),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _bikeActionLoading
                                        ? null
                                        : () => _removeBike(bike),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _pill(AppThemeConfig theme, {required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
