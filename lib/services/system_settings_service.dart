import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'autofillService.dart' show AutofillService;

enum PermissionState { granted, denied, unknown }

class SystemInfo {
  final String platform;
  final String osVersion;
  final bool isMobile;
  final bool isDesktop;
  final bool autofillSupported;
  final bool autofillEnabled;
  final bool biometricAvailable;
  final PermissionState notificationPermission;

  SystemInfo({
    required this.platform,
    required this.osVersion,
    required this.isMobile,
    required this.isDesktop,
    required this.autofillSupported,
    required this.autofillEnabled,
    required this.biometricAvailable,
    required this.notificationPermission,
  });
}

class SystemSettingsService {
  static final SystemSettingsService _instance = SystemSettingsService._internal();
  static const MethodChannel _channel = MethodChannel('com.thisjowi/system');

  factory SystemSettingsService() => _instance;
  SystemSettingsService._internal();

  final AutofillService _autofillService = AutofillService();

  Future<SystemInfo> getSystemInfo() async {
    final platform = _getPlatformName();
    final osVersion = await _getOsVersion();
    final isMobile = _isMobile();
    final isDesktop = _isDesktop();

    final autofillSupported = await _autofillService.hasAutofillSupport();
    final autofillEnabled = await _autofillService.isAutofillServiceEnabled();
    final biometricAvailable = await _biometricAvailable();
    final notificationPermission = await _getNotificationPermission();

    return SystemInfo(
      platform: platform,
      osVersion: osVersion,
      isMobile: isMobile,
      isDesktop: isDesktop,
      autofillSupported: autofillSupported,
      autofillEnabled: autofillEnabled,
      biometricAvailable: biometricAvailable,
      notificationPermission: notificationPermission,
    );
  }

  Future<void> openAppSystemSettings() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openAppSettings');
      } catch (e) {
        debugPrint('Error opening Android app settings: $e');
      }
    } else if (Platform.isIOS) {
      await _openUrl('app-settings:');
    } else if (Platform.isMacOS) {
      await _openUrl('x-apple.systempreferences:');
    } else if (Platform.isWindows) {
      await _openUrl('ms-settings:appsfeatures-app');
    } else if (Platform.isLinux) {
      try {
        await _channel.invokeMethod('openAppSettings');
      } catch (e) {
        debugPrint('Error opening Linux settings: $e');
      }
    }
  }

  Future<void> openAutofillSettings() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _autofillService.openAutofillSettings();
    } else if (Platform.isMacOS) {
      await _openUrl('x-apple.systempreferences:com.apple.Passwords-Settings.extension');
    } else if (Platform.isWindows) {
      await _openUrl('ms-settings:signinoptions');
    } else if (Platform.isLinux) {
      debugPrint('Linux: Install browser extension for autofill');
    }
  }

  Future<void> openNotificationSettings() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openNotificationSettings');
      } catch (e) {
        debugPrint('Error opening notification settings: $e');
      }
    } else if (Platform.isIOS) {
      await _openUrl('app-settings:');
    } else if (Platform.isMacOS) {
      await _openUrl('x-apple.systempreferences:com.apple.preference.notifications');
    } else if (Platform.isWindows) {
      await _openUrl('ms-settings:notifications');
    } else if (Platform.isLinux) {
      debugPrint('Linux: Notification settings vary by desktop environment');
    }
  }

  Future<PermissionState> _getNotificationPermission() async {
    if (kIsWeb) return PermissionState.unknown;

    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<int>('getNotificationPermission');
        if (result == null) return PermissionState.unknown;
        return result == 1 ? PermissionState.granted : PermissionState.denied;
      } else if (Platform.isIOS || Platform.isMacOS) {
        return PermissionState.unknown;
      } else if (Platform.isWindows) {
        return PermissionState.unknown;
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
    return PermissionState.unknown;
  }

  Future<bool> _biometricAvailable() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid || Platform.isIOS) {
      final result = await _channel.invokeMethod<bool>('isBiometricAvailable');
      return result ?? false;
    }
    if (Platform.isMacOS) return true;
    if (Platform.isWindows) {
      try {
        final result = await _channel.invokeMethod<bool>('isBiometricAvailable');
        return result ?? false;
      } catch (_) {}
    }
    return false;
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  Future<String> _getOsVersion() async {
    if (kIsWeb) return '';
    try {
      final version = await _channel.invokeMethod<String>('getOsVersion');
      return version ?? '';
    } catch (e) {
      return '';
    }
  }

  bool _isMobile() => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool _isDesktop() => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error opening URL $url: $e');
    }
  }
}
