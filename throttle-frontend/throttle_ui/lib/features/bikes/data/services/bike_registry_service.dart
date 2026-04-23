import 'dart:convert';

import 'package:throttle_ui/core/network/api_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';
import 'package:throttle_ui/features/bikes/data/models/bike_catalog_item.dart';

class BikeRegistryService {
  static Future<List<String>> fetchBrands([String query = ""]) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await ApiService.get(
        '/bikes/brands?query=$encodedQuery',
      );
      final decoded = jsonDecode(response['body']);
      if ((response['status'] == 200 || response['status'] == 201) &&
          decoded['data'] is List) {
        return List<String>.from(decoded['data']);
      }
      await Logger.warn(
        "Bike brands request returned status=${response['status']} body=${response['body']}",
      );
    } catch (e, st) {
      await Logger.error("Failed to fetch bike brands", e, st);
    }
    return _fallbackBrands(query);
  }

  static Future<List<String>> fetchModels(
    String brand, [
    String query = "",
  ]) async {
    try {
      final encodedBrand = Uri.encodeQueryComponent(brand);
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await ApiService.get(
        '/bikes/models?brand=$encodedBrand&query=$encodedQuery',
      );
      final decoded = jsonDecode(response['body']);
      if ((response['status'] == 200 || response['status'] == 201) &&
          decoded['data'] is List) {
        return List<String>.from(decoded['data']);
      }
      await Logger.warn(
        "Bike models request returned status=${response['status']} body=${response['body']}",
      );
    } catch (e, st) {
      await Logger.error("Failed to fetch bike models", e, st);
    }
    return _fallbackModels(brand, query);
  }

  static Future<List<BikeCatalogItem>> fetchVariants(
    String brand,
    String model, [
    String query = "",
  ]) async {
    try {
      final encodedBrand = Uri.encodeQueryComponent(brand);
      final encodedModel = Uri.encodeQueryComponent(model);
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await ApiService.get(
        '/bikes/variants?brand=$encodedBrand&model=$encodedModel&query=$encodedQuery',
      );
      final decoded = jsonDecode(response['body']);
      if ((response['status'] == 200 || response['status'] == 201) &&
          decoded['data'] is List) {
        final variants = (decoded['data'] as List)
            .whereType<Map>()
            .map(
              (item) =>
                  BikeCatalogItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        if (variants.isNotEmpty) {
          return variants;
        }
      }
      await Logger.warn(
        "Bike variants request returned status=${response['status']} body=${response['body']}",
      );
    } catch (e, st) {
      await Logger.error("Failed to fetch bike variants", e, st);
    }
    return _fallbackVariants(brand, model, query);
  }

  static Future<List<BikeCatalogItem>> _fallbackVariants(
    String brand,
    String model,
    String query,
  ) async {
    final normalizedBrand = brand.trim().toLowerCase();
    final normalizedModel = model.trim().toLowerCase();
    final normalizedQuery = query.trim().toLowerCase();
    final searchResults = await search("$brand $model");

    return searchResults.where((item) {
      final brandMatches = item.brand.trim().toLowerCase() == normalizedBrand;
      final modelMatches = item.model.trim().toLowerCase() == normalizedModel;
      if (!brandMatches || !modelMatches) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return item.variant.trim().toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  static Future<List<String>> _fallbackBrands(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final searchResults = await search(query);
    final brands = <String>{};

    for (final item in searchResults) {
      final brand = item.brand.trim();
      if (brand.isEmpty) {
        continue;
      }
      if (normalizedQuery.isNotEmpty &&
          !brand.toLowerCase().contains(normalizedQuery)) {
        continue;
      }
      brands.add(brand);
    }

    final sortedBrands = brands.toList()..sort();
    return sortedBrands;
  }

  static Future<List<String>> _fallbackModels(
    String brand,
    String query,
  ) async {
    final normalizedBrand = brand.trim().toLowerCase();
    final normalizedQuery = query.trim().toLowerCase();
    final searchSeed = query.trim().isEmpty ? brand : "$brand $query";
    final searchResults = await search(searchSeed);
    final models = <String>{};

    for (final item in searchResults) {
      if (item.brand.trim().toLowerCase() != normalizedBrand) {
        continue;
      }

      final model = item.model.trim();
      if (model.isEmpty) {
        continue;
      }
      if (normalizedQuery.isNotEmpty &&
          !model.toLowerCase().contains(normalizedQuery)) {
        continue;
      }
      models.add(model);
    }

    final sortedModels = models.toList()..sort();
    return sortedModels;
  }

  static Future<List<BikeCatalogItem>> search(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final response = await ApiService.get(
        '/bikes/search?query=$encodedQuery',
      );
      final decoded = jsonDecode(response['body']);
      if ((response['status'] == 200 || response['status'] == 201) &&
          decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map>()
            .map(
              (item) =>
                  BikeCatalogItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      await Logger.warn(
        "Bike catalog search returned status=${response['status']} body=${response['body']}",
      );
    } catch (e, st) {
      await Logger.error("Failed to search bike catalog", e, st);
    }
    return const [];
  }
}
