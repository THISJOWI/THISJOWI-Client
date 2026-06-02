import 'package:flutter/material.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/biometricService.dart';

/// Widget to configure biometric app lock settings
class BiometricLockSettings extends StatefulWidget {
  const BiometricLockSettings({super.key});

  @override
  State<BiometricLockSettings> createState() => _BiometricLockSettingsState();
}

class _BiometricLockSettingsState extends State<BiometricLockSettings> {
  final BiometricService _biometricService = BiometricService();
  
  bool _isLoading = true;
  bool _canUseBiometric = false;
  bool _isLockEnabled = false;
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final canUse = await _biometricService.canUseBiometricLock();
    final isEnabled = await _biometricService.isBiometricLockEnabled();
    final typeName = await _biometricService.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _canUseBiometric = canUse;
        _isLockEnabled = isEnabled;
        _biometricTypeName = typeName;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    if (enabled) {
      // Verify biometric before enabling
      final success = await _biometricService.authenticate(
        localizedReason: 'Verify your identity to enable biometric lock'.i18n,
      );
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not verify your identity'.i18n),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    await _biometricService.setBiometricLockEnabled(enabled);
    
    if (mounted) {
      setState(() => _isLockEnabled = enabled);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled 
                ? "Lock with %s enabled".i18n.fill([_biometricTypeName])
                : "Lock with %s disabled".i18n.fill([_biometricTypeName]),
          ),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  IconData _getBiometricIcon() {
    if (_biometricTypeName.contains('Face')) {
      return Icons.face;
    } else if (_biometricTypeName.contains('Touch') || 
               _biometricTypeName.contains('Fingerprint')) {
      return Icons.fingerprint;
    }
    return Icons.lock;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListTile(
        leading: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading...'.i18n),
      );
    }

    if (!_canUseBiometric) {
      return ListTile(
        leading: Icon(
          Icons.lock_outline,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        title: Text(
          'Biometric lock'.i18n,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        subtitle: Text(
          'Not available on this device'.i18n,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
      );
    }

    return ListTile(
      leading: Icon(
        _getBiometricIcon(),
        color: _isLockEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        'Lock with %s'.i18n.fill([_biometricTypeName]),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        _isLockEnabled 
            ? "%s will be required when opening the app".i18n.fill([_biometricTypeName])
            : 'The app will open without verification'.i18n,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: _isLockEnabled,
        onChanged: _toggleBiometricLock,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Compact card version of biometric lock settings
class BiometricLockSettingsCard extends StatefulWidget {
  const BiometricLockSettingsCard({super.key});

  @override
  State<BiometricLockSettingsCard> createState() => _BiometricLockSettingsCardState();
}

class _BiometricLockSettingsCardState extends State<BiometricLockSettingsCard> {
  final BiometricService _biometricService = BiometricService();
  
  bool _isLoading = true;
  bool _canUseBiometric = false;
  bool _isLockEnabled = false;
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final canUse = await _biometricService.canUseBiometricLock();
    final isEnabled = await _biometricService.isBiometricLockEnabled();
    final typeName = await _biometricService.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _canUseBiometric = canUse;
        _isLockEnabled = isEnabled;
        _biometricTypeName = typeName;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    if (enabled) {
      final success = await _biometricService.authenticate(
        localizedReason: 'Verify your identity to enable biometric lock'.i18n,
      );
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not verify your identity'.i18n),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    await _biometricService.setBiometricLockEnabled(enabled);
    
    if (mounted) {
      setState(() => _isLockEnabled = enabled);
    }
  }

  IconData _getBiometricIcon() {
    if (_biometricTypeName.contains('Face')) {
      return Icons.face;
    } else if (_biometricTypeName.contains('Touch') || 
               _biometricTypeName.contains('Fingerprint')) {
      return Icons.fingerprint;
    }
    return Icons.lock;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_canUseBiometric) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isLockEnabled 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getBiometricIcon(),
                color: _isLockEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lock with %s".i18n.fill([_biometricTypeName]),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLockEnabled 
                        ? 'Enabled'.i18n
                        : 'Disabled'.i18n,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isLockEnabled ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isLockEnabled,
              onChanged: _toggleBiometricLock,
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
