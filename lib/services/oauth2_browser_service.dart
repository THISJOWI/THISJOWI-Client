import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuth2BrowserService {
  /// Opens [authUrl] in the system browser and waits for the callback
  /// to arrive via the custom URL scheme defined in [expectedScheme].
  ///
  /// Uses app_links uriLinkStream to capture the deep link. The first
  /// listener on the stream automatically receives any pending initial
  /// link, so getInitialLink() is not needed.
  static Future<Uri> authenticate({
    required Uri authUrl,
    String expectedScheme = 'thisjowi',
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final appLinks = AppLinks();
    final completer = Completer<Uri>();

    final sub = appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == expectedScheme && !completer.isCompleted) {
        completer.complete(uri);
      }
    });

    final launched = await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    if (!launched) {
      await sub.cancel();
      throw Exception('No se pudo abrir el navegador');
    }

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }
}
