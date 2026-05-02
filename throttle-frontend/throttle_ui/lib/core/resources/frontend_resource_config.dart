import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FrontendResourceConfig extends ChangeNotifier {
  FrontendResourceConfig._();

  static final FrontendResourceConfig instance = FrontendResourceConfig._();
  static const String assetPath = 'assets/config/frontend-resource-config.json';
  static const Duration refreshInterval = Duration(seconds: 20);

  FrontendResourceData _data = FrontendResourceData.defaults();
  Map<String, dynamic> _flatValues = _flattenMap(_defaultRawConfig());
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  FrontendResourceData get data => _data;
  FrontendUrlResourceConfig get urls => _data.urls;
  FrontendAssetResourceConfig get assets => _data.assets;
  FrontendFeatureFlagResourceConfig get featureFlags => _data.featureFlags;
  FrontendLimitResourceConfig get limits => _data.limits;
  FrontendNavigationResourceConfig get navigation => _data.navigation;
  FrontendSubscriptionResourceConfig get subscriptions => _data.subscriptions;
  Map<String, dynamic> get values => Map.unmodifiable(_flatValues);

  Future<void> load() async {
    var changed = false;
    try {
      changed = await _loadLocalAsset();
      changed = await _loadRemoteOverride() || changed;
    } catch (_) {
      _data = FrontendResourceData.defaults();
      _flatValues = _flattenMap(_defaultRawConfig());
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
    _startAutoRefresh();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final changed = await _loadRemoteOverride();
      if (changed) {
        notifyListeners();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  String? getString(String key, {String? fallback}) {
    final value = _flatValues[key];
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  int? getInt(String key, {int? fallback}) {
    final value = _flatValues[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  double? getDouble(String key, {double? fallback}) {
    final value = _flatValues[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  bool? getBool(String key, {bool? fallback}) {
    final value = _flatValues[key];
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return fallback;
  }

  Map<String, dynamic>? getJson(String key) {
    final value = _flatValues[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  dynamic getValue(String key, {dynamic fallback}) {
    return _flatValues.containsKey(key) ? _flatValues[key] : fallback;
  }

  Future<bool> _loadLocalAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return _applyConfig(Map<String, dynamic>.from(decoded));
    }
    return false;
  }

  Future<bool> _loadRemoteOverride() async {
    try {
      final response = await http.get(
        Uri.parse('${_resolveApiBaseUrl()}/resources/frontend'),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      final payload = _extractPayload(decoded);
      if (payload != null) {
        return _applyConfig(payload);
      }
      return false;
    } catch (_) {
      // Keep local asset data when the remote override is unavailable.
      return false;
    }
  }

  Map<String, dynamic>? _extractPayload(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return map;
    }
    return null;
  }

  String _resolveApiBaseUrl() {
    final configuredBaseUrl =
        dotenv.env['API_BASE_URL']?.trim() ?? _data.urls.apiBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  bool _applyConfig(Map<String, dynamic> raw) {
    final normalized = _normalizeRawConfig(raw);
    final nextData = FrontendResourceData.fromJson(normalized);
    final nextFlatValues = _flattenMap(normalized);

    final changed =
        jsonEncode(_flatValues) != jsonEncode(nextFlatValues) ||
        jsonEncode(_data.toJson()) != jsonEncode(nextData.toJson());
    _data = nextData;
    _flatValues = nextFlatValues;
    return changed;
  }

  void _startAutoRefresh() {
    _refreshTimer ??= Timer.periodic(refreshInterval, (_) {
      unawaited(refresh());
    });
  }

  Map<String, dynamic> _normalizeRawConfig(Map<String, dynamic> raw) {
    final normalized = _deepCloneMap(raw);
    final flatRawValues = _flattenMap(normalized);
    final urls = _ensureMap(normalized, 'urls');
    _assignIfPresent(
      urls,
      'apiBaseUrl',
      _readString(flatRawValues, 'API_BASE_URL'),
    );
    _assignIfPresent(
      urls,
      'websiteBaseUrl',
      _readString(flatRawValues, 'WEBSITE_URL'),
    );
    _assignIfPresent(
      urls,
      'whatsappCommunityUrl',
      _readString(flatRawValues, 'WHATSAPP_COMMUNITY_URL'),
    );
    _assignIfPresent(
      urls,
      'privacyPolicyUrl',
      _readString(flatRawValues, 'PRIVACY_POLICY_URL'),
    );
    _assignIfPresent(urls, 'termsUrl', _readString(flatRawValues, 'TERMS_URL'));

    final limits = _ensureMap(normalized, 'limits');
    final freePlanMaxBikes = _readInt(flatRawValues, 'FREE_PLAN_MAX_BIKES');
    if (freePlanMaxBikes != null) {
      limits['freePlanMaxBikes'] = freePlanMaxBikes;
    }

    final subscriptions = _ensureMap(normalized, 'subscriptions');
    _assignIfPresent(
      subscriptions,
      'title',
      _readString(flatRawValues, 'SUBSCRIPTION_TITLE'),
    );
    _assignIfPresent(
      subscriptions,
      'description',
      _readString(flatRawValues, 'SUBSCRIPTION_DESCRIPTION'),
    );

    return normalized;
  }

  static Map<String, dynamic> _deepCloneMap(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }

  static Map<String, dynamic> _ensureMap(
    Map<String, dynamic> parent,
    String key,
  ) {
    final existing = parent[key];
    if (existing is Map<String, dynamic>) return existing;
    if (existing is Map) {
      final map = Map<String, dynamic>.from(existing);
      parent[key] = map;
      return map;
    }
    final created = <String, dynamic>{};
    parent[key] = created;
    return created;
  }

  static void _assignIfPresent(
    Map<String, dynamic> target,
    String key,
    dynamic value,
  ) {
    if (value != null) {
      target[key] = value;
    }
  }

  static Map<String, dynamic> _flattenMap(
    Map<String, dynamic> source, [
    String prefix = '',
  ]) {
    final flattened = <String, dynamic>{};
    source.forEach((key, value) {
      final nextKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        flattened.addAll(_flattenMap(value, nextKey));
      } else if (value is Map) {
        flattened.addAll(
          _flattenMap(Map<String, dynamic>.from(value), nextKey),
        );
      } else {
        flattened[nextKey] = value;
      }
    });
    return flattened;
  }

  static Map<String, dynamic> _defaultRawConfig() =>
      FrontendResourceData.defaults().toJson();

  static String? _readString(Map<String, dynamic> values, String key) {
    final value = values[key];
    if (value is String) return value;
    return value?.toString();
  }

  static int? _readInt(Map<String, dynamic> values, String key) {
    final value = values[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static IconData resolveIcon(String iconName) {
    switch (iconName) {
      case 'space_dashboard_outlined':
        return Icons.space_dashboard_outlined;
      case 'space_dashboard_rounded':
        return Icons.space_dashboard_rounded;
      case 'two_wheeler_outlined':
        return Icons.two_wheeler_outlined;
      case 'two_wheeler_rounded':
        return Icons.two_wheeler_rounded;
      case 'groups_2_outlined':
        return Icons.groups_2_outlined;
      case 'groups_2_rounded':
        return Icons.groups_2_rounded;
      case 'diversity_3_outlined':
        return Icons.diversity_3_outlined;
      case 'diversity_3_rounded':
        return Icons.diversity_3_rounded;
      case 'person_outline_rounded':
        return Icons.person_outline_rounded;
      case 'person_rounded':
        return Icons.person_rounded;
      case 'add_rounded':
        return Icons.add_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class FrontendResourceData {
  final FrontendUrlResourceConfig urls;
  final FrontendAssetResourceConfig assets;
  final FrontendFeatureFlagResourceConfig featureFlags;
  final FrontendLimitResourceConfig limits;
  final FrontendNavigationResourceConfig navigation;
  final FrontendSubscriptionResourceConfig subscriptions;

  const FrontendResourceData({
    required this.urls,
    required this.assets,
    required this.featureFlags,
    required this.limits,
    required this.navigation,
    required this.subscriptions,
  });

  factory FrontendResourceData.defaults() => FrontendResourceData(
    urls: FrontendUrlResourceConfig.defaults(),
    assets: FrontendAssetResourceConfig.defaults(),
    featureFlags: FrontendFeatureFlagResourceConfig.defaults(),
    limits: FrontendLimitResourceConfig.defaults(),
    navigation: FrontendNavigationResourceConfig.defaults(),
    subscriptions: FrontendSubscriptionResourceConfig.defaults(),
  );

  factory FrontendResourceData.fromJson(Map<String, dynamic> json) {
    return FrontendResourceData(
      urls: FrontendUrlResourceConfig.fromJson(_mapValue(json['urls'])),
      assets: FrontendAssetResourceConfig.fromJson(_mapValue(json['assets'])),
      featureFlags: FrontendFeatureFlagResourceConfig.fromJson(
        _mapValue(json['featureFlags']),
      ),
      limits: FrontendLimitResourceConfig.fromJson(_mapValue(json['limits'])),
      navigation: FrontendNavigationResourceConfig.fromJson(
        _mapValue(json['navigation']),
      ),
      subscriptions: FrontendSubscriptionResourceConfig.fromJson(
        _mapValue(json['subscriptions']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urls': urls.toJson(),
      'assets': assets.toJson(),
      'featureFlags': featureFlags.toJson(),
      'limits': limits.toJson(),
      'navigation': navigation.toJson(),
      'subscriptions': subscriptions.toJson(),
    };
  }
}

class FrontendUrlResourceConfig {
  final String apiBaseUrl;
  final String websiteBaseUrl;
  final String whatsappCommunityUrl;
  final String privacyPolicyUrl;
  final String termsUrl;

  const FrontendUrlResourceConfig({
    required this.apiBaseUrl,
    required this.websiteBaseUrl,
    required this.whatsappCommunityUrl,
    required this.privacyPolicyUrl,
    required this.termsUrl,
  });

  factory FrontendUrlResourceConfig.defaults() =>
      const FrontendUrlResourceConfig(
        apiBaseUrl: 'http://localhost:8080/api/v1',
        websiteBaseUrl: 'https://throttle.app',
        whatsappCommunityUrl:
            'https://chat.whatsapp.com/BvFnvej1Oup4bSxulL5c6U',
        privacyPolicyUrl: 'https://throttle.app/privacy',
        termsUrl: 'https://throttle.app/terms',
      );

  factory FrontendUrlResourceConfig.fromJson(Map<String, dynamic> json) {
    final defaults = FrontendUrlResourceConfig.defaults();
    return FrontendUrlResourceConfig(
      apiBaseUrl: _stringValue(json['apiBaseUrl'], defaults.apiBaseUrl),
      websiteBaseUrl: _stringValue(
        json['websiteBaseUrl'],
        defaults.websiteBaseUrl,
      ),
      whatsappCommunityUrl: _stringValue(
        json['whatsappCommunityUrl'],
        defaults.whatsappCommunityUrl,
      ),
      privacyPolicyUrl: _stringValue(
        json['privacyPolicyUrl'],
        defaults.privacyPolicyUrl,
      ),
      termsUrl: _stringValue(json['termsUrl'], defaults.termsUrl),
    );
  }

  Map<String, dynamic> toJson() => {
    'apiBaseUrl': apiBaseUrl,
    'websiteBaseUrl': websiteBaseUrl,
    'whatsappCommunityUrl': whatsappCommunityUrl,
    'privacyPolicyUrl': privacyPolicyUrl,
    'termsUrl': termsUrl,
  };
}

class FrontendAssetResourceConfig {
  final String defaultAvatar;
  final String subscriptionHero;
  final String appLogo;

  const FrontendAssetResourceConfig({
    required this.defaultAvatar,
    required this.subscriptionHero,
    required this.appLogo,
  });

  factory FrontendAssetResourceConfig.defaults() =>
      const FrontendAssetResourceConfig(
        defaultAvatar: 'assets/images/default_avatar.png',
        subscriptionHero: 'assets/images/subscription_hero.png',
        appLogo: 'assets/images/logo.png',
      );

  factory FrontendAssetResourceConfig.fromJson(Map<String, dynamic> json) {
    final defaults = FrontendAssetResourceConfig.defaults();
    return FrontendAssetResourceConfig(
      defaultAvatar: _stringValue(
        json['defaultAvatar'],
        defaults.defaultAvatar,
      ),
      subscriptionHero: _stringValue(
        json['subscriptionHero'],
        defaults.subscriptionHero,
      ),
      appLogo: _stringValue(json['appLogo'], defaults.appLogo),
    );
  }

  Map<String, dynamic> toJson() => {
    'defaultAvatar': defaultAvatar,
    'subscriptionHero': subscriptionHero,
    'appLogo': appLogo,
  };
}

class FrontendFeatureFlagResourceConfig {
  final bool weatherEnabled;
  final bool leaderboardEnabled;
  final bool oneToOneChatEnabled;
  final bool groupAudioCallsEnabled;
  final bool fullStatisticsEnabled;

  const FrontendFeatureFlagResourceConfig({
    required this.weatherEnabled,
    required this.leaderboardEnabled,
    required this.oneToOneChatEnabled,
    required this.groupAudioCallsEnabled,
    required this.fullStatisticsEnabled,
  });

  factory FrontendFeatureFlagResourceConfig.defaults() =>
      const FrontendFeatureFlagResourceConfig(
        weatherEnabled: true,
        leaderboardEnabled: true,
        oneToOneChatEnabled: false,
        groupAudioCallsEnabled: false,
        fullStatisticsEnabled: true,
      );

  factory FrontendFeatureFlagResourceConfig.fromJson(
    Map<String, dynamic> json,
  ) {
    final defaults = FrontendFeatureFlagResourceConfig.defaults();
    return FrontendFeatureFlagResourceConfig(
      weatherEnabled: _boolValue(
        json['weatherEnabled'],
        defaults.weatherEnabled,
      ),
      leaderboardEnabled: _boolValue(
        json['leaderboardEnabled'],
        defaults.leaderboardEnabled,
      ),
      oneToOneChatEnabled: _boolValue(
        json['oneToOneChatEnabled'],
        defaults.oneToOneChatEnabled,
      ),
      groupAudioCallsEnabled: _boolValue(
        json['groupAudioCallsEnabled'],
        defaults.groupAudioCallsEnabled,
      ),
      fullStatisticsEnabled: _boolValue(
        json['fullStatisticsEnabled'],
        defaults.fullStatisticsEnabled,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'weatherEnabled': weatherEnabled,
    'leaderboardEnabled': leaderboardEnabled,
    'oneToOneChatEnabled': oneToOneChatEnabled,
    'groupAudioCallsEnabled': groupAudioCallsEnabled,
    'fullStatisticsEnabled': fullStatisticsEnabled,
  };
}

class FrontendLimitResourceConfig {
  final int freePlanMaxBikes;

  const FrontendLimitResourceConfig({required this.freePlanMaxBikes});

  factory FrontendLimitResourceConfig.defaults() =>
      const FrontendLimitResourceConfig(freePlanMaxBikes: 3);

  factory FrontendLimitResourceConfig.fromJson(Map<String, dynamic> json) {
    final defaults = FrontendLimitResourceConfig.defaults();
    return FrontendLimitResourceConfig(
      freePlanMaxBikes: _intValue(
        json['freePlanMaxBikes'],
        defaults.freePlanMaxBikes,
      ),
    );
  }

  Map<String, dynamic> toJson() => {'freePlanMaxBikes': freePlanMaxBikes};
}

class FrontendNavigationResourceConfig {
  final List<FrontendNavigationTabResource> tabs;
  final FrontendNavigationActionResource actions;

  const FrontendNavigationResourceConfig({
    required this.tabs,
    required this.actions,
  });

  factory FrontendNavigationResourceConfig.defaults() =>
      FrontendNavigationResourceConfig(
        tabs: const [
          FrontendNavigationTabResource(
            id: 'dashboard',
            label: 'Dashboard',
            icon: 'space_dashboard_outlined',
            selectedIcon: 'space_dashboard_rounded',
            enabled: true,
            order: 1,
          ),
          FrontendNavigationTabResource(
            id: 'rides',
            label: 'Rides',
            icon: 'two_wheeler_outlined',
            selectedIcon: 'two_wheeler_rounded',
            enabled: true,
            order: 2,
          ),
          FrontendNavigationTabResource(
            id: 'clubs',
            label: 'Clubs',
            icon: 'groups_2_outlined',
            selectedIcon: 'groups_2_rounded',
            enabled: true,
            order: 3,
          ),
          FrontendNavigationTabResource(
            id: 'friends',
            label: 'Friends',
            icon: 'diversity_3_outlined',
            selectedIcon: 'diversity_3_rounded',
            enabled: true,
            order: 4,
          ),
          FrontendNavigationTabResource(
            id: 'profile',
            label: 'Profile',
            icon: 'person_outline_rounded',
            selectedIcon: 'person_rounded',
            enabled: true,
            order: 5,
          ),
        ],
        actions: const FrontendNavigationActionResource(
          createRideFabEnabled: true,
          createRideFabIcon: 'add_rounded',
        ),
      );

  factory FrontendNavigationResourceConfig.fromJson(Map<String, dynamic> json) {
    final defaults = FrontendNavigationResourceConfig.defaults();
    final tabs = _listValue(json['tabs'])
        .map(
          (item) => FrontendNavigationTabResource.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    tabs.sort((a, b) => a.order.compareTo(b.order));

    return FrontendNavigationResourceConfig(
      tabs: tabs.isEmpty ? defaults.tabs : tabs,
      actions: FrontendNavigationActionResource.fromJson(
        _mapValue(json['actions']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'tabs': tabs.map((tab) => tab.toJson()).toList(growable: false),
    'actions': actions.toJson(),
  };
}

class FrontendNavigationTabResource {
  final String id;
  final String label;
  final String icon;
  final String selectedIcon;
  final bool enabled;
  final int order;

  const FrontendNavigationTabResource({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.enabled,
    required this.order,
  });

  factory FrontendNavigationTabResource.fromJson(Map<String, dynamic> json) {
    return FrontendNavigationTabResource(
      id: _stringValue(json['id'], ''),
      label: _stringValue(json['label'], ''),
      icon: _stringValue(json['icon'], 'help_outline_rounded'),
      selectedIcon: _stringValue(
        json['selectedIcon'],
        _stringValue(json['icon'], 'help_outline_rounded'),
      ),
      enabled: _boolValue(json['enabled'], true),
      order: _intValue(json['order'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'icon': icon,
    'selectedIcon': selectedIcon,
    'enabled': enabled,
    'order': order,
  };
}

class FrontendNavigationActionResource {
  final bool createRideFabEnabled;
  final String createRideFabIcon;

  const FrontendNavigationActionResource({
    required this.createRideFabEnabled,
    required this.createRideFabIcon,
  });

  factory FrontendNavigationActionResource.fromJson(Map<String, dynamic> json) {
    final defaults = FrontendNavigationResourceConfig.defaults().actions;
    return FrontendNavigationActionResource(
      createRideFabEnabled: _boolValue(
        json['createRideFabEnabled'],
        defaults.createRideFabEnabled,
      ),
      createRideFabIcon: _stringValue(
        json['createRideFabIcon'],
        defaults.createRideFabIcon,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'createRideFabEnabled': createRideFabEnabled,
    'createRideFabIcon': createRideFabIcon,
  };
}

class FrontendSubscriptionResourceConfig {
  final String currencyCode;
  final String currencySymbol;
  final String title;
  final String description;
  final String cancelAnytimeText;
  final String allPlansIncludeText;
  final String bikeUpsellTitle;
  final String bikeUpsellDescription;
  final String bikeLimitDialogTitle;
  final String bikeLimitDialogMessage;
  final List<SubscriptionPlanResource> plans;

  const FrontendSubscriptionResourceConfig({
    required this.currencyCode,
    required this.currencySymbol,
    required this.title,
    required this.description,
    required this.cancelAnytimeText,
    required this.allPlansIncludeText,
    required this.bikeUpsellTitle,
    required this.bikeUpsellDescription,
    required this.bikeLimitDialogTitle,
    required this.bikeLimitDialogMessage,
    required this.plans,
  });

  factory FrontendSubscriptionResourceConfig.defaults() =>
      FrontendSubscriptionResourceConfig(
        currencyCode: 'INR',
        currencySymbol: 'Rs',
        title: 'Throttle Membership',
        description:
            'Choose a plan that unlocks more riding utility, better alerts, and deeper stats.',
        cancelAnytimeText: 'Cancel anytime. No questions asked.',
        allPlansIncludeText:
            'All plans include access to core riding features.',
        bikeUpsellTitle: 'Need More Bike Slots?',
        bikeUpsellDescription:
            'Free riders can keep up to {limit} bikes. Upgrade for more bike slots, or remove an existing bike to add another one.',
        bikeLimitDialogTitle: 'Bike limit reached',
        bikeLimitDialogMessage:
            'You can keep up to {limit} bikes on the free plan. Remove an existing bike or upgrade your subscription to add more.',
        plans: const [
          SubscriptionPlanResource(
            id: 'free',
            name: 'Free',
            period: 'per month',
            priceInr: 0,
            ctaLabel: 'Current Plan',
            features: [
              'Up to 3 bikes',
              'Core ride planning',
              'Basic group ride participation',
            ],
            entitlements: SubscriptionEntitlementResource(
              maxBikes: 3,
              weatherAccess: false,
              smsAlerts: false,
              emailAlerts: false,
              whatsappAlerts: false,
              oneToOneChat: false,
              groupAudioCalls: false,
              fullStatistics: false,
              leaderboard: false,
            ),
          ),
          SubscriptionPlanResource(
            id: 'rider_plus',
            name: 'Rider Plus',
            period: 'per month',
            priceInr: 499,
            popular: true,
            ctaLabel: 'Upgrade Now',
            features: [
              'Add more than 3 bikes',
              'Weather data',
              'Email and WhatsApp alerts',
              'One-to-one chat',
              'Full statistics',
              'Ranking access',
            ],
            entitlements: SubscriptionEntitlementResource(
              maxBikes: 10,
              weatherAccess: true,
              smsAlerts: false,
              emailAlerts: true,
              whatsappAlerts: true,
              oneToOneChat: true,
              groupAudioCalls: false,
              fullStatistics: true,
              leaderboard: true,
            ),
          ),
          SubscriptionPlanResource(
            id: 'pro_club',
            name: 'Pro Club',
            period: 'per month',
            priceInr: 599,
            originalPriceInr: 799,
            ctaLabel: 'Go Pro',
            features: [
              'Unlimited bike slots',
              'Weather data',
              'SMS, email, and WhatsApp alerts',
              'One-to-one chat',
              'Optional group audio calls',
              'Full statistics',
              'Ranking and leaderboard features',
            ],
            entitlements: SubscriptionEntitlementResource(
              maxBikes: -1,
              weatherAccess: true,
              smsAlerts: true,
              emailAlerts: true,
              whatsappAlerts: true,
              oneToOneChat: true,
              groupAudioCalls: true,
              fullStatistics: true,
              leaderboard: true,
            ),
          ),
        ],
      );

  factory FrontendSubscriptionResourceConfig.fromJson(
    Map<String, dynamic> json,
  ) {
    final defaults = FrontendSubscriptionResourceConfig.defaults();
    final plans = _listValue(json['plans'])
        .map(
          (item) => SubscriptionPlanResource.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    return FrontendSubscriptionResourceConfig(
      currencyCode: _stringValue(json['currencyCode'], defaults.currencyCode),
      currencySymbol: _stringValue(
        json['currencySymbol'],
        defaults.currencySymbol,
      ),
      title: _stringValue(json['title'], defaults.title),
      description: _stringValue(json['description'], defaults.description),
      cancelAnytimeText: _stringValue(
        json['cancelAnytimeText'],
        defaults.cancelAnytimeText,
      ),
      allPlansIncludeText: _stringValue(
        json['allPlansIncludeText'],
        defaults.allPlansIncludeText,
      ),
      bikeUpsellTitle: _stringValue(
        json['bikeUpsellTitle'],
        defaults.bikeUpsellTitle,
      ),
      bikeUpsellDescription: _stringValue(
        json['bikeUpsellDescription'],
        defaults.bikeUpsellDescription,
      ),
      bikeLimitDialogTitle: _stringValue(
        json['bikeLimitDialogTitle'],
        defaults.bikeLimitDialogTitle,
      ),
      bikeLimitDialogMessage: _stringValue(
        json['bikeLimitDialogMessage'],
        defaults.bikeLimitDialogMessage,
      ),
      plans: plans.isEmpty ? defaults.plans : plans,
    );
  }

  Map<String, dynamic> toJson() => {
    'currencyCode': currencyCode,
    'currencySymbol': currencySymbol,
    'title': title,
    'description': description,
    'cancelAnytimeText': cancelAnytimeText,
    'allPlansIncludeText': allPlansIncludeText,
    'bikeUpsellTitle': bikeUpsellTitle,
    'bikeUpsellDescription': bikeUpsellDescription,
    'bikeLimitDialogTitle': bikeLimitDialogTitle,
    'bikeLimitDialogMessage': bikeLimitDialogMessage,
    'plans': plans.map((plan) => plan.toJson()).toList(growable: false),
  };

  String formatPrice(int priceInr) {
    if (priceInr <= 0) {
      return 'Free';
    }
    return '$currencySymbol $priceInr';
  }

  String formatLimitText(String template, int limit) {
    return template.replaceAll('{limit}', '$limit');
  }
}

class SubscriptionPlanResource {
  final String id;
  final String name;
  final String period;
  final int priceInr;
  final int? originalPriceInr;
  final bool popular;
  final String ctaLabel;
  final List<String> features;
  final SubscriptionEntitlementResource entitlements;

  const SubscriptionPlanResource({
    required this.id,
    required this.name,
    required this.period,
    required this.priceInr,
    this.originalPriceInr,
    this.popular = false,
    required this.ctaLabel,
    required this.features,
    required this.entitlements,
  });

  factory SubscriptionPlanResource.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanResource(
      id: _stringValue(json['id'], ''),
      name: _stringValue(json['name'], ''),
      period: _stringValue(json['period'], ''),
      priceInr: _intValue(json['priceInr'], 0),
      originalPriceInr: json['originalPriceInr'] == null
          ? null
          : _intValue(json['originalPriceInr'], 0),
      popular: _boolValue(json['popular'], false),
      ctaLabel: _stringValue(json['ctaLabel'], 'Subscribe Now'),
      features: _listValue(json['features']).map((item) => '$item').toList(),
      entitlements: SubscriptionEntitlementResource.fromJson(
        _mapValue(json['entitlements']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'period': period,
    'priceInr': priceInr,
    if (originalPriceInr != null) 'originalPriceInr': originalPriceInr,
    'popular': popular,
    'ctaLabel': ctaLabel,
    'features': features,
    'entitlements': entitlements.toJson(),
  };
}

class SubscriptionEntitlementResource {
  final int maxBikes;
  final bool weatherAccess;
  final bool smsAlerts;
  final bool emailAlerts;
  final bool whatsappAlerts;
  final bool oneToOneChat;
  final bool groupAudioCalls;
  final bool fullStatistics;
  final bool leaderboard;

  const SubscriptionEntitlementResource({
    required this.maxBikes,
    required this.weatherAccess,
    required this.smsAlerts,
    required this.emailAlerts,
    required this.whatsappAlerts,
    required this.oneToOneChat,
    required this.groupAudioCalls,
    required this.fullStatistics,
    required this.leaderboard,
  });

  factory SubscriptionEntitlementResource.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntitlementResource(
      maxBikes: _intValue(json['maxBikes'], 3),
      weatherAccess: _boolValue(json['weatherAccess'], false),
      smsAlerts: _boolValue(json['smsAlerts'], false),
      emailAlerts: _boolValue(json['emailAlerts'], false),
      whatsappAlerts: _boolValue(json['whatsappAlerts'], false),
      oneToOneChat: _boolValue(json['oneToOneChat'], false),
      groupAudioCalls: _boolValue(json['groupAudioCalls'], false),
      fullStatistics: _boolValue(json['fullStatistics'], false),
      leaderboard: _boolValue(json['leaderboard'], false),
    );
  }

  Map<String, dynamic> toJson() => {
    'maxBikes': maxBikes,
    'weatherAccess': weatherAccess,
    'smsAlerts': smsAlerts,
    'emailAlerts': emailAlerts,
    'whatsappAlerts': whatsappAlerts,
    'oneToOneChat': oneToOneChat,
    'groupAudioCalls': groupAudioCalls,
    'fullStatistics': fullStatistics,
    'leaderboard': leaderboard,
  };
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

List<dynamic> _listValue(dynamic value) {
  if (value is List) {
    return value;
  }
  return const [];
}

String _stringValue(dynamic value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

int _intValue(dynamic value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(dynamic value, bool fallback) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}
