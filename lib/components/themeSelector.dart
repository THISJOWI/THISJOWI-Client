import 'package:flutter/material.dart';
import 'package:thisjowi/core/themeProvider.dart';
import 'package:provider/provider.dart';

/// Widget selector de tema con opciones: Sistema, Claro, Oscuro
class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apariencia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildThemeOption(
                context,
                themeProvider,
                ThemeModeOption.system,
                'Sistema',
                'Sigue la configuración del dispositivo',
                Icons.brightness_auto,
              ),
              Divider(
                height: 1,
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
              _buildThemeOption(
                context,
                themeProvider,
                ThemeModeOption.light,
                'Claro',
                'Tema claro siempre activo',
                Icons.light_mode,
              ),
              Divider(
                height: 1,
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
              _buildThemeOption(
                context,
                themeProvider,
                ThemeModeOption.dark,
                'Oscuro',
                'Tema oscuro siempre activo',
                Icons.dark_mode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeModeOption mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final isDark = themeProvider.isDarkMode(context);
    
    return InkWell(
      onTap: () => themeProvider.setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 22,
                color: Theme.of(context).primaryColor,
              )
            else
              Icon(
                Icons.circle_outlined,
                size: 22,
                color: isDark 
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget simple de toggle para cambiar entre claro/oscuro
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return IconButton(
      onPressed: () => themeProvider.toggleTheme(),
      icon: Icon(
        themeProvider.isDarkMode(context) 
            ? Icons.light_mode 
            : Icons.dark_mode,
      ),
      tooltip: themeProvider.isDarkMode(context) 
          ? 'Cambiar a modo claro'
          : 'Cambiar a modo oscuro',
    );
  }
}

/// ListTile para usar en configuraciones
class ThemeSettingsTile extends StatelessWidget {
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ListTile(
      leading: Icon(themeProvider.getThemeModeIcon()),
      title: const Text('Tema'),
      subtitle: Text(themeProvider.getThemeModeText()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const ThemeSelectorWidget(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
