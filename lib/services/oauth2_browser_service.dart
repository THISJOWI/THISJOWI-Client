import 'dart:async';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:thisjowi/utils/app_logger.dart';

class OAuth2BrowserService {
  /// Opens [authUrl] in an in-app browser modal and waits for the callback
  /// to arrive via the custom URL scheme defined in [expectedScheme].
  ///
  /// Uses ASWebAuthenticationSession on iOS/macOS and Chrome Custom Tabs
  /// on Android — no app switching or deep link interception needed.
  static Future<Uri> authenticate({
    required Uri authUrl,
    String expectedScheme = 'thisjowi',
    Duration timeout = const Duration(seconds: 90),
  }) async {
    appLog.i('OAuth2BrowserService: opening auth modal: $authUrl');

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: expectedScheme,
      ).timeout(timeout);

      appLog.i('OAuth2BrowserService: callback received: $result');
      return Uri.parse(result);
    } on TimeoutException {
      appLog.w('OAuth2BrowserService: timeout waiting for callback');
      rethrow;
    } catch (e) {
      appLog.w('OAuth2BrowserService: auth error: $e');
      rethrow;
    }
  }
}
