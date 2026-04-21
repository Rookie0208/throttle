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
    } catch (e, st) {
      await Logger.error("Failed to fetch bike brands", e, st);
    }
    return const [];
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
    } catch (e, st) {
      await Logger.error("Failed to fetch bike models", e, st);
    }
    return const [];
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
        return (decoded['data'] as List)
            .whereType<Map>()
            .map(
              (item) =>
                  BikeCatalogItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    } catch (e, st) {
      await Logger.error("Failed to fetch bike variants", e, st);
    }
    return const [];
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
    } catch (e, st) {
      await Logger.error("Failed to search bike catalog", e, st);
    }
    return const [];
  }
}
