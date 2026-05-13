import 'package:flutter/material.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/i18n/translationService.dart';
import 'package:thisjowi/services/samlAuthService.dart';

class SamlLoginScreen extends StatefulWidget {
  const SamlLoginScreen({super.key});

  @override
  State<SamlLoginScreen> createState() => _SamlLoginScreenState();
}

class _SamlLoginScreenState extends State<SamlLoginScreen> {
  final SamlAuthService _samlAuthService = SamlAuthService();
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;
  String? _selectedDomain;
  List<String> _availableDomains = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableDomains();
  }

  Future<void> _loadAvailableDomains() async {
    try {
      setState(() => _isLoading = true);
      final domains = await _fetchSamlEnabledDomains();
      if (mounted) {
        setState(() {
          _availableDomains = domains;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<String>> _fetchSamlEnabledDomains() async {
    return [];
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _handleSamlLogin() async {
    if (_selectedDomain == null || _selectedDomain!.isEmpty) {
      ErrorSnackBar.show(context, 'Selecciona tu empresa'.tr(context));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final config = await _samlAuthService.getSamlConfigForDomain(_selectedDomain!);
      
      if (config == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ErrorSnackBar.show(context, 'SAML no configurado para este dominio');
        }
        return;
      }

      final idpLoginUrl = config['idpLoginUrl'] ?? config['loginUrl'];
      
      if (idpLoginUrl == null && mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(context, 'URL de login SAML no disponible');
        return;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(context,
            'Serás redirigido al portal de tu empresa para autenticarte');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        ErrorSnackBar.show(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SSO Empresarial'.tr(context),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_outlined,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        ' SSO Empresarial'.tr(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión con las credenciales de tu empresa'
                            .tr(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecciona tu organización'.tr(context),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_isLoading)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              else if (_availableDomains.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.business_outlined,
                                        color: Colors.white.withValues(alpha: 0.5),
                                        size: 40,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No hay organizaciones SAML disponibles'
                                            .tr(context),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Contacta a tu administrador'
                                            .tr(context),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDomain,
                                      hint: Text(
                                        'Selecciona dominio...'.tr(context),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF2E2E2E),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                      items: _availableDomains
                                          .map(
                                            (domain) => DropdownMenuItem(
                                              value: domain,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Text(
                                                  domain,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDomain = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.tertiary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading || _selectedDomain == null
                                      ? null
                                      : _handleSamlLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Continuar'.tr(context),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Serás redirigido al portal de tu empresa para autenticarte'
                                    .tr(context),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}