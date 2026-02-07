# LDAP Integration - Flutter Client Implementation

## 📱 Overview

Se ha implementado un sistema completo de autenticación LDAP en el cliente Flutter de ThisJowi.

---

## 📁 Archivos Creados

### Models
- **`lib/data/models/organization.dart`** - Modelo de Organización
  - id, domain, name, description
  - ldapUrl, ldapBaseDn, ldapEnabled, isActive
  - timestamps

### Services
- **`lib/services/ldapAuthService.dart`** - Servicio LDAP
  - loginWithLdap() - Autenticación LDAP
  - getOrganizationByDomain() - Obtener org por dominio
  - isLdapEnabledForDomain() - Verificar si dominio tiene LDAP
  - getLdapUserInfo() - Obtener info de usuario LDAP
  - clearLdapSession() - Limpiar sesión

### Screens
- **`lib/screens/auth/ldapLogin.dart`** - Pantalla de login LDAP
  - Campos: Dominio, Usuario, Contraseña
  - Validación de formulario
  - Manejo de errores
  - Link a login regular

- **`lib/screens/auth/authSelection.dart`** - Pantalla de selección de método
  - Selector visual LDAP vs Regular
  - Información de ayuda
  - Logo y branding

### Components
- **`lib/components/authMethodSelector.dart`** - Selector de método auth
  - UI para elegir LDAP o regular
  - Iconos y descripciones

- **`lib/components/ldapUserCard.dart`** - Widget de información de usuario LDAP
  - Muestra email, usuario LDAP, orgId
  - Status badge
  - Botón de logout opcional

---

## ✏️ Archivos Modificados

### Models
- **`lib/data/models/user.dart`** - Actualizada con campos LDAP
  - `orgId` - ID de organización
  - `ldapUsername` - Usuario LDAP
  - `isLdapUser` - Indicador de usuario LDAP

---

## 🎯 Features Implementadas

✅ **Autenticación LDAP** - Login contra servidores LDAP corporativos  
✅ **Validación de Dominio** - Verificar que dominio tiene LDAP habilitado  
✅ **Almacenamiento Local** - Guardar token y datos en SharedPreferences  
✅ **UI Intuitiva** - Pantallas con validación y manejo de errores  
✅ **Información de Usuario** - Widget para mostrar datos de usuario LDAP  
✅ **Selección de Método** - Elegir entre LDAP y autenticación regular  
✅ **Logout LDAP** - Limpiar datos de sesión LDAP  

---

## 🚀 Flujo de Uso

### 1. Pantalla de Selección
Usuario ve opciones:
- LDAP Corporativo (para empresas)
- Cuenta Regular (email/password)

### 2. Login LDAP
```
Ingresar dominio (ej: empresa.com)
    ↓
Validar que dominio tiene LDAP habilitado
    ↓
Solicitar usuario LDAP
    ↓
Solicitar contraseña LDAP
    ↓
Enviar a backend: POST /api/v1/auth/ldap/login
    ↓
Recibir token JWT + datos de usuario
    ↓
Guardar en SharedPreferences
    ↓
Navegar a home
```

### 3. Navegación
```dart
// Ir a selección de métodos
Navigator.pushReplacementNamed(context, '/authSelection');

// Ir a login LDAP
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const LdapLoginScreen(),
));

// Ir a login regular
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const LoginScreen(),
));
```

---

## 📋 Guía de Integración

### 1. Actualizar main.dart
Añadir ruta para authSelection:

```dart
routes: {
  '/authSelection': (context) => const AuthSelectionScreen(),
  '/ldapLogin': (context) => const LdapLoginScreen(),
  '/login': (context) => const LoginScreen(),
  '/home': (context) => const MyBottomNavigation(),
}
```

### 2. Actualizar splash screen
En lugar de ir directo a login, ir a authSelection:

```dart
// En SplashScreen
Future.delayed(const Duration(seconds: 2), () {
  Navigator.of(context).pushReplacementNamed('/authSelection');
});
```

### 3. Mostrar información de usuario LDAP
En pantalla de perfil o settings:

```dart
final ldapAuthService = LdapAuthService();
final user = await ldapAuthService.getLdapUserInfo();

if (user != null && user.isLdapUser) {
  return LdapUserCard(
    user: user,
    onLogout: () async {
      await ldapAuthService.clearLdapSession();
      Navigator.pushReplacementNamed(context, '/authSelection');
    },
  );
}
```

### 4. Verificar sesión LDAP
Al cargar app:

```dart
final ldapUser = await ldapAuthService.getLdapUserInfo();
if (ldapUser != null) {
  // Usuario LDAP autenticado
  print('LDAP user: ${ldapUser.email}');
} else {
  // Usuario regular o no autenticado
}
```

---

## 🔐 Seguridad

✅ Tokens guardados en SharedPreferences (considerar usar Secure Storage)  
✅ Validación de dominio antes de solicitar credenciales  
✅ Manejo seguro de contraseñas (no se almacenan)  
✅ Limpieza de sesión al logout  
✅ Errores específicos sin exponer detalles del servidor  

---

## 🎨 UI Components

### AuthMethodSelector
```dart
AuthMethodSelector(
  onLdapTap: () { /* navegar a LDAP */ },
  onRegularTap: () { /* navegar a Regular */ },
)
```

### LdapUserCard
```dart
LdapUserCard(
  user: user,
  onLogout: () { /* manejar logout */ },
)
```

### LdapLoginScreen
Pantalla completa con:
- Validación de formulario
- Manejo de errores
- Indicador de carga
- Link a login regular

---

## 📊 Data Flow

```
LdapLoginScreen
    ↓
LdapAuthService.loginWithLdap()
    ↓
POST /api/v1/auth/ldap/login
    ↓
Backend LDAP Authentication
    ↓
Response: { token, userId, email, orgId, ldapUsername }
    ↓
Guardar en SharedPreferences
    ↓
User object creado
    ↓
Navegar a Home
```

---

## 🛠️ Troubleshooting

### "El dominio no tiene LDAP habilitado"
- Verificar que el dominio existe en el servidor
- Verificar que LDAP está habilitado para esa organización
- Revisar logs del backend

### "Credenciales inválidas"
- Verificar usuario y contraseña LDAP
- Verificar que el usuario existe en el servidor LDAP
- Revisar filtros de búsqueda en backend

### "Timeout al conectarse"
- Verificar conexión a internet
- Verificar que servidor LDAP es accesible
- Aumentar timeout si es necesario en ldapAuthService

### "Token no se guarda"
- Verificar permisos de SharedPreferences
- Considerar usar Secure Storage para tokens

---

## 📚 Related Documentation

- Backend: `/Users/joel/proyects/server/auth/LDAP_IMPLEMENTATION.md`
- API: `/Users/joel/proyects/server/auth/DEPLOYMENT_GUIDE.md`
- Checklist: `/Users/joel/proyects/server/auth/VERIFICATION_CHECKLIST.md`

---

## 📦 Dependencies

Asegúrate de que estas dependencias están en pubspec.yaml:

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.0
  google_sign_in: ^6.1.0
  flutter_web_auth_2: ^3.0.0
```

---

## 🔄 Next Steps

1. Añadir rutas en main.dart
2. Actualizar pantalla de splash
3. Actualizar pantalla de settings para mostrar usuario LDAP
4. Probar con servidor LDAP real
5. Considerar usar Secure Storage para tokens
6. Implementar refresh de token
7. Añadir biometric auth para usuarios LDAP

---

**Implementation Date**: 2026-02-01  
**Status**: ✅ Ready for Integration  
**Platform**: Flutter  
**Min SDK**: Flutter 3.0+
