/// Shared labels for user garage / profile bike rows.
class BikeDisplayFormatters {
  BikeDisplayFormatters._();

  static String title(Map<String, dynamic> bike) {
    final brand =
        (bike['brand'] ?? bike['make'] ?? bike['title'] ?? '').toString().trim();
    final model = (bike['model'] ?? '').toString().trim();
    return [brand, model].where((part) => part.isNotEmpty).join(' ');
  }

  static String subtitle(Map<String, dynamic> bike) {
    final variant = (bike['variant'] ?? '').toString().trim();
    final category = _labelToken((bike['category'] ?? '').toString());
    final type =
        _labelToken((bike['bikeType'] ?? bike['type'] ?? '').toString());
    final engineCc = bike['engineCc']?.toString();
    final year = bike['year']?.toString().trim();

    final parts = <String>[
      if (variant.isNotEmpty) variant,
      if (category.isNotEmpty) category,
      if (type.isNotEmpty) type,
      if (engineCc != null &&
          engineCc.isNotEmpty &&
          engineCc != '0' &&
          int.tryParse(engineCc) != 0)
        '${engineCc}cc',
      if (year != null && year.isNotEmpty) year,
    ];

    return parts.join(' • ');
  }

  static String _labelToken(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.toLowerCase() == 'adv') {
      return 'ADV';
    }
    if (trimmed.length == 1) {
      return trimmed.toUpperCase();
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }
}
