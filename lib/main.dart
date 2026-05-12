import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_extension.dart' show Translations, I18n;
import 'package:provider/provider.dart';
import 'package:thisjowi/core/app_theme.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/env_loader.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/screens/auth/login.dart';
import 'package:thisjowi/screens/auth/register.dart';
import 'package:thisjowi/screens/auth/authSelection.dart';
import 'package:thisjowi/screens/auth/ldapLogin.dart';
import 'package:thisjowi/screens/auth/samlLogin.dart';
import 'package:thisjowi/screens/otp/OtpQrScannerScreen.dart';
import 'package:thisjowi/screens/splash/splash.dart';
import 'package:thisjowi/screens/onboarding/onBoarding.dart';
import 'package:thisjowi/components/privacy_overlay.dart';
import 'package:thisjowi/utils/app_logger.dart';

// Workaround for macOS keyboard event bug
// See: https://github.com/flutter/flutter/issues/148604
class KeyboardEventFix extends StatefulWidget {
  final Widget child;
  const KeyboardEventFix({super.key, required this.child});

  @override
  State<KeyboardEventFix> createState() => _KeyboardEventFixState();
}

class _KeyboardEventFixState extends State<KeyboardEventFix> {
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    // Note: HardwareKeyboard.clearState() is not public API
    // The fix works by intercepting duplicate key events in _handleKeyEvent
  }

  @override
  void dispose() {
    _pressedKeys.clear();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_pressedKeys.contains(event.logicalKey)) {
        // Key was already pressed, ignore duplicate
        return KeyEventResult.handled;
      }
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    } else if (event is KeyRepeatEvent) {
      if (!_pressedKeys.contains(event.logicalKey)) {
        // Repeat event without prior down event
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      canRequestFocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: widget.child,
    );
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar sistema de logging
  await AppLogger.initialize();
  appLog.i('🚀 App starting...');

  // Silenciar callbacks de traducciones faltantes
  // Estas configs deben estar ANTES de que se carguen las traducciones
  Translations.missingKeyCallback = (key, locale) {};
  Translations.missingTranslationCallback = ({required key, required locale, required translations, required supportedLocales}) => false;

  await EnvLoader.load();
  await ApiConfig.init();

  ApiConfig.printConfig();

  appLog.i('✅ App initialized successfully');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OtpProvider()),
      ],
      child: KeyboardEventFix(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "ThisJowi",
        
        // Localization support
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          // Si el idioma del dispositivo es español (cualquier variante), usar 'es'
          if (locale != null && locale.languageCode == 'es') {
            return const Locale('es');
          }
          // Por defecto, usar inglés
          return const Locale('en');
        },
        builder: (context, child) => PrivacyOverlay(
          child: I18n(
            initialLocale: const Locale('en'),
            child: child!
          ),
        ),
        
        themeMode: ThemeMode.system,
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
      routes: {
        '/authSelection': (context) => const AuthSelectionScreen(),
        '/ldapLogin': (context) => const LdapLoginScreen(),
        '/samlLogin': (context) => const SamlLoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/otp/qrscan': (context) => const OtpQrScannerScreen(),
      },
      home: const SplashScreen(),
      ),
      ),
    );
  }
}
