# Guía de Activación de Autofill - THISJOWI

Esta guía explica cómo activar el gestor de contraseñas de THISJOWI en cada plataforma.

---

## 📱 Android

### Requisitos
- Android 8.0 (Oreo) o superior
- THISJOWI instalado

### Pasos de Activación

1. **Abrir Configuración del Sistema**
   - Ve a `Configuración` → `Sistema`

2. **Acceder a Idiomas y Entrada**
   - Toca `Idiomas y entrada` o `Languages & input`

3. **Configurar Servicio de Autocompletar**
   - Busca `Servicio de autocompletar` o `Autofill service`
   - Toca en la opción actual

4. **Seleccionar THISJOWI**
   - En la lista, selecciona `THISJOWI`
   - Confirma la selección

5. **Verificar Activación**
   - Abre cualquier app (ej: Twitter, Instagram)
   - Toca un campo de usuario/contraseña
   - Deberías ver "THISJOWI - Tap to autofill" en la barra superior

### Solución de Problemas

**No aparece THISJOWI en la lista:**
- Reinstala la app
- Verifica que tienes Android 8.0+
- Reinicia el dispositivo

**No se muestran sugerencias:**
- Verifica que has guardado al menos una contraseña
- Asegúrate de que THISJOWI está seleccionado en Configuración
- Prueba en modo incógnito del navegador

---

## 🍎 iOS / iPadOS

### Requisitos
- iOS 12 o superior
- THISJOWI instalado
- Cuenta de Apple ID

### Pasos de Activación

1. **Abrir Ajustes de iOS**
   - Ve a `Ajustes` (Settings)

2. **Acceder a Contraseñas**
   - Toca `Contraseñas` (Passwords)
   - Autentica con Face ID / Touch ID / Código

3. **Configurar Autorrellenar Contraseñas**
   - Toca `Opciones de autorrellenar contraseñas` (AutoFill Passwords)

4. **Activar THISJOWI**
   - Activa el interruptor junto a `THISJOWI`
   - Puedes desactivar iCloud Keychain si prefieres usar solo THISJOWI

5. **Verificar Activación**
   - Abre Safari o cualquier app
   - Toca un campo de usuario/contraseña
   - Deberías ver sugerencias de THISJOWI en la barra QuickType

### Características iOS

- **QuickType Bar**: Sugerencias automáticas sobre el teclado
- **Face ID / Touch ID**: Autenticación biométrica para acceder
- **Safari Integration**: Funciona perfectamente en Safari
- **App Integration**: Compatible con apps nativas de iOS

### Solución de Problemas

**No aparece THISJOWI:**
- Asegúrate de tener iOS 12+
- Reinstala la app
- Verifica que la extensión está instalada

**No se muestran sugerencias:**
- Guarda al menos una contraseña en THISJOWI
- Verifica que THISJOWI está activado en Ajustes
- Reinicia la app

---

## 💻 macOS

### Requisitos
- macOS 11 (Big Sur) o superior
- THISJOWI instalado

### Pasos de Activación

1. **Abrir Preferencias del Sistema**
   - Click en el menú Apple → `Preferencias del Sistema`

2. **Acceder a Contraseñas**
   - Click en `Contraseñas` (Passwords)
   - Autentica con Touch ID / Contraseña

3. **Configurar Extensión de Contraseñas**
   - Click en el icono de opciones (⋯)
   - Selecciona `Preferencias de extensión de contraseñas`

4. **Activar THISJOWI**
   - Marca la casilla junto a `THISJOWI`
   - Confirma la activación

5. **Verificar Activación**
   - Abre Safari
   - Ve a cualquier sitio con login
   - Deberías ver sugerencias de THISJOWI

### Características macOS

- **Safari Integration**: Integración nativa con Safari
- **Touch ID**: Autenticación rápida con Touch ID
- **Universal Clipboard**: Sincroniza con iOS (si usas iCloud)
- **Keyboard Shortcuts**: Atajos de teclado personalizables

### Solución de Problemas

**No aparece en la lista:**
- Verifica que tienes macOS 11+
- Reinstala THISJOWI
- Revisa permisos de la app

---

## 🪟 Windows

### Requisitos
- Windows 10 versión 1809 o superior
- THISJOWI instalado

### Opción 1: Credential Provider (Nativo)

1. **Instalar Credential Provider**
   - THISJOWI instalará automáticamente el proveedor
   - Puede requerir permisos de administrador

2. **Verificar Instalación**
   - Abre `Panel de Control` → `Cuentas de usuario`
   - Ve a `Administrador de credenciales`
   - Deberías ver credenciales de THISJOWI

3. **Usar en Navegadores**
   - Chrome, Edge y Firefox detectarán automáticamente
   - Las sugerencias aparecerán al hacer click en campos

### Opción 2: Extensión de Navegador (Recomendado)

1. **Instalar Extensión**
   - **Chrome/Edge**: [Chrome Web Store]
   - **Firefox**: [Firefox Add-ons]

