import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/features/bikes/data/models/bike_catalog_item.dart';
import 'package:throttle_ui/features/bikes/data/services/bike_registry_service.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/profile/presentation/screens/stats_screen.dart';
import 'package:throttle_ui/features/settings/presentation/screens/settings_screen.dart';
import 'package:throttle_ui/features/settings/presentation/screens/subscription_screen.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_summary_screen.dart';

import 'package:throttle_ui/core/utils/string_extensions.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _bikeActionLoading = false;

  static const _bikeTypes = [
    "Motorcycle",
    "Electric Scooter",
    "Scooter",
    "Tourer",
    "Custom Build",
  ];
  static const _bikeCategories = ["Cruiser", "Sport", "Commuter", "ADV"];

  List<Map<String, dynamic>> get rideHistory =>
      _userData != null && _userData!['recentRides'] != null
      ? List<Map<String, dynamic>>.from(_userData!['recentRides'])
      : [];

  List<Map<String, dynamic>> get achievements =>
      _userData != null && _userData!['achievements'] != null
      ? List<Map<String, dynamic>>.from(_userData!['achievements'])
      : [];

  List<Map<String, dynamic>> get bikes =>
      _userData != null && _userData!['bikes'] != null
      ? List<Map<String, dynamic>>.from(_userData!['bikes'])
      : [];

  bool get _subscriptionActive =>
      (_userData?['subscriptionActive'] ?? false) == true;

  int get _bikeLimit =>
      int.tryParse((_userData?['bikeLimit'] ?? 3).toString()) ?? 3;

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final raw = value?.toString().trim() ?? "";
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  double _rideDistanceKm(Map<String, dynamic> ride) {
    final distanceKm = _toDouble(
      ride['distanceKm'] ?? ride['km'] ?? ride['kilometers'],
    );
    if (distanceKm > 0) return distanceKm;

    final miles = _toDouble(
      ride['miles'] ?? ride['distanceMiles'] ?? ride['distance'],
    );
    if (miles > 0) return miles * 1.60934;

    return 0;
  }

  double get _totalDistanceKm {
    final fromHistory = rideHistory.fold<double>(
      0,
      (sum, ride) => sum + _rideDistanceKm(ride),
    );
    if (fromHistory > 0) return fromHistory;

    final fromUserKm = _toDouble(
      _userData?['totalKm'] ??
          _userData?['totalDistanceKm'] ??
          _userData?['distanceKm'],
    );
    if (fromUserKm > 0) return fromUserKm;

    final totalMiles = _toDouble(_userData?['totalMiles']);
    if (totalMiles > 0) return totalMiles * 1.60934;

    return 0;
  }

  int get _totalRidesTaken {
    final totalRides = _toInt(_userData?['totalRides']);
    if (totalRides > 0) return totalRides;
    return rideHistory.length;
  }

  String _formatKm(double value) {
    if (value == 0) return "0";
    if (value >= 100) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String _rideDateLabel(Map<String, dynamic> ride) =>
      (ride["date"] ?? ride["scheduledDate"] ?? "").toString();

  String _rideDurationLabel(Map<String, dynamic> ride) =>
      (ride["duration"] ?? ride["time"] ?? "").toString();

  Future<void> _openRideSummary(Map<String, dynamic> ride) async {
    final rideUuid = (ride["uuid"] ?? ride["id"])?.toString();
    final groupName = (ride["title"] ?? ride["name"] ?? "Ride").toString();
    final token = await AuthService.getToken();

    Map<String, dynamic>? session;
    if (rideUuid != null && rideUuid.isNotEmpty) {
      try {
        if (token != null && token.isNotEmpty) {
          session = await RideService.fetchRideSession(token, rideUuid);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSummaryScreen(
          groupName: groupName,
          ride: ride,
          session: session,
          token: token,
          rideUuid: rideUuid,
        ),
      ),
    );
    await _refreshProfile();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userData = widget.userData != null
        ? Map<String, dynamic>.from(widget.userData!)
        : {};
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    final freshUser = await UserService.getMe();
    if (!mounted || freshUser == null) return;
    setState(() {
      _userData = freshUser;
    });
  }

  void _openSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          onClose: () => Navigator.pop(context),
          title: "Need More Bike Slots?",
          description:
              "Free riders can keep up to 3 bikes. Upgrade to Premium for more bike slots, or remove an existing bike to add another one.",
        ),
      ),
    );
  }

  Future<void> _showBikeLimitDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeController.instance.theme.surface,
        title: Text(
          "Bike limit reached",
          style: TextStyle(color: ThemeController.instance.theme.textPrimary),
        ),
        content: Text(
          "You can keep up to $_bikeLimit bikes on the free plan. Remove an existing bike or upgrade your subscription to add more.",
          style: TextStyle(
            color: ThemeController.instance.theme.textPrimary.withValues(
              alpha: 0.7,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Manage Bikes"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openSubscriptionScreen();
            },
            child: const Text("View Plans"),
          ),
        ],
      ),
    );
  }

  String _bikeTitle(Map<String, dynamic> bike) {
    final year = bike['year']?.toString() ?? "";
    final brand = (bike['brand'] ?? bike['make'] ?? bike['title'] ?? '')
        .toString();
    final model = (bike['model'] ?? '').toString();
    final variant = (bike['variant'] ?? '').toString();
    return [
      year,
      brand,
      model,
      variant,
    ].where((part) => part.trim().isNotEmpty).join(" ");
  }

  String _bikeSubtitle(Map<String, dynamic> bike) {
    final category = (bike['category'] ?? '').toString();
    final type = (bike['bikeType'] ?? bike['type'] ?? '').toString();
    final engineCc = bike['engineCc']?.toString();
    return [
      if (category.isNotEmpty) category,
      if (type.isNotEmpty) type,
      if (engineCc != null && engineCc.isNotEmpty) "${engineCc}cc",
    ].join(" • ");
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
      String query = "",
    }) async {
      final currentRequestId = ++requestId;
      setSheetState(() {
        isLoading = true;
      });
      final results = await loader(query);
      if (!mounted || currentRequestId != requestId) {
        return;
      }
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
                      decoration: const InputDecoration(hintText: "Search"),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredOptions.isEmpty
                          ? const Center(child: Text("No matches found"))
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
      String query = "",
    }) async {
      final currentRequestId = ++requestId;
      setSheetState(() {
        isLoading = true;
      });
      final results = await BikeRegistryService.fetchVariants(
        brand,
        model,
        query,
      );
      if (!mounted || currentRequestId != requestId) {
        return;
      }
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
                      "Select Variant",
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
                      decoration: const InputDecoration(hintText: "Search"),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredVariants.isEmpty
                          ? const Center(child: Text("No variants found"))
                          : ListView.builder(
                              itemCount: filteredVariants.length,
                              itemBuilder: (context, index) {
                                final option = filteredVariants[index];
                                return ListTile(
                                  title: Text(option.variant),
                                  subtitle: Text(
                                    "${option.category} • ${option.bikeType}${option.engineCc != null ? " • ${option.engineCc}cc" : ""}",
                                  ),
                                  trailing: option.verified
                                      ? null
                                      : const Chip(label: Text("Unverified")),
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

  Widget _selectorTile(String label, String value, VoidCallback onTap) {
    final theme = ThemeController.instance.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
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
                      color: theme.textPrimary.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? "Select $label" : value,
                    style: TextStyle(
                      color: value.isEmpty
                          ? theme.textPrimary.withValues(alpha: 0.45)
                          : theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more, color: theme.textPrimary),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBikeSheet() async {
    if (!_subscriptionActive && bikes.length >= _bikeLimit) {
      await _showBikeLimitDialog();
      return;
    }

    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final variantController = TextEditingController();
    final yearController = TextEditingController();
    final engineController = TextEditingController();
    String selectedBrand = "";
    String selectedModel = "";
    BikeCatalogItem? selectedVariant;
    bool useCustomBike = false;
    String customBikeCategory = "";
    String customBikeType = "";
    bool setAsPrimary = bikes.isEmpty;
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
              setModalState(() {
                modalError = message;
              });
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
                      ? "Select brand, model, variant, and a valid year"
                      : "Fill all custom bike details with valid values",
                );
                return;
              }

              setModalError(null);
              setState(() => _bikeActionLoading = true);
              final result = await UserService.addBike({
                "bikeMasterId": useCustomBike ? null : selectedVariant?.id,
                "brand": useCustomBike ? brand : selectedVariant?.brand,
                "model": useCustomBike ? model : selectedVariant?.model,
                "variant": useCustomBike ? variant : selectedVariant?.variant,
                "year": year,
                "category": useCustomBike
                    ? customBikeCategory.toLowerCase()
                    : selectedVariant?.category,
                "bikeType": useCustomBike
                    ? customBikeType
                    : selectedVariant?.bikeType,
                "engineCc": useCustomBike
                    ? engineCc
                    : selectedVariant?.engineCc,
                "primary": setAsPrimary,
              });
              if (!mounted) return;
              setState(() => _bikeActionLoading = false);

              if (result["success"] == true) {
                Navigator.of(this.context).pop(true);
                await _refreshProfile();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(result["message"] ?? "Bike added")),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result["message"]?.toString() ?? "Failed to add bike",
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add Bike",
                      style: GoogleFonts.lexend(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Bike ${bikes.length + 1}${_subscriptionActive ? "" : " of $_bikeLimit on free plan"}",
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!useCustomBike) ...[
                      _selectorTile("Brand", selectedBrand, () async {
                        final brand = await _pickStringOption(
                          title: "Select Brand",
                          loader: BikeRegistryService.fetchBrands,
                        );
                        if (brand == null) return;
                        setModalState(() {
                          modalError = null;
                          selectedBrand = brand;
                          selectedModel = "";
                          selectedVariant = null;
                        });
                      }),
                      const SizedBox(height: 14),
                      _selectorTile("Model", selectedModel, () async {
                        if (selectedBrand.isEmpty) {
                          setModalError("Select brand first");
                          return;
                        }
                        final model = await _pickStringOption(
                          title: "Select Model",
                          loader: (query) => BikeRegistryService.fetchModels(
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
                        "Variant",
                        selectedVariant?.variant ?? "",
                        () async {
                          if (selectedBrand.isEmpty || selectedModel.isEmpty) {
                            setModalError("Select brand and model first");
                            return;
                          }
                          final variantItem = await _pickVariantOption(
                            selectedBrand,
                            selectedModel,
                          );
                          if (variantItem == null) {
                            setModalError(
                              "No variants found for the selected brand and model",
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
                            selectedBrand = "";
                            selectedModel = "";
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
                          labelText: "Bike Brand",
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: "Bike Model",
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: variantController,
                        decoration: const InputDecoration(
                          labelText: "Bike Variant",
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Category",
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
                          final isSelected = customBikeCategory == category;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) {
                              setModalState(
                                () => customBikeCategory = category,
                              );
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Bike Type",
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
                          final isSelected = customBikeType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
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
                          "Custom bikes are saved as unverified",
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
                            customBikeCategory = "";
                            customBikeType = "";
                          });
                        },
                        child: const Text("Use Bike Registry Instead"),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Year"),
                    ),
                    if (useCustomBike) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: engineController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Engine CC",
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: setAsPrimary,
                      onChanged: (value) {
                        setModalState(() => setAsPrimary = value);
                      },
                      title: const Text("Set as primary bike"),
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
                          _bikeActionLoading ? "Saving..." : "Add Bike",
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

    if (added == true && mounted) {
      await _openBikeManager();
    }
  }

  Future<void> _removeBike(Map<String, dynamic> bike) async {
    final bikeId = int.tryParse((bike['id'] ?? "").toString());
    if (bikeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to remove this bike")),
      );
      return;
    }

    setState(() => _bikeActionLoading = true);
    final result = await UserService.deleteBike(bikeId);
    if (!mounted) return;
    setState(() => _bikeActionLoading = false);

    if (result["success"] == true) {
      await _refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Bike removed")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["message"]?.toString() ?? "Failed to remove bike",
          ),
        ),
      );
    }
  }

  Future<void> _openBikeManager() async {
    await showModalBottomSheet<void>(
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
            final bikeList = bikes;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Bikes",
                    style: GoogleFonts.lexend(
                      color: theme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subscriptionActive
                        ? "${bikeList.length} bikes registered"
                        : "${bikeList.length}/$_bikeLimit bikes on free plan",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_subscriptionActive && bikeList.length >= _bikeLimit)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium, color: theme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Remove a bike or upgrade to add more than $_bikeLimit bikes.",
                              style: TextStyle(color: theme.textPrimary),
                            ),
                          ),
                          TextButton(
                            onPressed: _openSubscriptionScreen,
                            child: const Text("Upgrade"),
                          ),
                        ],
                      ),
                    ),
                  if (bikeList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "No bikes registered yet.",
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.65),
                        ),
                      ),
                    )
                  else
                    ...bikeList.map((bike) {
                      final title = _bikeTitle(bike);
                      final subtitle = _bikeSubtitle(bike);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x52B8C6DA)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.two_wheeler, color: theme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title.isEmpty ? "Bike" : title,
                                          style: TextStyle(
                                            color: theme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if ((bike['primary'] ?? false) == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primary.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            "Primary",
                                            style: TextStyle(
                                              color: theme.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      if ((bike['verified'] ?? false) != true)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: const Text(
                                            "Unverified",
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle.isEmpty
                                        ? "Bike details"
                                        : subtitle,
                                    style: TextStyle(
                                      color: theme.textPrimary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _bikeActionLoading
                                  ? null
                                  : () async {
                                      await _removeBike(bike);
                                      if (!mounted) return;
                                      Navigator.of(this.context).pop();
                                      await _openBikeManager();
                                    },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bikeActionLoading
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _showAddBikeSheet();
                            },
                      child: const Text("Add Bike"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editBio(AppThemeConfig theme) async {
    final TextEditingController bioController = TextEditingController(
      text: _userData?['bio'] ?? "",
    );

    bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text("Edit Bio", style: TextStyle(color: theme.textPrimary)),
        content: TextField(
          controller: bioController,
          style: TextStyle(color: theme.textPrimary),
          maxLength: 150,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Tell us about your riding style...",
            hintStyle: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.4),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xff697389)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved == true && _userData != null && mounted) {
      final newBio = bioController.text.trim();
      final oldBio = _userData!['bio'];

      // Optimistic UI update
      setState(() {
        _userData!['bio'] = newBio;
      });

      // API Call
      bool success = await UserService.updateProfile({
        "bio": newBio,
        "firstName": _userData!['firstName'] ?? "",
        "lastName": _userData!['lastName'] ?? "",
        "profileImage": _userData!['profileImage'] ?? "",
      });

      if (!success && mounted) {
        // Rollback
        setState(() {
          _userData!['bio'] = oldBio;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save bio on the server.")),
        );
      }
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    AppThemeConfig theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.bebasNeue(
            color: theme.textPrimary,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.65),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, AppThemeConfig theme) {
    return InkWell(
      onTap: () => _openRideSummary(ride),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x52B8C6DA)),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.directions_bike, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride["title"] ?? ride["name"] ?? "Ride",
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _rideDateLabel(ride),
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${_formatKm(_rideDistanceKm(ride))} km",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _rideDurationLabel(ride),
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(dynamic achievement, AppThemeConfig theme) {
    String name = achievement is String
        ? achievement
        : (achievement["title"] ?? "Badge");
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: theme.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile",
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Icon(Icons.settings, color: theme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 64,
                                    width: 64,
                                    decoration: BoxDecoration(
                                      color: theme.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _userData != null &&
                                              _userData!['firstName'] != null &&
                                              _userData!['firstName'].isNotEmpty
                                          ? _userData!['firstName'][0]
                                                    .toUpperCase() +
                                                (_userData!['lastName'] !=
                                                            null &&
                                                        _userData!['lastName']
                                                            .isNotEmpty
                                                    ? _userData!['lastName'][0]
                                                          .toUpperCase()
                                                    : '')
                                          : "RU",
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 20,
                                      width: 20,
                                      decoration: BoxDecoration(
                                        color: theme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userData != null
                                          ? ((widget.userData!['username'] ??
                                                        '')
                                                    .toString())
                                                .trim()
                                          : "Guest User",
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if ((_userData?['riderId'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          "@${_userData!['riderId']}",
                                          style: TextStyle(
                                            color: theme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    GestureDetector(
                                      onTap: () => _editBio(theme),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _userData?['bio'] != null &&
                                                      _userData!['bio']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? _userData!['bio']
                                                  : "Tell us about your riding style...",
                                              style: TextStyle(
                                                color: theme.textPrimary
                                                    .withValues(alpha: 0.65),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit,
                                            color: theme.textPrimary.withValues(
                                              alpha: 0.4,
                                            ),
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bike Details
                        GestureDetector(
                          onTap: _openBikeManager,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x52B8C6DA),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.directions_bike,
                                    color: theme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bikes.isNotEmpty
                                            ? _bikeTitle(bikes.first)
                                            : "Add Your First Bike",
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        bikes.isNotEmpty
                                            ? "${_bikeSubtitle(bikes.first)} • ${bikes.length} registered"
                                            : "Tap to register your bike",
                                        style: TextStyle(
                                          color: theme.textPrimary.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (bikes.isNotEmpty &&
                                          (bikes.first['verified'] ?? false) !=
                                              true)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              "Unverified bike",
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Consolidated Ride Stats Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "RIDE STATS",
                                style: GoogleFonts.bebasNeue(
                                  color: theme.textPrimary,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    Icons.directions,
                                    _formatKm(_totalDistanceKm),
                                    "Km",
                                    theme,
                                  ),
                                  _buildStatItem(
                                    Icons.calendar_today,
                                    "$_totalRidesTaken",
                                    "Rides",
                                    theme,
                                  ),
                                  _buildStatItem(
                                    Icons.emoji_events,
                                    "${achievements.length}",
                                    "Badges",
                                    theme,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StatsScreen(userData: _userData),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: theme.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    "SEE FULL RIDE STATS",
                                    style: GoogleFonts.bebasNeue(
                                      color: theme.primary,
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          labelColor: theme.primary,
                          unselectedLabelColor: theme.textPrimary.withValues(
                            alpha: 0.6,
                          ),
                          indicatorColor: theme.primary,
                          tabs: const [
                            Tab(text: "Overview"),
                            Tab(text: "Rides"),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Overview Tab
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Achievements",
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: achievements.isEmpty ? null : 80,
                                      child: achievements.isEmpty
                                          ? Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 24,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: theme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0x52B8C6DA,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.workspace_premium,
                                                    color: theme.textPrimary
                                                        .withValues(alpha: 0.1),
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "Complete rides to earn badges!",
                                                    style: TextStyle(
                                                      color: theme.textPrimary
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView(
                                              scrollDirection: Axis.horizontal,
                                              children: achievements
                                                  .map<Widget>(
                                                    (a) =>
                                                        _buildAchievementCard(
                                                          a,
                                                          theme,
                                                        ),
                                                  )
                                                  .toList(),
                                            ),
                                    ),

                                  ],
                                ),
                              ),

                              // Rides Tab
                              rideHistory.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history,
                                            color: theme.textPrimary.withValues(
                                              alpha: 0.1,
                                            ),
                                            size: 64,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Your journey begins here",
                                            style: TextStyle(
                                              color: theme.textPrimary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Your completed rides will appear here.",
                                            style: TextStyle(
                                              color: theme.textPrimary
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      children: rideHistory
                                          .map<Widget>(
                                            (r) => _buildRideCard(r, theme),
                                          )
                                          .toList(),
                                    ),
                            ],
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
      },
    );
  }
}
