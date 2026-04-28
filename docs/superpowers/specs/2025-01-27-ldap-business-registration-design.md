# Diseño: Registro Business con LDAP

## Fecha
2025-01-27

## Resumen
Implementar un flujo de registro alternativo para cuentas Business que permita configurar autenticación LDAP en lugar del registro tradicional con email/password.

## Flujo de Registro Actual vs Nuevo

### Flujo Actual
1. Selección tipo de cuenta (Personal/Business)
2. Selección modo de despliegue (Cloud/SelfHosted)
3. Formulario de registro estándar (email, password, nombre, etc.)

### Flujo Nuevo
1. **Paso 0:** Selección tipo de cuenta (Personal/Business)
2. **Paso 1:** Selección modo de despliegue (Cloud/SelfHosted)
3. **Paso 2 (solo Business):** Pregunta "¿Deseas usar LDAP para autenticación?"
   - **NO** → Formulario de registro normal (existente)
   - **SÍ** → Formulario de registro LDAP personalizado (nuevo)

## Formulario de Registro LDAP

Cuando el usuario elige usar LDAP, se muestra un formulario específico con los siguientes campos:

### Campos del Formulario LDAP

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| Nombre de la organización | Texto | Sí | Nombre de la empresa |
| URL del servidor LDAP | Texto | Sí | Ej: `ldaps://ldap.empresa.com:636` |
| CN del administrador | Texto | Sí | Ej: `cn=admin,dc=empresa,dc=com` |
| DC (Domain Component) | Texto | Sí | Ej: `dc=empresa,dc=com` |
| Contraseña del administrador | Password | Sí | Para autenticar con el servidor LDAP |
| Base DN | Texto | No | Para búsqueda de usuarios |
| Términos y condiciones | Checkbox | Sí | Aceptación de términos |

### Diferencias con Registro Normal

| Aspecto | Registro Normal | Registro LDAP |
|---------|----------------|---------------|
| Email del administrador | Sí | No (se usa el del LDAP) |
| Password del administrador | Sí | No (se usa la del LDAP) |
| Configuración LDAP | No | Sí (todos los campos LDAP) |
| OTP/Verificación por email | Sí | No (se valida contra LDAP directamente) |

## Flujo de Datos

1. Usuario completa formulario LDAP
2. App valida conexión al servidor LDAP usando los datos proporcionados
3. Si la conexión es válida:
   - Se crea la cuenta Business vinculada a ese dominio LDAP
   - Se guarda la configuración LDAP para la organización
4. Los usuarios de esa organización pueden loguearse usando sus credenciales LDAP

## Archivos a Modificar/Crear

### Nuevos Archivos
1. `lib/components/ldap_selector.dart` - Componente de selección Sí/No para LDAP
2. `lib/screens/auth/ldap_register_form.dart` - Formulario de registro LDAP

### Archivos Modificados
1. `lib/screens/auth/register_flow.dart` - Agregar lógica de decisión LDAP y paso intermedio
2. `lib/services/ldapAuthService.dart` - Agregar método de registro con LDAP

## API Endpoints Requeridos

### POST /ldap/register-organization
Registra una nueva organización con configuración LDAP.

**Request:**
```json
{
  "organizationName": "Mi Empresa",
  "ldapUrl": "ldaps://ldap.empresa.com:636",
  "adminCn": "cn=admin,dc=empresa,dc=com",
  "dc": "dc=empresa,dc=com",
  "adminPassword": "secret",
  "baseDn": "ou=users,dc=empresa,dc=com",
  "hostingMode": "Cloud|SelfHosted"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Organización registrada exitosamente",
  "data": {
    "orgId": "uuid",
    "domain": "empresa.com",
    "ldapEnabled": true
  }
}
```

### POST /ldap/validate-config
Valida la configuración LDAP antes de registrar.

**Request:**
```json
{
  "ldapUrl": "ldaps://ldap.empresa.com:636",
  "adminCn": "cn=admin,dc=empresa,dc=com",
  "adminPassword": "secret",
  "dc": "dc=empresa,dc=com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Conexión LDAP válida",
  "configValid": true,
  "credentialsValid": true
}
```

## UI/UX Consideraciones

### Selector LDAP (Paso 2)
- Diseño consistente con los selectores existentes (AccountTypeSelector, DeploymentModeSelector)
- Opciones: "Usar autenticación LDAP" vs "Registro tradicional"
- Descripción breve de cada opción
- Iconos representativos

### Formulario LDAP
- Diseño glassmorphism consistente con la app
- Validación en tiempo real de campos requeridos
- Botón "Probar conexión LDAP" para validar antes de enviar
- Indicadores visuales de éxito/error en la conexión

## Seguridad

- La contraseña del admin LDAP se envía de forma segura (HTTPS)
- No se almacena la contraseña del admin LDAP en el dispositivo
- Se valida el certificado SSL/TLS del servidor LDAP
- Timeout en conexiones LDAP para evitar bloqueos

## Testing

### Casos de prueba
1. Registro LDAP exitoso con servidor LDAP válido
2. Registro LDAP fallido con credenciales incorrectas
3. Registro LDAP fallido con servidor inalcanzable
4. Registro normal funciona correctamente (sin LDAP)
5. Navegación hacia atrás funciona en todos los pasos
6. Validación de campos requeridos en formulario LDAP

## Dependencias

- `lib/services/ldapAuthService.dart` - Servicio existente para LDAP
- `lib/components/errorBar.dart` - Para mostrar errores
- `lib/i18n/translations.dart` - Para internacionalización

## Notas de Implementación

- Reutilizar estilos y componentes existentes para mantener consistencia visual
- El formulario LDAP debe ser un widget separado para mantener el código limpio
- Considerar agregar un indicador de progreso de 4 pasos cuando se usa LDAP
- Mantener compatibilidad con el flujo existente para cuentas Personal
