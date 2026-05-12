# Pantalla de Autenticación Biométrica

Una pantalla de autenticación biométrica a pantalla completa con fondo borroso, ícono animado en el centro y soporte para reconocimiento facial y huella dactilar.

## Características

✨ **Diseño**
- Pantalla completa con fondo degradado borroso
- Ícono animado con efecto pulso en el centro
- Soporta tanto modo claro como oscuro
- Integrado con tu paleta de colores actual

🔐 **Funcionalidad Biométrica**
- Detección automática de tipo de biometría (cara, huella, ambas)
- Ícono dinámico según el método disponible
- Manejo de errores y estados de carga
- Compatible con iOS y Android

🎯 **UX/UI**
- Animaciones suaves
- Textos contextuales según el tipo de biometría
- Feedback visual de progreso
- Mensajes de error claros

## Instalación y Configuración

### 1. Archivos Creados

```
lib/presentation/screens/biometric_auth_screen.dart
```

Este archivo contiene:
- `BiometricType`: Enum para tipos de biometría (face, fingerprint, both)
- `BiometricAuthState`: Modelo de estado con propiedades de autenticación
- `BiometricAuthNotifier`: ChangeNotifier que maneja la lógica biométrica
- `BiometricAuthScreen`: Widget de la pantalla completa

### 2. Integración en tu App

En tu `main.dart`, agrega el provider:

```dart
import 'package:provider/provider.dart';
import 'package:thisjowi/presentation/screens/biometric_auth_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BiometricAuthNotifier(),
        ),
        // Tus otros providers...
      ],
      child: const MyApp(),
    ),
  );
}
```

### 3. Mostrar la Pantalla

```dart
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
      home: _isAuthenticated
          ? const HomeScreen() // Tu pantalla principal
          : BiometricAuthScreen(
              onAuthenticated: () {
                setState(() {
                  _isAuthenticated = true;
                });
              },
            ),
    );
  }
}
```

## Personalización

### Textos

Edita los textos en `BiometricAuthScreen`:

```dart
// Título principal (línea ~257)
Text(
  'Biometric Authentication',
  // Cambia a tu texto personalizado
)

// Texto secundario según tipo de biometría (línea ~269)
Text(
  authState.biometricType == BiometricType.fingerprint
      ? 'Place your finger on the sensor'
      : authState.biometricType == BiometricType.both
          ? 'Use your face or fingerprint to authenticate'
          : 'Face the camera to authenticate',
)

// Botón (línea ~330)
Text('Authenticate')
```

### Colores

La pantalla utiliza automáticamente los colores de `AppColors.dart`:
- `AppColors.primary` - Color principal del ícono
- `AppColors.accent` - Color de acento
- `AppColors.background` - Fondo en modo oscuro
- `AppColors.surface` - Superficie en modo oscuro
- Etc.

Para cambiar los colores, modifica directamente `lib/core/app_colors.dart` o edita las líneas en `BiometricAuthScreen`:

```dart
// Ícono con gradiente (línea ~219)
gradient: LinearGradient(
  colors: [
    AppColors.primary.withAlpha(200),
    AppColors.accent.withAlpha(150),
  ],
)

// Botón (línea ~303)
gradient: LinearGradient(
  colors: [
    AppColors.primary,
    AppColors.accent,
  ],
)
```

### Animación

Ajusta la velocidad de pulso (línea ~131):

```dart
_pulseController = AnimationController(
  duration: const Duration(milliseconds: 2000), // Cambia aquí
  vsync: this,
)
```

Valores sugeridos:
- `1500ms` - Rápido
- `2000ms` - Normal (actual)
- `3000ms` - Lento

### Dimensiones

Tamaño del ícono (línea ~214):
```dart
width: 140,   // Cambia aquí
height: 140,  // Cambia aquí
```

Tamaño del ícono adentro (línea ~240):
```dart
size: 80,     // Cambia aquí
```

## Manejo de Errores

La pantalla automáticamente muestra mensajes de error si:
- No hay biometría disponible
- La autenticación falla
- Hay problemas inicializando los sensores

El mensaje de error se muestra en un contenedor rojo en la parte inferior de la pantalla.

## Requisitos Previos

✅ Ya instalado en tu proyecto:
- `flutter`
- `provider: ^6.0.0`
- `local_auth: ^3.0.1`

## Notas de Compatibilidad

### iOS

Requiere en `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID to authenticate you</string>
<key>NSBiometricsUsageDescription</key>
<string>This app uses biometric authentication</string>
```

### Android

Requiere en `android/app/build.gradle`:

```gradle
android {
  compileSdkVersion 35
  ...
}
```

Y permisos en `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

## Troubleshooting

### "Biometric authentication not available"

- Verifica que el dispositivo tenga sensores biométricos configurados
- En emulador, algunos sensores no están disponibles
- Comprueba los permisos del SO

### La pantalla no se muestra

- Asegúrate de que `BiometricAuthNotifier` esté en `MultiProvider`
- Verifica que el contexto tenga acceso al provider

### Animación no funciona

- Comprueba que `AnimationController` se inicialice en `initState`
- Verifica que `dispose()` se llame correctamente

## Próximas Mejoras

Considera agregar:
- Opción de fallback a PIN/contraseña
- Reintentos limitados
- Historial de autenticación
- Recordar dispositivo (evitar biometría en inicios posteriores)
- Localización de textos (i18n)
