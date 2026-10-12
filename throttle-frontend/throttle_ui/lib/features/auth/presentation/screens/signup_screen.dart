import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/main_screen.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/utils/app_feedback.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/bikes/data/models/bike_catalog_item.dart';
import 'package:throttle_ui/features/bikes/data/services/bike_registry_service.dart';

class SignupScreen extends StatefulWidget {
  final bool isGoogleRegistration;
  final Map<String, dynamic>? googleData;

  const SignupScreen({
    super.key,
    this.isGoogleRegistration = false,
    this.googleData,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController controller = PageController();

  int step = 0;
  bool obscurePassword = true;

  String? _firstNameError;
  String? _riderIdError;
  String? _emailError;
  String? _passwordError;
  String? _pronounError;

  String pronoun = "";
  String preference = "";
  String selectedBrand = "";
  String selectedModel = "";
  BikeCatalogItem? selectedVariant;
  bool useCustomBike = false;
  String customBikeCategory = "";
  String customBikeType = "";

  final firstNameController = TextEditingController();
  final surNameController = TextEditingController();
  final riderIdController = TextEditingController();
  final bikeBrandController = TextEditingController();
  final bikeModelController = TextEditingController();
  final bikeVariantController = TextEditingController();
  final bikeYearController = TextEditingController();
  final bikeEngineCcController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final pronouns = ["He/Him", "She/Her", "They/Them", "Other"];
  final bikeTypes = [
    "Motorcycle",
    "Electric Scooter",
    "Scooter",
    "Tourer",
    "Custom Build",
  ];
  final bikeCategories = ["Cruiser", "Sport", "Commuter", "ADV"];
  final preferences = [
    "Weekend Rides",
    "Long Tours",
    "City Riding",
    "Track Days",
    "Group Rides",
    "Casual Riding",
  ];

  AppThemeConfig get _theme => ThemeController.instance.theme;
  bool get _isDarkTheme => _theme.brightness == Brightness.dark;
  Color get _textSecondary => _theme.textPrimary.withValues(alpha: 0.68);
  Color get _textMuted => _theme.textPrimary.withValues(alpha: 0.56);
  Color get _borderColor =>
      _theme.textPrimary.withValues(alpha: _isDarkTheme ? 0.18 : 0.12);
  Color get _cardColor => Color.lerp(
    _theme.surface,
    _theme.background,
    _isDarkTheme ? 0.15 : 0.35,
  )!;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleRegistration && widget.googleData != null) {
      emailController.text = widget.googleData!["email"] ?? "";
      firstNameController.text = widget.googleData!["firstName"] ?? "";
      surNameController.text = widget.googleData!["lastName"] ?? "";
    }
  }

