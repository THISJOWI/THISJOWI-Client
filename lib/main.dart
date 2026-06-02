import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_extension.dart' show Translations, I18n;
import 'package:provider/provider.dart';
import 'package:thisjowi/core/app_theme.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/env_loader.dart';
import 'package:thisjowi/core/theme_provider.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/screens/auth/login.dart';
import 'package:thisjowi/screens/auth/register.dart';
import 'package:thisjowi/screens/auth/authSelection.dart';
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

class _SystemUIUpdater extends StatelessWidget {
  final Widget child;
  const _SystemUIUpdater({required this.child});

  @override
  Widget build(BuildContext context) {
    context.read<ThemeProvider>().updateSystemUI(context);
    return child;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OtpProvider()),
      ],
      child: KeyboardEventFix(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return I18n(
              child: _AppCore(themeProvider: themeProvider),
            );
          },
        ),
      ),
    );
  }
}

class _AppCore extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _AppCore({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return _SystemUIUpdater(
      child: MaterialApp(
        locale: I18n.locale,
        debugShowCheckedModeBanner: false,
        title: "THISECURE",
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
        ],
        builder: (context, child) => PrivacyOverlay(child: child!),
        themeMode: themeProvider.flutterThemeMode,
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        routes: {
          '/authSelection': (context) => const AuthSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/otp/qrscan': (context) => const OtpQrScannerScreen(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
