# Sistema de Gestor de Contraseñas - THISJOWI

## Descripción General

THISJOWI ahora funciona como un **gestor de contraseñas completo** similar a Bitwarden. Cuando el usuario escribe credenciales (usuario/email y contraseña) en aplicaciones o sitios web externos, THISJOWI detecta automáticamente estos campos y ofrece:

1. **Guardar las credenciales** cuando se detectan nuevas
2. **Autocompletar automáticamente** cuando se detecta el mismo sitio/app

## Arquitectura del Sistema

### 1. Detección de Credenciales (Android)

#### `ThisjowiAutofillService.kt`
- **Servicio de Autofill de Android** que se ejecuta en segundo plano
- **Detecta campos** de usuario/contraseña en otras apps
- **Captura URLs** de navegadores web (Chrome, Firefox, Brave, etc.)
- **Extrae credenciales** cuando el usuario las envía

**Funciones principales:**
- `onFillRequest()`: Detecta cuando una app solicita autofill
- `onSaveRequest()`: Captura credenciales cuando el usuario las envía
- `extractWebUrl()`: Extrae la URL del navegador web
- `parseStructure()`: Analiza la estructura de la app para encontrar campos

### 2. Comunicación con Flutter

#### `MainActivity.kt`
- **Puente entre Android y Flutter** usando MethodChannel
- **Almacena datos pendientes** de autofill
- **Pasa información** a Flutter cuando la app se abre

**Datos que maneja:**
- `target_package`: Nombre del paquete de la app
- `target_url`: URL del sitio web (si es navegador)
- `username`: Usuario/email detectado
- `password`: Contraseña detectada

### 3. Servicios de Flutter

#### `autofillService.dart`
- **Interfaz principal** para funcionalidad de autofill
- **Verifica soporte** del dispositivo
- **Obtiene solicitudes pendientes** de autofill
- **Proporciona credenciales** para autocompletar

**Clases:**
- `AutofillService`: Servicio singleton principal
- `AutofillRequest`: Modelo de datos para solicitudes
- `AutofillStatus`: Estado del servicio de autofill

#### `autofillSaveHandler.dart`
- **Monitorea constantemente** solicitudes de guardado
- **Muestra el diálogo** cuando se detectan credenciales
- **Se ejecuta en segundo plano** mientras la app está activa

**Funciones:**
- `startMonitoring()`: Inicia el monitoreo
- `stopMonitoring()`: Detiene el monitoreo
- `checkNow()`: Verifica inmediatamente si hay solicitudes

### 4. Interfaz de Usuario

#### `SavePasswordDialog.dart`
- **Diálogo hermoso y moderno** para guardar contraseñas
- **Validación de formularios** completa
- **Extracción inteligente** de nombres de apps/sitios

**Campos:**
- Título (auto-generado desde URL/app)
- Usuario/Email
- Contraseña (con visibilidad toggle)
- Sitio web/App
- Notas (opcional)

**Características:**
- Auto-rellena con datos detectados
- Extrae nombre de dominio de URLs
- Extrae nombre de app desde package name
- Validación en tiempo real
- Diseño premium con glassmorphism

### 5. Integración con Navigation

#### `Navigation.dart`
- **Inicia el monitoreo** cuando la app se abre
- **Detecta cuando la app vuelve** al primer plano
- **Limpia recursos** cuando se cierra

## Flujo de Trabajo

### Guardar Nueva Contraseña

```
1. Usuario escribe credenciales en otra app/web
   ↓
2. ThisjowiAutofillService detecta los campos
   ↓
3. Usuario envía el formulario (login/registro)
   ↓
4. onSaveRequest() captura las credenciales
   ↓
5. Se abre THISJOWI con un Intent
   ↓
6. MainActivity almacena los datos pendientes
   ↓
7. AutofillSaveHandler detecta la solicitud
   ↓
8. Se muestra SavePasswordDialog
   ↓
9. Usuario revisa/edita y guarda
   ↓
10. Contraseña se guarda en la base de datos
```

### Autocompletar Contraseña

```
1. Usuario abre una app/web
   ↓
2. ThisjowiAutofillService detecta campos de login
   ↓
3. Android muestra sugerencia "THISJOWI - Tap to autofill"
   ↓
4. Usuario toca la sugerencia
   ↓
5. Se abre THISJOWI para autenticación
   ↓
6. Usuario selecciona la contraseña correcta
   ↓
7. Credenciales se envían de vuelta a la app
   ↓
8. Campos se rellenan automáticamente
```

