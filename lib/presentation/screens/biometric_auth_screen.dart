import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:thisjowi/core/app_theme.dart';

// Tipos de biometría
enum BiometricType { face, fingerprint, both }

// Estados de autenticación biométrica
class BiometricAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final BiometricType biometricType;

  const BiometricAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.biometricType = BiometricType.face,
  });

  BiometricAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    BiometricType? biometricType,
  }) {
    return BiometricAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      biometricType: biometricType ?? this.biometricType,
    );
  }
}

// ChangeNotifier para la autenticación biométrica
class BiometricAuthNotifier extends ChangeNotifier {
  BiometricAuthState _state = const BiometricAuthState();

  BiometricAuthState get state => _state;

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> initializeBiometrics() async {
    try {
      final canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;

      if (!canAuthenticateWithBiometrics) {
        _state = _state.copyWith(
          error: 'Biometric authentication not available',
        );
        notifyListeners();
        return;
      }

      final availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      BiometricType detectedType = BiometricType.face;
      final availableBiometricsStr =
          availableBiometrics.map((b) => b.toString()).toList();
      final hasFace =
          availableBiometricsStr.any((b) => b.contains('face'));
      final hasFingerprint =
          availableBiometricsStr.any((b) => b.contains('fingerprint'));

      if (hasFace && hasFingerprint) {
        detectedType = BiometricType.both;
      } else if (hasFingerprint) {
        detectedType = BiometricType.fingerprint;
      }

      _state = _state.copyWith(biometricType: detectedType);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to initialize biometrics');
      notifyListeners();
    }
  }

  Future<void> authenticate() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
      );

      _state = _state.copyWith(
        isAuthenticated: isAuthenticated,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Authentication failed: ${e.toString()}',
      );
      notifyListeners();
    }
  }
}

// Pantalla de autenticación biométrica
class BiometricAuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricAuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializar animación de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Inicializar biometría
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BiometricAuthNotifier>().initializeBiometrics();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BiometricAuthNotifier>(
        builder: (context, authNotifier, _) {
          final authState = authNotifier.state;
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          // Escuchar cambios en la autenticación
          if (authState.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onAuthenticated();
            });
          }

          return Stack(
            children: [
              // Fondo borroso con degradado
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            Theme.of(context).scaffoldBackgroundColor,
                            Theme.of(context).cardColor.withAlpha(200),
                          ]
                        : [
                            AppTheme.lightBackground,
                            AppTheme.lightCardBg,
                          ],
                  ),
                ),
              ),

              // Efecto de blur al fondo (simulado con BackdropFilter)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: isDarkMode
                      ? (Theme.of(context).brightness == Brightness.light ? Colors.white.withAlpha(180) : Colors.black.withAlpha(40))
                      : Theme.of(context).colorScheme.onSurface.withAlpha(20),
                ),
              ),

              // Contenido centrado
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ícono biométrico animado con pulso
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: authState.isLoading
                                  ? _pulseAnimation.value
                                  : 1.0,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withAlpha(200),
                                      Theme.of(context).colorScheme.tertiary.withAlpha(150),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    authState.biometricType ==
                                            BiometricType.fingerprint
                                        ? Icons.fingerprint
                                        : Icons.face,
                                    size: 80,
                                    color: isDarkMode
                                        ? Theme.of(context).scaffoldBackgroundColor
                                        : AppTheme.lightBackground,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 48),

                        // Texto principal
                        Text(
                          'Biometric Authentication',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // Texto secundario
                        Text(
                          authState.biometricType ==
                                  BiometricType.fingerprint
                              ? 'Place your finger on the sensor'
                              : authState.biometricType == BiometricType.both
                                  ? 'Use your face or fingerprint to authenticate'
                                  : 'Face the camera to authenticate',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Theme.of(context).colorScheme.onSurface.withAlpha(180)
                                    : AppTheme.lightText.withAlpha(180),
                                fontWeight: FontWeight.w400,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Botón de autenticación
                        if (!authState.isAuthenticated)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: authState.isLoading
                                  ? null
                                  : () async {
                                      await authNotifier.authenticate();
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.tertiary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withAlpha(100),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Authenticate',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withAlpha(200),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(100),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Authenticated',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Mensaje de error (si aplica)
                        if (authState.error != null &&
                            !authState.isAuthenticated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error.withAlpha(100),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error.withAlpha(200),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              authState.error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
