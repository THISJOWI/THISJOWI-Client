// Ejemplo COMPLETO de integración en main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/app_theme.dart';
import 'package:thisjowi/presentation/screens/biometric_auth_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BiometricAuthNotifier(),
        ),
        // Agrega aquí tus otros providers (ThemeProvider, etc.)
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THISECURE',
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.dark,
      home: _isAuthenticated
          ? const HomeScreen()
          : BiometricAuthScreen(
              onAuthenticated: () {
                setState(() {
                  _isAuthenticated = true;
                });
                // Opcionalmente: navega a otra pantalla
                // Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
    );
  }
}

// Pantalla principal de ejemplo
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Autenticado correctamente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Logout: volver a la pantalla de biometría
                // Implementa tu lógica de logout aquí
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

/* 
INSTRUCCIONES DE INTEGRACIÓN:

1. Copia BiometricAuthNotifier y BiometricAuthScreen a tu proyecto:
   - lib/presentation/screens/biometric_auth_screen.dart

2. En tu main.dart:
   - Importa BiometricAuthScreen y BiometricAuthNotifier
   - Agrega ChangeNotifierProvider en MultiProvider
   - Envuelve tu app logic con la pantalla biométrica

3. Permisos necesarios:

   iOS (ios/Runner/Info.plist):
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Usamos Face ID para proteger tu cuenta</string>
   <key>NSBiometricsUsageDescription</key>
   <string>Usamos datos biométricos para tu seguridad</string>
   ```

   Android (android/app/src/main/AndroidManifest.xml):
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC" />
   ```

4. Personalización de textos:
   En BiometricAuthScreen, edita:
   - Línea 257: Título principal
   - Línea 269-273: Texto según tipo de biometría
   - Línea 330: Texto del botón

5. Personalización de colores:
   Usa AppColors.dart o modifica directamente en BiometricAuthScreen

6. Para deshabilitar por ahora, simplemente no uses BiometricAuthScreen:
   home: const HomeScreen(),  // Sin autenticación
*/

