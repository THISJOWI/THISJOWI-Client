import 'package:flutter/material.dart';
import '../components/liquid_glass.dart';
import '../data/models/password_entry.dart';
import '../i18n/translations.dart';
import '../services/import_export_service.dart';

class ExportPasswordsSheet extends StatelessWidget {
  final List<PasswordEntry> passwords;

  const ExportPasswordsSheet({super.key, required this.passwords});

  void _export(BuildContext context, String format) async {
    Navigator.pop(context);
    final service = ImportExportService();

    try {
      String content;
      String filename;
      String mimeType;

      if (format == 'csv') {
        content = service.generateCsv(passwords);
        filename = 'passwords_export.csv';
        mimeType = 'text/csv';
      } else {
        content = service.generateJson(passwords);
        filename = 'passwords_export.json';
        mimeType = 'application/json';
      }

      await service.exportAndShare(content, filename, mimeType);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'Export failed'.i18n}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.wrap(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Export Passwords'.i18n,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${passwords.length} ${'passwords will be exported'.i18n}',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.table_chart,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                title: Text(
                  'CSV',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Compatible with Bitwarden, LastPass, etc.'.i18n,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () => _export(context, 'csv'),
              ),
              ListTile(
                leading: Icon(
                  Icons.data_object,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                title: Text(
                  'JSON',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Full data format'.i18n,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                onTap: () => _export(context, 'json'),
              ),
            ],
          ),
        ),
      ),
      context,
      borderRadius: 20,
    );
  }
}