  @override
  void dispose() {
    controller.dispose();
    firstNameController.dispose();
    surNameController.dispose();
    riderIdController.dispose();
    bikeBrandController.dispose();
    bikeModelController.dispose();
    bikeVariantController.dispose();
    bikeYearController.dispose();
    bikeEngineCcController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (step == 0) {
      setState(() {
        _firstNameError = null;
        _riderIdError = null;
        _emailError = null;
        _passwordError = null;
        _pronounError = null;
      });

      bool hasError = false;

      if (firstNameController.text.trim().isEmpty) {
        setState(() => _firstNameError = "First name is required");
        hasError = true;
      }

      final email = emailController.text.trim();
      if (email.isEmpty) {
        setState(() => _emailError = "Email is required");
        hasError = true;
      } else if (!email.contains("@") || !email.contains(".")) {
        setState(() => _emailError = "Please enter a valid email address");
        hasError = true;
      }

      final riderId = riderIdController.text.trim();
      final riderIdPattern = RegExp(r'^[A-Za-z0-9._]{3,30}$');
      if (riderId.isEmpty) {
        setState(() => _riderIdError = "Rider ID is required");
        hasError = true;
      } else if (!riderIdPattern.hasMatch(riderId)) {
        setState(() => _riderIdError = "Must be 3-30 characters (letters, numbers, '.', '_')");
        hasError = true;
      }

      if (!widget.isGoogleRegistration) {
        if (passwordController.text.isEmpty) {
          setState(() => _passwordError = "Password is required");
          hasError = true;
        } else if (passwordController.text.length < 6) {
          setState(() => _passwordError = "Password must be at least 6 characters");
          hasError = true;
        }
      }

      if (pronoun.isEmpty) {
        setState(() => _pronounError = "Please select your pronoun");
        hasError = true;
      }

      if (hasError) return;
    }

    if (step == 2) {
      final catalogBikeTouched =
          selectedBrand.isNotEmpty ||
          selectedModel.isNotEmpty ||
          selectedVariant != null;
      final customBikeTouched =
          bikeBrandController.text.trim().isNotEmpty ||
          bikeModelController.text.trim().isNotEmpty ||
          bikeVariantController.text.trim().isNotEmpty ||
          bikeYearController.text.trim().isNotEmpty ||
          bikeEngineCcController.text.trim().isNotEmpty ||
          customBikeCategory.isNotEmpty ||
          customBikeType.isNotEmpty;

      final shouldSubmitCatalogBike = !useCustomBike && selectedVariant != null;
      final shouldSubmitCustomBike = useCustomBike && customBikeTouched;

      if (catalogBikeTouched && !shouldSubmitCatalogBike) {
        showError("Select brand, model, and variant or clear the bike fields");
        return;
      }

      if (shouldSubmitCustomBike) {
        if (customBikeCategory.isEmpty ||
            customBikeType.isEmpty ||
            bikeBrandController.text.trim().isEmpty ||
            bikeModelController.text.trim().isEmpty ||
            bikeVariantController.text.trim().isEmpty ||
            bikeEngineCcController.text.trim().isEmpty) {
          showError(
            "Complete all custom bike fields or switch to bike registry",
          );
          return;
        }
      }

      final parsedBikeYear = bikeYearController.text.trim().isEmpty
          ? null
          : int.tryParse(bikeYearController.text.trim());
      final parsedBikeEngineCc = bikeEngineCcController.text.trim().isEmpty
          ? null
          : int.tryParse(bikeEngineCcController.text.trim());

      if (bikeYearController.text.trim().isNotEmpty &&
          (parsedBikeYear == null ||
              parsedBikeYear < 1950 ||
              parsedBikeYear > 2100)) {
        showError("Enter a valid bike year");
        return;
      }

      if ((shouldSubmitCatalogBike || shouldSubmitCustomBike) &&
          parsedBikeYear == null) {
        showError("Enter the year of purchase");
        return;
      }

      if (shouldSubmitCustomBike &&
          bikeEngineCcController.text.trim().isNotEmpty &&
          (parsedBikeEngineCc == null ||
              parsedBikeEngineCc < 50 ||
              parsedBikeEngineCc > 5000)) {
        showError("Enter a valid engine CC");
        return;
      }

      final bikeYear = shouldSubmitCatalogBike || shouldSubmitCustomBike
          ? parsedBikeYear
          : null;
      final bikeEngineCc = shouldSubmitCustomBike
          ? parsedBikeEngineCc
          : shouldSubmitCatalogBike
          ? selectedVariant?.engineCc
          : null;
      final bikeMasterId = shouldSubmitCatalogBike ? selectedVariant?.id : null;
      final bikeBrand = shouldSubmitCustomBike
          ? _nullableText(bikeBrandController)
          : shouldSubmitCatalogBike
          ? selectedVariant?.brand
          : null;
      final bikeModel = shouldSubmitCustomBike
          ? _nullableText(bikeModelController)
          : shouldSubmitCatalogBike
          ? selectedVariant?.model
          : null;
      final bikeVariant = shouldSubmitCustomBike
          ? _nullableText(bikeVariantController)
          : shouldSubmitCatalogBike
          ? selectedVariant?.variant
          : null;
      final bikeCategory = shouldSubmitCustomBike
          ? customBikeCategory.toLowerCase()
          : shouldSubmitCatalogBike
          ? selectedVariant?.category
          : null;
      final bikeType = shouldSubmitCustomBike
          ? customBikeType
          : shouldSubmitCatalogBike
          ? selectedVariant?.bikeType
          : null;

      final result = widget.isGoogleRegistration
          ? await AuthService.completeGoogleRegistration(
              email: emailController.text.trim(),
              firstName: firstNameController.text.trim(),
              lastName: surNameController.text.trim(),
              riderId: riderIdController.text.trim(),
              pronoun: pronoun,
              bikeMasterId: bikeMasterId,
              bikeBrand: bikeBrand,
              bikeModel: bikeModel,
              bikeVariant: bikeVariant,
              bikeCategory: bikeCategory,
              bikeType: bikeType,
              bikeYear: bikeYear,
              bikeEngineCc: bikeEngineCc,
            )
          : await AuthService.register(
              firstName: firstNameController.text.trim(),
              lastName: surNameController.text.trim(),
              riderId: riderIdController.text.trim(),
              pronoun: pronoun,
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              bikeMasterId: bikeMasterId,
              bikeBrand: bikeBrand,
              bikeModel: bikeModel,
              bikeVariant: bikeVariant,
              bikeCategory: bikeCategory,
              bikeType: bikeType,
              bikeYear: bikeYear,
              bikeEngineCc: bikeEngineCc,
              experienceYears: 0,
            );

      if (result["success"]) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, _, _) => const MainScreen(),
            transitionsBuilder: (_, animation, _, child) {
              final offsetAnimation =
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  );
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      } else {
        showError(result["message"]);
      }
      return;
    }

    controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => step++);
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void back() {
    if (step > 0) {
      controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => step--);
    }
  }

  void showError(String message) {
    AppFeedback.showError(message, context: context);
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
      backgroundColor: _theme.background,
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
                        color: _theme.textPrimary,
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

  Future<BikeCatalogItem?> _pickVariantOption() async {
    if (selectedBrand.isEmpty || selectedModel.isEmpty) {
      showError("Select brand and model first");
      return null;
    }

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
        selectedBrand,
        selectedModel,
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
      backgroundColor: _theme.background,
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
                        color: _theme.textPrimary,
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
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          useCustomBike = true;
                          selectedVariant = null;
                        });
                      },
                      child: const Text("Add Custom Bike"),
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

  Widget optionGrid(
    List<String> options,
    String selected,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((e) {
        final isSelected = selected == e;

        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _theme.primary : _theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _theme.primary : _borderColor,
              ),
            ),
            child: Text(
              e,
              style: GoogleFonts.lexend(
                color: isSelected ? Colors.white : _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget thinInput(
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          keyboardType: type,
          readOnly: hint == "Email" && widget.isGoogleRegistration,
          obscureText: isPassword ? obscurePassword : false,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(color: _theme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: _cardColor,
            enabledBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 1.5),
                  )
                : null,
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 1.5),
                  )
                : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: _textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  )
                : null,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Color(0xFFFF4D4F),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFF4D4F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _selectorTile(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: _textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? "Select $label" : value,
                    style: GoogleFonts.plusJakartaSans(
                      color: value.isEmpty ? _textMuted : _theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Widget _bikeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Register your first bike now, or leave it blank and add it later from your profile.",
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 24),
        if (!useCustomBike) ...[
          _selectorTile("Brand", selectedBrand, () async {
            final brand = await _pickStringOption(
              title: "Select Brand",
              loader: BikeRegistryService.fetchBrands,
            );
            if (brand == null) return;
            setState(() {
              selectedBrand = brand;
              selectedModel = "";
              selectedVariant = null;
            });
          }),
          const SizedBox(height: 16),
          _selectorTile("Model", selectedModel, () async {
            if (selectedBrand.isEmpty) {
              showError("Select a brand first");
              return;
            }
            final model = await _pickStringOption(
              title: "Select Model",
              loader: (query) =>
                  BikeRegistryService.fetchModels(selectedBrand, query),
            );
            if (model == null) return;
            setState(() {
              selectedModel = model;
              selectedVariant = null;
            });
          }),
          const SizedBox(height: 16),
          _selectorTile("Variant", selectedVariant?.variant ?? "", () async {
            final variant = await _pickVariantOption();
            if (variant == null) return;
            setState(() {
              selectedVariant = variant;
              useCustomBike = false;
            });
          }),
          if (selectedVariant != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(selectedVariant!.category.toUpperCase())),
                Chip(label: Text(selectedVariant!.bikeType)),
                if (selectedVariant!.engineCc != null)
                  Chip(label: Text("${selectedVariant!.engineCc}cc")),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                useCustomBike = true;
                selectedBrand = "";
                selectedModel = "";
                selectedVariant = null;
              });
            },
            child: const Text("Can't find your bike? Add Custom Bike"),
          ),
        ] else ...[
          thinInput("Bike Brand", bikeBrandController),
          const SizedBox(height: 20),
          thinInput("Bike Model", bikeModelController),
          const SizedBox(height: 20),
          thinInput("Bike Variant", bikeVariantController),
          const SizedBox(height: 20),
          const Text("Category", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 15),
          optionGrid(
            bikeCategories,
            customBikeCategory,
            (v) => setState(() => customBikeCategory = v),
          ),
          const SizedBox(height: 20),
          const Text(
            "Bike Type",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          optionGrid(
            bikeTypes,
            customBikeType,
            (v) => setState(() => customBikeType = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              "Custom bikes are saved as unverified",
              style: TextStyle(color: Colors.orange),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                useCustomBike = false;
                bikeBrandController.clear();
                bikeModelController.clear();
                bikeVariantController.clear();
                bikeEngineCcController.clear();
                customBikeCategory = "";
                customBikeType = "";
              });
            },
            child: const Text("Use Bike Registry Instead"),
          ),
        ],
        if (selectedVariant != null || useCustomBike) ...[
          const SizedBox(height: 12),
          thinInput(
            "Year of Purchase",
            bikeYearController,
            type: TextInputType.number,
          ),
        ],
        if (useCustomBike) ...[
          const SizedBox(height: 20),
          thinInput(
            "Engine CC",
            bikeEngineCcController,
            type: TextInputType.number,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _theme.background,
          body: SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (step + 1) / 3,
                  backgroundColor: _theme.surface,
                  color: _theme.primary,
                ),
                Expanded(
                  child: PageView(
                    controller: controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      buildStep(
                        "Tell us about you",
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            thinInput(
                              "First Name",
                              firstNameController,
                              errorText: _firstNameError,
                              onChanged: (_) {
                                if (_firstNameError != null) {
                                  setState(() => _firstNameError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            thinInput("Last Name", surNameController),
                            const SizedBox(height: 20),
                            thinInput(
                              "Rider ID",
                              riderIdController,
                              errorText: _riderIdError,
                              onChanged: (_) {
                                if (_riderIdError != null) {
                                  setState(() => _riderIdError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            thinInput(
                              "Email",
                              emailController,
                              type: TextInputType.emailAddress,
                              errorText: _emailError,
                              onChanged: (_) {
                                if (_emailError != null) {
                                  setState(() => _emailError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            if (!widget.isGoogleRegistration) ...[
                              thinInput(
                                "Password",
                                passwordController,
                                isPassword: true,
                                errorText: _passwordError,
                                onChanged: (_) {
                                  if (_passwordError != null) {
                                    setState(() => _passwordError = null);
                                  }
                                },
                              ),
                              const SizedBox(height: 30),
                            ],
                            Text(
                              "Pronoun",
                              style: TextStyle(
                                color: _pronounError != null
                                    ? const Color(0xFFFF4D4F)
                                    : _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 15),
                            optionGrid(
                              pronouns,
                              pronoun,
                              (v) => setState(() {
                                pronoun = v;
                                _pronounError = null;
                              }),
                            ),
                            if (_pronounError != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 13,
                                    color: Color(0xFFFF4D4F),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _pronounError!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFFF4D4F),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      buildStep(
                        "Your Riding Style",
                        optionGrid(
                          preferences,
                          preference,
                          (v) => setState(() => preference = v),
                        ),
                      ),
                      buildStep("Your Bike", _bikeStep()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: next,
                          child: Text(
                            "CONTINUE",
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (step > 0)
                        TextButton(
                          onPressed: back,
                          child: Text(
                            "Back",
                            style: GoogleFonts.lexend(
                              color: _textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildStep(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _theme.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            content,
          ],
        ),
      ),
    );
  }
}
