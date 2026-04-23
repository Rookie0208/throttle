import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/main_screen.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
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
      if (firstNameController.text.trim().isEmpty) {
        showError("First name is required");
        return;
      }
      if (emailController.text.trim().isEmpty) {
        showError("Email is required");
        return;
      }
      if (pronoun.isEmpty) {
        showError("Please select your pronoun");
        return;
      }

      final riderId = riderIdController.text.trim();
      if (riderId.isEmpty) {
        showError("Rider ID is required");
        return;
      }

      final riderIdPattern = RegExp(r'^[A-Za-z0-9._]{3,30}$');
      if (!riderIdPattern.hasMatch(riderId)) {
        showError(
          "Rider ID must be 3-30 characters and use only letters, numbers, dots, or underscores",
        );
        return;
      }

      if (!emailController.text.contains("@")) {
        showError("Enter a valid email");
        return;
      }

      if (!widget.isGoogleRegistration && passwordController.text.length < 6) {
        showError("Password must be at least 6 characters");
        return;
      }
    }

    if (step == 2) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
      backgroundColor: AppColors.background,
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
                        color: AppColors.textPrimary,
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
      backgroundColor: AppColors.background,
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
                        color: AppColors.textPrimary,
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
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              e,
              style: GoogleFonts.lexend(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      readOnly: hint == "Email" && widget.isGoogleRegistration,
      obscureText: isPassword ? obscurePassword : false,
      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        fillColor: AppColors.card,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              )
            : null,
      ),
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? "Select $label" : value,
                    style: GoogleFonts.plusJakartaSans(
                      color: value.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
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
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
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
          const Text(
            "Category",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          optionGrid(
            bikeCategories,
            customBikeCategory,
            (v) => setState(() => customBikeCategory = v),
          ),
          const SizedBox(height: 20),
          const Text(
            "Bike Type",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (step + 1) / 3,
              backgroundColor: AppColors.surface,
              color: colorScheme.primary,
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
                        thinInput("First Name", firstNameController),
                        const SizedBox(height: 20),
                        thinInput("Last Name", surNameController),
                        const SizedBox(height: 20),
                        thinInput("Rider ID", riderIdController),
                        const SizedBox(height: 20),
                        thinInput(
                          "Email",
                          emailController,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        if (!widget.isGoogleRegistration) ...[
                          thinInput(
                            "Password",
                            passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 30),
                        ],
                        const Text(
                          "Pronoun",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        optionGrid(
                          pronouns,
                          pronoun,
                          (v) => setState(() => pronoun = v),
                        ),
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
                          color: AppColors.white,
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
                          color: AppColors.textMuted,
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
                color: AppColors.textPrimary,
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
