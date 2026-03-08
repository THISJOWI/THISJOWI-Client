import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/appColors.dart';
import 'package:thisjowi/core/providers/otpProvider.dart';
import 'package:thisjowi/data/models/otpEntry.dart';
import 'package:thisjowi/i18n/translationService.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/otpService.dart';
import 'package:thisjowi/components/errorBar.dart';
import 'package:thisjowi/components/button.dart';
import 'package:thisjowi/utils/GlobalActions.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with WidgetsBindingObserver {
  final OtpService _otpService = OtpService();
  Timer? _refreshTimer;
  late OtpProvider _otpProvider;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Save reference to OtpProvider for use in dispose()
    _otpProvider = context.read<OtpProvider>();

    // Load entries when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOtpData();
      // Start auto-refresh to detect changes from other screens
      _otpProvider.startAutoRefresh(
        refreshInterval: const Duration(seconds: 2),
      );
    });

    // Update codes every second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload entries when app comes to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      _loadOtpData();
      // Resume auto-refresh
      try {
        _otpProvider.startAutoRefresh(
          refreshInterval: const Duration(seconds: 2),
        );
      } catch (e) {
        // Widget may have been deactivated
      }
    } else if (state == AppLifecycleState.paused && mounted) {
      // Stop auto-refresh when app is paused
      try {
        _otpProvider.stopAutoRefresh();
      } catch (e) {
        // Widget may have been deactivated
      }
    }
  }

  void _loadOtpData() {
    if (mounted) {
      try {
        _otpProvider.loadEntries();
      } catch (e) {
        // Widget may have been deactivated
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    // Stop auto-refresh when leaving the screen (using saved provider reference)
    _otpProvider.stopAutoRefresh();
    super.dispose();
  }

  void _copyCode(OtpEntry entry) {
    if (!mounted) return;
    
    try {
      final code = _otpService.generateTotp(
        secret: entry.secret,
        digits: entry.digits,
        period: entry.period,
        algorithm: entry.algorithm,
      );

      Clipboard.setData(ClipboardData(text: code));
      
      if (!mounted) return;
      try {
        ErrorSnackBar.showSuccess(context, 'Code copied'.tr(context));
      } catch (e) {
        // Widget may have been deactivated
      }
    } catch (e) {
      if (!mounted) return;
      try {
        ErrorSnackBar.show(context, 'Invalid secret key'.tr(context));
      } catch (e) {
        // Widget may have been deactivated
      }
    }
  }

  Future<void> _refreshFromServer() async {
    if (!mounted) return;
    try {
      await _otpProvider.loadEntries();
    } catch (e) {
      // Widget may have been deactivated
    }
  }



  Future<void> _deleteEntry(OtpEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
        title: Text('Delete OTP?'.tr(context),
            style: const TextStyle(color: AppColors.text)),
        content: Text(
          'Are you sure you want to delete "${entry.issuer.isNotEmpty ? entry.issuer : entry.name}"?',
          style: const TextStyle(color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr(context),
                style: TextStyle(color: AppColors.text.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'.tr(context),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _otpProvider.deleteOtpEntry(
        entry.id,
        serverId: entry.serverId,
      );

      if (!mounted) return;

      try {
        if (success) {
          ErrorSnackBar.showSuccess(context, 'OTP deleted'.tr(context));
        } else {
          ErrorSnackBar.show(
              context, _otpProvider.errorMessage);
        }
      } catch (e) {
        // Widget may have been deactivated
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.text.withOpacity(0.7)),
        hintStyle: TextStyle(color: AppColors.text.withOpacity(0.3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.text.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.text.withOpacity(0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Consumer<OtpProvider>(
          builder: (context, otpProvider, _) {
            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            const Icon(Icons.security,
                                color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Authenticator'.tr(context),
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  otpProvider.setSearchQuery(value);
                                },
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Search'.i18n,
                                  hintStyle: TextStyle(
                                      color: AppColors.text.withOpacity(0.5),
                                      fontSize: 16),
                                  prefixIcon: Icon(Icons.search,
                                      color: AppColors.text.withOpacity(0.6),
                                      size: 22),
                                  suffixIcon: otpProvider.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.close,
                                              color:
                                                  AppColors.text.withOpacity(0.6),
                                              size: 20),
                                          onPressed: () {
                                            otpProvider.clearSearch();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // List
                      Expanded(
                        child: otpProvider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary))
                            : otpProvider.filteredEntries.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _refreshFromServer,
                                    color: AppColors.primary,
                                    child: ListView.builder(
                                      padding:
                                          const EdgeInsets.fromLTRB(20, 0, 20, 150),
                                      itemCount:
                                          otpProvider.filteredEntries.length,
                                      itemBuilder: (context, index) =>
                                          _buildOtpCard(
                                              otpProvider.filteredEntries[index]),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),

                // FAB
                Positioned(
                  bottom: 130.0,
                  right: 16.0,
                  child: ExpandableActionButton(
                    onCreatePassword: () =>
                        GlobalActions.createPassword(context),
                    onCreateNote: () => GlobalActions.createNote(context),
                    onCreateOtp: () =>
                        GlobalActions.createOtp(context, onSuccess: _refreshFromServer),
                    onCreateMessage: () =>
                        GlobalActions.createMessage(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 80,
            color: AppColors.text.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No OTP entries yet'.tr(context),
            style: TextStyle(
              color: AppColors.text.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first authenticator code'.tr(context),
            style: TextStyle(
              color: AppColors.text.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(OtpEntry entry) {
    String code;
    bool isValidSecret = true;

    try {
      code = _otpService.generateTotp(
        secret: entry.secret,
        digits: entry.digits,
        period: entry.period,
        algorithm: entry.algorithm,
      );
    } catch (e) {
      code = 'INVALID';
      isValidSecret = false;
    }

    // Si el secreto es inválido, mostrar una tarjeta de error sin información sensible
    if (!isValidSecret) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(40, 30, 30, 1.0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invalid OTP Entry'.tr(context),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Secret key is corrupted'.tr(context),
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteEntry(entry),
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final formattedCode = _otpService.formatCode(code);
    final remainingSeconds =
        _otpService.getRemainingSeconds(period: entry.period);
    final progress = _otpService.getProgress(period: entry.period);

    // Color del progreso: verde > amarillo > rojo
    Color progressColor;
    if (remainingSeconds > 10) {
      progressColor = Colors.green;
    } else if (remainingSeconds > 5) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _copyCode(entry),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon with issuer initial
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  () {
                                    final text = entry.issuer.isNotEmpty
                                        ? entry.issuer
                                        : entry.name;
                                    return text.isNotEmpty
                                        ? text.substring(0, 1).toUpperCase()
                                        : '?';
                                  }(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.issuer.isNotEmpty
                                        ? entry.issuer
                                        : entry.name,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (entry.issuer.isNotEmpty)
                                    Text(
                                      entry.name,
                                      style: TextStyle(
                                        color: AppColors.text.withOpacity(0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Delete button
                            IconButton(
                              onPressed: () => _deleteEntry(entry),
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.text.withOpacity(0.3),
                                size: 20,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Code and timer
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Code
                            Expanded(
                              child: Text(
                                formattedCode,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),

                            // Timer
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3,
                                    backgroundColor:
                                        AppColors.text.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        progressColor),
                                  ),
                                ),
                                Text(
                                  '$remainingSeconds',
                                  style: TextStyle(
                                    color: progressColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Copy hint
                        Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 14,
                              color: AppColors.text.withOpacity(0.3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to copy'.tr(context),
                              style: TextStyle(
                                color: AppColors.text.withOpacity(0.3),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
