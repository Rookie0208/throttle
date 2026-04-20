class BikeCatalogItem {
  final int id;
  final String brand;
  final String model;
  final String variant;
  final int? engineCc;
  final String category;
  final String bikeType;
  final double? tankCapacity;
  final int? rangeKm;
  final int? comfortScore;
  final bool active;
  final bool verified;

  const BikeCatalogItem({
    required this.id,
    required this.brand,
    required this.model,
    required this.variant,
    this.engineCc,
    required this.category,
    required this.bikeType,
    this.tankCapacity,
    this.rangeKm,
    this.comfortScore,
    required this.active,
    required this.verified,
  });

  String get label => "$brand $model $variant".trim();

  factory BikeCatalogItem.fromJson(Map<String, dynamic> json) {
    return BikeCatalogItem(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      variant: (json['variant'] ?? '').toString(),
      engineCc: int.tryParse((json['engineCc'] ?? '').toString()),
      category: (json['category'] ?? '').toString(),
      bikeType: (json['bikeType'] ?? '').toString(),
      tankCapacity: double.tryParse((json['tankCapacity'] ?? '').toString()),
      rangeKm: int.tryParse((json['rangeKm'] ?? '').toString()),
      comfortScore: int.tryParse((json['comfortScore'] ?? '').toString()),
      active: (json['active'] ?? false) == true,
      verified: (json['verified'] ?? false) == true,
    );
  }
}
