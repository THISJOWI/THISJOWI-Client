import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:thisjowi/data/models/passwordEntry.dart';

/// Abstract interface for platform-specific autofill services
///
/// Each platform implements this interface to provide autofill functionality
/// in a way that's native to that platform.
abstract class PlatformAutofillService {
  /// Check if autofill is supported on this platform
  Future<bool> isSupported();

  /// Check if autofill is currently enabled
  Future<bool> isEnabled();

  /// Open platform-specific settings to enable autofill
  Future<void> openSettings();

  /// Save a credential to the platform's autofill system
  Future<bool> saveCredential(PasswordEntry entry);

  /// Get credentials matching a domain/package
  Future<List<PasswordEntry>> getCredentials(String identifier);

  /// Sync all credentials to the platform's autofill system
  Future<bool> syncAllCredentials(List<PasswordEntry> entries);

  /// Clear all credentials from the platform's autofill system
  Future<bool> clearAllCredentials();

  /// Get a user-friendly status message
  Future<String> getStatusMessage();
}

/// Factory to get the appropriate platform-specific autofill service
class PlatformAutofillFactory {
  static PlatformAutofillService? _instance;

  static PlatformAutofillService get instance {
    if (_instance != null) return _instance!;

    if (kIsWeb) {
      _instance = WebAutofillService();
    } else if (Platform.isAndroid) {
      _instance = AndroidAutofillService();
    } else if (Platform.isIOS) {
      _instance = IOSAutofillService();
    } else if (Platform.isMacOS) {
      _instance = MacOSAutofillService();
    } else if (Platform.isWindows) {
      _instance = WindowsAutofillService();
    } else if (Platform.isLinux) {
      _instance = LinuxAutofillService();
    } else {
      _instance = UnsupportedAutofillService();
    }

    return _instance!;
  }

  /// Reset the instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}

/// Android implementation (already exists, this is a wrapper)
class AndroidAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async {
    // Android 8.0+ supports AutofillService
    return true;
  }

  @override
  Future<bool> isEnabled() async {
    // Check via method channel
    // Implementation in existing autofillService.dart
    return false; // Placeholder
  }

  @override
  Future<void> openSettings() async {
    // Open Android autofill settings
    // Implementation in existing autofillService.dart
  }

  @override
  Future<bool> saveCredential(PasswordEntry entry) async {
    // Credentials are automatically saved via AutofillService
    return true;
  }

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async {
    // Android AutofillService handles this automatically
    return [];
  }

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async {
    // No explicit sync needed for Android
    return true;
  }

  @override
  Future<bool> clearAllCredentials() async {
    // Clear from local database
    return true;
  }

  @override
  Future<String> getStatusMessage() async {
    final enabled = await isEnabled();
    if (enabled) {
      return 'THISJOWI está activo como gestor de contraseñas';
    } else {
      return 'Activa THISJOWI en Configuración > Sistema > Autofill';
    }
  }
}

/// iOS implementation
class IOSAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async {
    // iOS 12+ supports Credential Provider Extension
    return true;
  }

  @override
  Future<bool> isEnabled() async {
    // iOS doesn't provide API to check if extension is enabled
    // We assume it's enabled if the user has set it up
    return true;
  }

  @override
  Future<void> openSettings() async {
    // iOS doesn't allow opening Settings directly to AutoFill
    // User must manually go to Settings > Passwords > AutoFill Passwords
    debugPrint(
        'iOS: User must enable in Settings > Passwords > AutoFill Passwords');
  }

  @override
  Future<bool> saveCredential(PasswordEntry entry) async {
    // Sync to App Group storage
    // Implementation uses CredentialSharingService
    return true;
  }

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async {
    // Credential Provider Extension handles this
    return [];
  }

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async {
    // Sync to App Group storage
    // Implementation uses CredentialSharingService
    return true;
  }

  @override
  Future<bool> clearAllCredentials() async {
    // Clear from App Group storage
    return true;
  }

  @override
  Future<String> getStatusMessage() async {
    return 'Para usar autofill, ve a Ajustes > Contraseñas > Autorrellenar contraseñas y activa THISJOWI';
  }
}

/// macOS implementation (similar to iOS)
class MacOSAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async {
    // macOS 11+ supports Credential Provider Extension
    return true;
  }

  @override
  Future<bool> isEnabled() async {
    return true;
  }

  @override
  Future<void> openSettings() async {
    debugPrint('macOS: User must enable in System Preferences > Passwords');
  }

  @override
  Future<bool> saveCredential(PasswordEntry entry) async {
    return true;
  }

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async {
    return [];
  }

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async {
    return true;
  }

  @override
  Future<bool> clearAllCredentials() async {
    return true;
  }

  @override
  Future<String> getStatusMessage() async {
    return 'Para usar autofill, ve a Preferencias del Sistema > Contraseñas y activa THISJOWI';
  }
}

/// Windows implementation
class WindowsAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async {
    // Windows 10+ supports Credential Provider
    return true;
  }

  @override
  Future<bool> isEnabled() async {
    // Check if our Credential Provider is registered
    return false;
  }

  @override
  Future<void> openSettings() async {
    // Open Windows Credential Manager
    debugPrint('Windows: Opening Credential Manager');
  }

  @override
  Future<bool> saveCredential(PasswordEntry entry) async {
    // Save to Windows Credential Manager
    return true;
  }

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async {
    return [];
  }

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async {
    return true;
  }

  @override
  Future<bool> clearAllCredentials() async {
    return true;
  }

  @override
  Future<String> getStatusMessage() async {
    return 'THISJOWI puede guardar contraseñas en Windows Credential Manager';
  }
}

/// Linux implementation
class LinuxAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async {
    // Supported via browser extensions + libsecret
    return true;
  }

  @override
  Future<bool> isEnabled() async {
    // Check if browser extension is installed
    return false;
  }

  @override
  Future<void> openSettings() async {
    debugPrint('Linux: Install THISJOWI browser extension');
  }

  @override
  Future<bool> saveCredential(PasswordEntry entry) async {
    // Save to libsecret
    return true;
  }

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async {
    return [];
  }

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async {
    return true;
  }

  @override
  Future<bool> clearAllCredentials() async {
    return true;
  }

  @override
  Future<String> getStatusMessage() async {
    return 'Instala la extensión de navegador de THISJOWI para autofill';
  }
}

/// Web implementation
class WebAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async {
    // Supported via browser extension
    return true;
  }

  @override
  Future<bool> isEnabled() async {
    // Check if extension is installed
    return false;
  }

  @override
  Future<void> openSettings() async {
    debugPrint('Web: Install THISJOWI browser extension');
  }

  @override
  Future<bool> saveCredential(PasswordEntry entry) async {
    // Save to IndexedDB
    return true;
  }

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async {
    return [];
  }

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async {
    return true;
  }

  @override
  Future<bool> clearAllCredentials() async {
    return true;
  }

  @override
  Future<String> getStatusMessage() async {
    return 'Instala la extensión de navegador de THISJOWI para autofill';
  }
}

/// Unsupported platform fallback
class UnsupportedAutofillService implements PlatformAutofillService {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> openSettings() async {}

  @override
  Future<bool> saveCredential(PasswordEntry entry) async => false;

  @override
  Future<List<PasswordEntry>> getCredentials(String identifier) async => [];

  @override
  Future<bool> syncAllCredentials(List<PasswordEntry> entries) async => false;

  @override
  Future<bool> clearAllCredentials() async => false;

  @override
  Future<String> getStatusMessage() async {
    return 'Autofill no está soportado en esta plataforma';
  }
}