## Detección de URLs en Navegadores

El sistema detecta URLs en los siguientes navegadores:

- Google Chrome (`com.android.chrome`)
- Mozilla Firefox (`org.mozilla.firefox`)
- Opera (`com.opera.browser`)
- Microsoft Edge (`com.microsoft.emmx`)
- Brave (`com.brave.browser`)
- DuckDuckGo (`com.duckduckgo.mobile.android`)
- Samsung Internet (`com.sec.android.app.sbrowser`)

**Métodos de extracción:**
1. `webDomain` property del ViewNode
2. Búsqueda de texto que empiece con "http"
3. Búsqueda recursiva en todos los nodos

## Configuración Requerida

### AndroidManifest.xml
```xml
<service
    android:name=".ThisjowiAutofillService"
    android:permission="android.permission.BIND_AUTOFILL_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.service.autofill.AutofillService" />
    </intent-filter>
    <meta-data
        android:name="android.autofill"
        android:resource="@xml/autofill_service" />
</service>
```

### Permisos
- `android.permission.BIND_AUTOFILL_SERVICE`

### Activación por Usuario
El usuario debe activar THISJOWI como servicio de autofill en:
**Configuración > Sistema > Idiomas y entrada > Servicio de autocompletar > THISJOWI**

## Almacenamiento de Contraseñas

Las contraseñas se guardan en:

1. **Base de datos local** (Drift/SQLite)
   - Tabla: `Passwords`
   - Campos: id, title, username, password, website, notes, userId, etc.

2. **Servidor backend** (sincronización)
   - API: `/api/passwords`
   - Métodos: GET, POST, PUT, DELETE

3. **App Group Storage** (iOS - para extensión de autofill)
   - Compartido entre app principal y extensión

## Seguridad

- **Encriptación**: Las contraseñas se almacenan encriptadas
- **Autenticación**: Requiere login para acceder
- **Biometría**: Soporte para desbloqueo biométrico
- **E2EE**: End-to-end encryption para mensajes

## Ventajas sobre Gestores Tradicionales

1. **Integración nativa** con tu ecosistema THISJOWI
2. **Sin suscripciones** adicionales
3. **Control total** de tus datos
4. **Sincronización** entre dispositivos
5. **Interfaz moderna** y premium
6. **Detección inteligente** de URLs y apps

## Próximas Mejoras

- [ ] Generador de contraseñas seguras
- [ ] Análisis de seguridad de contraseñas
- [ ] Detección de contraseñas duplicadas
- [ ] Alertas de brechas de seguridad
- [ ] Soporte para iOS Credential Provider Extension
- [ ] Importar/exportar contraseñas
- [ ] Compartir contraseñas con otros usuarios (Business)
- [ ] Categorías y etiquetas para contraseñas
- [ ] Historial de cambios de contraseñas
- [ ] Notas seguras y documentos

## Archivos Modificados/Creados

### Nuevos Archivos
1. `/lib/screens/password/SavePasswordDialog.dart` - Diálogo de guardado
2. `/lib/services/autofillSaveHandler.dart` - Manejador de guardado

### Archivos Modificados
1. `/android/app/src/main/kotlin/.../ThisjowiAutofillService.kt` - Detección de URLs
2. `/android/app/src/main/kotlin/.../MainActivity.kt` - Manejo de URLs
3. `/lib/services/autofillService.dart` - Soporte para URLs
4. `/lib/components/Navigation.dart` - Monitoreo de autofill

## Testing

Para probar la funcionalidad:

1. **Activar el servicio:**
   - Ir a Configuración > Sistema > Autofill
   - Seleccionar THISJOWI

2. **Probar guardado:**
   - Abrir cualquier app (ej: Twitter, Instagram)
   - Escribir usuario y contraseña
   - Hacer login
   - THISJOWI debe mostrar el diálogo de guardado

3. **Probar autocompletar:**
   - Abrir la misma app
   - Tocar el campo de usuario
   - Debe aparecer "THISJOWI - Tap to autofill"
   - Seleccionar y autenticar

4. **Probar con navegador:**
   - Abrir Chrome
   - Ir a cualquier sitio con login
   - Escribir credenciales
   - Debe detectar la URL correctamente
