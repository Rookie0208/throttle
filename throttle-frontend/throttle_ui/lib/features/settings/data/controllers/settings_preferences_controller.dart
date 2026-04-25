import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPreferencesController extends ChangeNotifier {
  SettingsPreferencesController._();

  static final SettingsPreferencesController instance =
      SettingsPreferencesController._();

  static const _notificationsEnabledKey = 'settings_notifications_enabled';
  static const _rideAlertsKey = 'settings_ride_alerts';
  static const _friendRequestAlertsKey = 'settings_friend_request_alerts';
  static const _marketingAlertsKey = 'settings_marketing_alerts';

  static const _messageRequestsKey = 'settings_message_requests';
  static const _messagePreviewsKey = 'settings_message_previews';
  static const _readReceiptsKey = 'settings_read_receipts';

  static const _privateProfileKey = 'settings_private_profile';
  static const _discoverableProfileKey = 'settings_discoverable_profile';
  static const _shareRideActivityKey = 'settings_share_ride_activity';
  static const _showRideStatsKey = 'settings_show_ride_stats';

  bool _loaded = false;

  bool _notificationsEnabled = true;
  bool _rideAlerts = true;
  bool _friendRequestAlerts = true;
  bool _marketingAlerts = false;

  bool _allowMessageRequests = true;
  bool _showMessagePreviews = true;
  bool _sendReadReceipts = true;

  bool _privateProfile = false;
  bool _discoverableProfile = true;
  bool _shareRideActivity = true;
  bool _showRideStats = true;

  bool get isLoaded => _loaded;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get rideAlerts => _rideAlerts;
  bool get friendRequestAlerts => _friendRequestAlerts;
  bool get marketingAlerts => _marketingAlerts;

  bool get allowMessageRequests => _allowMessageRequests;
  bool get showMessagePreviews => _showMessagePreviews;
  bool get sendReadReceipts => _sendReadReceipts;

  bool get privateProfile => _privateProfile;
  bool get discoverableProfile => _discoverableProfile;
  bool get shareRideActivity => _shareRideActivity;
  bool get showRideStats => _showRideStats;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _rideAlerts = prefs.getBool(_rideAlertsKey) ?? true;
    _friendRequestAlerts = prefs.getBool(_friendRequestAlertsKey) ?? true;
    _marketingAlerts = prefs.getBool(_marketingAlertsKey) ?? false;

    _allowMessageRequests = prefs.getBool(_messageRequestsKey) ?? true;
    _showMessagePreviews = prefs.getBool(_messagePreviewsKey) ?? true;
    _sendReadReceipts = prefs.getBool(_readReceiptsKey) ?? true;

    _privateProfile = prefs.getBool(_privateProfileKey) ?? false;
    _discoverableProfile = prefs.getBool(_discoverableProfileKey) ?? true;
    _shareRideActivity = prefs.getBool(_shareRideActivityKey) ?? true;
    _showRideStats = prefs.getBool(_showRideStatsKey) ?? true;

    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setRideAlerts(bool value) async {
    _rideAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rideAlertsKey, value);
    notifyListeners();
  }

  Future<void> setFriendRequestAlerts(bool value) async {
    _friendRequestAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_friendRequestAlertsKey, value);
    notifyListeners();
  }

  Future<void> setMarketingAlerts(bool value) async {
    _marketingAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marketingAlertsKey, value);
    notifyListeners();
  }

  Future<void> setAllowMessageRequests(bool value) async {
    _allowMessageRequests = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_messageRequestsKey, value);
    notifyListeners();
  }

  Future<void> setShowMessagePreviews(bool value) async {
    _showMessagePreviews = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_messagePreviewsKey, value);
    notifyListeners();
  }

  Future<void> setSendReadReceipts(bool value) async {
    _sendReadReceipts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readReceiptsKey, value);
    notifyListeners();
  }

  Future<void> setPrivateProfile(bool value) async {
    _privateProfile = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privateProfileKey, value);
    notifyListeners();
  }

  Future<void> setDiscoverableProfile(bool value) async {
    _discoverableProfile = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_discoverableProfileKey, value);
    notifyListeners();
  }

  Future<void> setShareRideActivity(bool value) async {
    _shareRideActivity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareRideActivityKey, value);
    notifyListeners();
  }

  Future<void> setShowRideStats(bool value) async {
    _showRideStats = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showRideStatsKey, value);
    notifyListeners();
  }
}
