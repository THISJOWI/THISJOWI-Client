import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:thisjowi/core/app_theme.dart';

enum BiometricType { face, fingerprint, both }

class BiometricState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitializing;
  final String? error;
  final BiometricType biometricType;

  const BiometricState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
    this.biometricType = BiometricType.face,
  });

  BiometricState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    BiometricType? biometricType,
  }) {
    return BiometricState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      biometricType: biometricType ?? this.biometricType,
    );
  }
}

class BiometricNotifier extends ChangeNotifier {
  BiometricState _state = const BiometricState();
  BiometricState get state => _state;

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> initialize() async {
    try {
      final canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;

      if (!canAuthenticateWithBiometrics) {
        _state = _state.copyWith(
          isInitializing: false,
          error: 'Biometric not available',
        );
        notifyListeners();
        return;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final bioStr = availableBiometrics.map((b) => b.toString()).toList();

      final hasFace = bioStr.any((b) => b.contains('face'));
      final hasFingerprint = bioStr.any((b) => b.contains('fingerprint'));

      BiometricType detectedType = BiometricType.face;
      if (hasFace && hasFingerprint) {
        detectedType = BiometricType.both;
      } else if (hasFingerprint) {
        detectedType = BiometricType.fingerprint;
      }

      _state = _state.copyWith(
        isInitializing: false,
        biometricType: detectedType,
      );
      notifyListeners();

      // Auto-authenticate después de inicializar
      await Future.delayed(const Duration(milliseconds: 800));
      await authenticate();
    } catch (e) {
      _state = _state.copyWith(
        isInitializing: false,
        error: 'Failed to initialize',
      );
      notifyListeners();
    }
  }

  Future<void> authenticate() async {
    if (_state.isAuthenticated || _state.isLoading) return;

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: _getLocalizedReason(),
      );

      _state = _state.copyWith(
        isAuthenticated: isAuthenticated,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Authentication failed',
      );
      notifyListeners();
    }
  }

  String _getLocalizedReason() {
    switch (_state.biometricType) {
      case BiometricType.fingerprint:
        return 'Touch the sensor';
      case BiometricType.face:
        return 'Look at the camera';
      case BiometricType.both:
        return 'Use biometrics to unlock';
    }
  }

  void retry() {
    _state = _state.copyWith(error: null);
    notifyListeners();
    authenticate();
  }
}

class BiometricScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final Widget child;

  const BiometricScreen({
    super.key,
    required this.onAuthenticated,
    required this.child,
  });

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BiometricNotifier>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BiometricNotifier>(
      builder: (context, notifier, _) {
        final state = notifier.state;

        if (state.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onAuthenticated();
          });
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _buildAuthScreen(context, state, notifier),
            );
          },
        );
      },
    );
  }

  Widget _buildAuthScreen(
    BuildContext context,
    BiometricState state,
    BiometricNotifier notifier,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).cardColor]
                    : [AppTheme.lightBackground, AppTheme.lightCardBg],
              ),
            ),
          ),

          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: isDarkMode
                  ? Colors.black.withAlpha(40)
                  : Colors.white.withAlpha(30),
            ),
          ),

          // Scan line animation (para efecto futurista)
          if (state.isLoading)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).colorScheme.primary.withAlpha(30),
                            Colors.transparent,
                          ],
                          stops: [
                            0.0,
                            _scanAnimation.value,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Biometric icon with pulse
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: state.isLoading ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withAlpha(200),
                                  Theme.of(context).colorScheme.primary.withAlpha(100),
                                  Theme.of(context).colorScheme.tertiary.withAlpha(80),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 0.8, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(80),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.tertiary.withAlpha(50),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _buildBiometricIcon(state.biometricType),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Title
                    Text(
                      state.isLoading
                          ? 'Authenticating...'
                          : state.error != null
                              ? 'Try Again'
                              : 'Biometric Auth',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: isDarkMode
                                ? Theme.of(context).colorScheme.onSurface
                                : AppTheme.lightText,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      state.isInitializing
                          ? 'Initializing...'
                          : state.error != null
                              ? state.error!
                              : state.biometricType ==
                                      BiometricType.fingerprint
                                  ? 'Place your finger on the sensor'
                                  : state.biometricType == BiometricType.both
                                      ? 'Use face or fingerprint'
                                      : 'Look at the camera',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            color: (isDarkMode
                                    ? Theme.of(context).colorScheme.onSurface
                                    : AppTheme.lightText)
                                .withAlpha(180),
                            fontWeight: FontWeight.w400,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Loading indicator or retry button
                    if (state.isLoading)
                      _buildLoadingIndicator()
                    else if (state.error != null)
                      _buildRetryButton(context, notifier)
                    else if (!state.isInitializing)
                      _buildTapHint(isDarkMode),
                  ],
                ),
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: state.isLoading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Authenticate to continue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (isDarkMode
                              ? Theme.of(context).colorScheme.onSurface
                              : AppTheme.lightText)
                          .withAlpha(100),
                      fontSize: 12,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricIcon(BiometricType type) {
    if (type == BiometricType.fingerprint) {
      return Icon(
        Icons.fingerprint,
        size: 90,
        color: Theme.of(context).scaffoldBackgroundColor,
      );
    } else if (type == BiometricType.both) {
      return Icon(
        Icons.verified_user,
        size: 90,
        color: Theme.of(context).scaffoldBackgroundColor,
      );
    } else {
      return Icon(
        Icons.face,
        size: 90,
        color: Theme.of(context).scaffoldBackgroundColor,
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Waiting for biometrics...',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton(BuildContext context, BiometricNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.retry(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapHint(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: (isDarkMode ? Theme.of(context).cardColor : AppTheme.lightCardBg)
            .withAlpha(150),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Touch to authenticate',
            style: TextStyle(
              color: isDarkMode ? Theme.of(context).colorScheme.onSurface : AppTheme.lightText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para usar en la app
class BiometricGate extends StatelessWidget {
  final Widget child;
  final VoidCallback onAuthenticated;

  const BiometricGate({
    super.key,
    required this.child,
    required this.onAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BiometricNotifier(),
      child: BiometricScreen(
        onAuthenticated: onAuthenticated,
        child: child,
      ),
    );
  }
}