2. **Conectar con la App**
   - La extensión detectará THISJOWI automáticamente
   - Si no, click en el icono → `Conectar con app`

3. **Configurar**
   - Permite permisos de la extensión
   - Configura atajos de teclado (opcional)

### Características Windows

- **Windows Hello**: Autenticación biométrica
- **Edge Integration**: Integración perfecta con Edge
- **Chrome/Firefox**: Compatible con extensiones
- **Credential Manager**: Sincroniza con Windows

---

## 🐧 Linux

### Requisitos
- Distribución moderna (Ubuntu 20.04+, Fedora 34+, etc.)
- THISJOWI instalado
- Navegador web (Chrome, Firefox, Brave)

### Instalación de Extensión

1. **Instalar Extensión de Navegador**
   - **Chrome/Chromium**: [Chrome Web Store]
   - **Firefox**: [Firefox Add-ons]

2. **Instalar Native Messaging Host**
   ```bash
   # El instalador de THISJOWI hace esto automáticamente
   # O manualmente:
   ~/.config/thisjowi/install-native-host.sh
   ```

3. **Verificar Conexión**
   - Abre la extensión
   - Debería mostrar "Conectado a THISJOWI"

### Características Linux

- **libsecret Integration**: Almacenamiento seguro
- **GNOME Keyring**: Compatible con GNOME
- **KWallet**: Compatible con KDE
- **Browser Extensions**: Chrome, Firefox, Brave

### Distribuciones Soportadas

- ✅ Ubuntu / Debian
- ✅ Fedora / RHEL
- ✅ Arch Linux
- ✅ openSUSE
- ✅ Pop!_OS
- ✅ Manjaro

---

## 🌐 Web (PWA)

### Requisitos
- Navegador moderno (Chrome 90+, Firefox 88+, Safari 14+)
- Extensión de navegador instalada

### Instalación

1. **Instalar Extensión**
   - **Chrome**: [Chrome Web Store]
   - **Firefox**: [Firefox Add-ons]
   - **Edge**: [Edge Add-ons]
   - **Safari**: [Safari Extensions]

2. **Iniciar Sesión en THISJOWI Web**
   - Ve a `app.thisjowi.com`
   - Inicia sesión con tu cuenta

3. **Conectar Extensión**
   - Click en el icono de THISJOWI en la barra
   - Click en `Conectar con cuenta`
   - Autentica

4. **Usar Autofill**
   - Las sugerencias aparecerán automáticamente
   - Click en el icono de THISJOWI en campos de login

### Características Web

- **Cross-Browser**: Funciona en todos los navegadores
- **Cloud Sync**: Sincronización en tiempo real
- **No Installation**: No requiere app nativa
- **Portable**: Úsalo en cualquier computadora

---

## 🔒 Seguridad

### Encriptación

Cada plataforma usa su método de encriptación nativo:

- **Android**: Android Keystore
- **iOS/macOS**: Keychain (AES-256)
- **Windows**: DPAPI (Data Protection API)
- **Linux**: libsecret (GNOME Keyring / KWallet)
- **Web**: Web Crypto API (AES-GCM)

### Autenticación

- **Biometría**: Face ID, Touch ID, Windows Hello, Fingerprint
- **PIN/Password**: Código de seguridad
- **2FA**: Autenticación de dos factores (opcional)

### Sincronización

- **E2EE**: End-to-end encryption
- **TLS 1.3**: Comunicación segura
- **Zero-Knowledge**: El servidor no puede leer tus contraseñas

---

## 📊 Comparación de Plataformas

| Característica | Android | iOS | macOS | Windows | Linux | Web |
|----------------|---------|-----|-------|---------|-------|-----|
| Autofill Nativo | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| Extensión Navegador | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Biometría | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ |
| Apps Nativas | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| Sincronización | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Offline | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

**Leyenda:**
- ✅ Completamente soportado
- ⚠️ Parcialmente soportado
- ❌ No soportado

---

## 🆘 Soporte

### Problemas Comunes

**"No se muestran sugerencias"**
1. Verifica que THISJOWI está activado
2. Guarda al menos una contraseña
3. Reinicia la app/navegador

**"No puedo activar THISJOWI"**
1. Verifica la versión del SO
2. Reinstala la app
3. Revisa permisos

**"Las contraseñas no se sincronizan"**
1. Verifica conexión a internet
2. Inicia sesión nuevamente
3. Fuerza sincronización en Configuración

### Contacto

- **Email**: support@thisjowi.com
- **Discord**: [discord.gg/thisjowi]
- **GitHub**: [github.com/thisjowi/issues]
- **Twitter**: [@thisjowi]

---

## 🎯 Próximos Pasos

Después de activar autofill:

1. **Importar contraseñas** desde otros gestores
2. **Configurar generador** de contraseñas seguras
3. **Activar 2FA** para mayor seguridad
4. **Compartir contraseñas** con tu equipo (Business)
5. **Revisar seguridad** de contraseñas existentes

---

**¡Listo!** 🎉 Ahora THISJOWI gestionará tus contraseñas en todas tus plataformas.
