import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/components/account_type_selector.dart';
import 'package:thisjowi/components/deployment_mode_selector.dart';
import 'package:thisjowi/components/ldap_selector.dart';
import 'package:thisjowi/core/app_colors.dart';
import 'package:thisjowi/screens/auth/registerForm.dart';
import 'package:thisjowi/screens/auth/ldap_register_form.dart';

class RegisterFlowScreen extends StatefulWidget {
  final bool isEmbedded;
  final Function(Map<String, dynamic>)? onSuccess;

  const RegisterFlowScreen({
    super.key,
    this.isEmbedded = false,
    this.onSuccess,
  });

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen>
    with TickerProviderStateMixin {
  int currentStep = 0;
  String? accountType;
  String? hostingMode;
  bool? useLdap;
  bool _isGoingBack = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _slideBackController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _slideBackAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fadeBackAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideBackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideBackAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _slideBackController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeBackAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideBackController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _slideBackController.dispose();
    super.dispose();
  }

  void _animateToNextStep(VoidCallback onComplete) {
    _fadeController.reverse().then((_) {
      onComplete();
      _slideController.forward(from: 0.0);
      _fadeController.forward();
    });
  }

  void _handleAccountTypeSelected(String type) {
    _animateToNextStep(() {
      setState(() {
        accountType = type;
        currentStep = 1;
      });
    });
  }

  void _handleDeploymentModeSelected(String mode) {
    _animateToNextStep(() {
      setState(() {
        hostingMode = mode;
        if (accountType == 'Business') {
          currentStep = 2;
        } else {
          currentStep = 3;
        }
      });
    });
  }

  void _handleLdapSelected(bool useLdapValue) {
    _animateToNextStep(() {
      setState(() {
        useLdap = useLdapValue;
        currentStep = 3;
      });
    });
  }

  void _goBack() {
    if (currentStep > 0) {
      _isGoingBack = true;
      _slideBackController.forward(from: 0.0).then((_) {
        setState(() {
          currentStep--;
          if (currentStep == 0) {
            hostingMode = null;
            accountType = null;
            useLdap = null;
          } else if (currentStep == 1) {
            useLdap = null;
          } else if (currentStep == 2 && accountType != 'Business') {
            currentStep = 1;
            useLdap = null;
          }
        });
        _slideController.forward(from: 0.0);
        _fadeController.forward();
        _slideBackController.reset();
        _isGoingBack = false;
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _handleSuccess(Map<String, dynamic> result) {
    if (widget.onSuccess != null) {
      widget.onSuccess!(result);
    }
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return AccountTypeSelector(
          onAccountTypeSelected: _handleAccountTypeSelected,
        );
      case 1:
        return DeploymentModeSelector(
          onDeploymentModeSelected: _handleDeploymentModeSelected,
        );
      case 2:
        if (accountType == 'Business') {
          return LdapSelector(
            onLdapSelected: _handleLdapSelected,
          );
        }
        if (accountType != null && hostingMode != null) {
          return RegisterForm(
            accountType: accountType!,
            hostingMode: hostingMode!,
            onSuccess: _handleSuccess,
            onBack: _goBack,
          );
        }
        return const Center(child: CircularProgressIndicator());
      case 3:
        if (accountType != null && hostingMode != null) {
          if (accountType == 'Business' && useLdap == true) {
            return LdapRegisterForm(
              hostingMode: hostingMode!,
              onSuccess: _handleSuccess,
              onBack: _goBack,
            );
          } else {
            return RegisterForm(
              accountType: accountType!,
              hostingMode: hostingMode!,
              onSuccess: _handleSuccess,
              onBack: _goBack,
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _fadeController,
        _slideBackController,
      ]),
      builder: (context, child) {
        if (_isGoingBack) {
          return FadeTransition(
            opacity: _fadeBackAnimation,
            child: SlideTransition(
              position: _slideBackAnimation,
              child: child,
            ),
          );
        }
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: _buildStepContent(),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            top: currentStep == 0 ? -100 : -50,
            left: currentStep == 0 ? -100 : -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2000),
              width: currentStep == 0 ? 400 : 350,
              height: currentStep == 0 ? 400 : 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary
                        .withValues(alpha: currentStep == 0 ? 0.3 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            bottom: currentStep == 1 ? -50 : -100,
            right: currentStep == 1 ? -50 : -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2000),
              width: currentStep == 1 ? 350 : 300,
              height: currentStep == 1 ? 350 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary
                        .withValues(alpha: currentStep == 1 ? 0.35 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -80,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: currentStep == 2 ? 0.4 : 0.0,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.text,
                  size: 22,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}