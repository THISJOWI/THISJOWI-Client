# Resumen de Implementación: Registro Interactivo

**Fecha:** 23 de Abril, 2026  
**Estado:** En progreso

---

## 📋 Descripción del Proyecto

Implementación de un flujo de registro interactivo de 3 pasos para la aplicación ThisJowi:

1. **Paso 1:** Selección de tipo de cuenta (Community vs Business)
2. **Paso 2:** Selección de modo de despliegue (Cloud vs SelfHosted)
3. **Paso 3:** Formulario de datos con campos dinámicos

---

## ✅ Completado

### Componentes UI Nuevos

| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `lib/components/account_type_selector.dart` | ✅ Creado | Selector minimalista de tipo de cuenta |
| `lib/components/deployment_mode_selector.dart` | ✅ Creado | Selector de modo de despliegue |
| `lib/components/country_selector.dart` | ✅ Creado | Selector desplegable de países (opcional) |

### Pantallas de Flujo

| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `lib/screens/auth/register_flow.dart` | ✅ Creado | Gestor del flujo de 3 pasos con navegación |

---

## 🔄 En Progreso / Pendiente

### Modificaciones de Archivos Existentes

| Archivo | Estado | Cambios Requeridos |
|---------|--------|-------------------|
| `lib/screens/auth/registerForm.dart` | 🔄 Pendiente | Añadir parámetros requeridos (accountType, hostingMode), país opcional, campo serverUrl para SelfHosted, prueba de conectividad |
| `lib/screens/auth/register.dart` | 🔄 Pendiente | Simplificar para usar RegisterFlowScreen |
| `lib/services/auth_service.dart` | 🔄 Pendiente | Actualizar método register() con nuevos parámetros |
| `lib/data/models/auth_user.dart` | 🔄 Pendiente | Añadir campos accountType, hostingMode, serverUrl |
| `lib/i18n/translations.dart` | 🔄 Pendiente | Añadir traducciones para nuevos textos |

---

## 🏗️ Arquitectura del Flujo

```
RegisterFlowScreen (Gestor principal)
    │
    ├── Paso 0: AccountTypeSelector
    │   └── Selecciona: "Community" o "Business"
    │
    ├── Paso 1: DeploymentModeSelector
    │   └── Selecciona: "Cloud" o "SelfHosted"
    │
    └── Paso 2: RegisterForm
        ├── Muestra resumen de selecciones
        ├── Campos: Nombre, Email, Contraseña
        ├── País: Selector opcional
        ├── URL Servidor: Solo si SelfHosted
        ├── [Probar Conexión]: Solo si SelfHosted
        └── [Crear Cuenta] / [Atrás]
```

---

## 🎨 Diseño Visual

### Pantalla 1: Tipo de Cuenta (Minimalista)
```
┌─────────────────────────────────────┐
│ Elige tu tipo de cuenta             │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────┐     │
│ │ 👤 Community Account        │     │
│ └─────────────────────────────┘     │
│                                     │
│ ┌─────────────────────────────┐     │
│ │ 💼 Business Account         │     │
│ └─────────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

### Pantalla 2: Modo de Despliegue
```
┌─────────────────────────────────────┐
│ ¿Cómo deseas desplegar?             │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────┐     │
│ │ ☁️ Cloud                    │     │
│ │ Nosotros gestionamos todo   │     │
│ └─────────────────────────────┘     │
│                                     │
│ ┌─────────────────────────────┐     │
│ │ 🖥️ Self-Hosted              │     │
│ │ Requiere servidor propio    │     │
│ └─────────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

### Pantalla 3: Formulario (SelfHosted)
```
┌─────────────────────────────────────┐
│ Completa tu registro                │
│                                     │
│ Tu selección:                       │
│ 👤 Business Account                 │
│ 🖥️ Self-Hosted                      │
│                                     │
│ ─────────────────────────────────── │
│                                     │
│ Nombre completo: [_______________] │
│ Email: [_______________]            │
│ Contraseña: [_______________]       │
│ País: [V Seleccionar ___] (opcional)│
│                                     │
│ URL del servidor: [_______________] │
│ (ej: https://mi.servidor.com)       │
│                                     │
│ [Probar conexión]                   │
│                                     │
│ [✓] Acepto términos                 │
│                                     │
│ [Atrás] [Crear Cuenta]              │
└─────────────────────────────────────┘
```

---

## ⚙️ Funcionalidades Específicas

### Requisitos Confirmados

| # | Requerimiento | Estado |
|---|---------------|--------|
| 1 | Pantalla 1 sin precios, solo orientativa | ✅ Implementado |
| 2 | País opcional | ✅ Implementado en CountrySelector |
| 3 | Permitir volver atrás entre pasos | ✅ Implementado en RegisterFlowScreen |
| 4 | SelfHosted: capturar URL del servidor | 🔄 Pendiente (en RegisterForm) |
| 5 | SelfHosted: prueba de conectividad | 🔄 Pendiente (en RegisterForm) |
| 6 | Selector de país (no texto libre) | ✅ Implementado |
| 7 | No guardar selecciones si abandona | ✅ Implementado (sin persistencia) |
| 8 | No analytics/tracking | ✅ Implementado (sin tracking) |

---

## 📁 Archivos Creados

```
lib/
├── components/
│   ├── account_type_selector.dart      ✅ Nuevo
│   ├── deployment_mode_selector.dart   ✅ Nuevo
│   └── country_selector.dart           ✅ Nuevo
│
└── screens/auth/
    └── register_flow.dart              ✅ Nuevo
```

---

## 📁 Archivos a Modificar

```
lib/
├── screens/auth/
│   ├── register.dart                   🔄 Pendiente
│   └── registerForm.dart               🔄 Pendiente
│
├── services/
│   └── auth_service.dart               🔄 Pendiente
│
├── data/models/
│   └── auth_user.dart                  🔄 Pendiente
│
└── i18n/
    └── translations.dart               🔄 Pendiente
```

---

## 🔧 Cambios Técnicos Pendientes

### 1. RegisterForm.dart
- [ ] Cambiar `accountType` y `hostingMode` a requeridos (no opcionales)
- [ ] Añadir parámetro `onBack` para navegación atrás
- [ ] Reemplazar campo de país texto por CountrySelector
- [ ] Añadir campo URL servidor (condicional a hostingMode == 'SelfHosted')
- [ ] Añadir botón "Probar conexión" (solo SelfHosted)
- [ ] Implementar lógica de prueba de conectividad HTTP
- [ ] Mostrar resumen de selecciones en la parte superior

### 2. AuthService.dart
- [ ] Actualizar método `register()` para aceptar:
  - `accountType` (requerido)
  - `hostingMode` (requerido)
  - `country` (opcional)
  - `serverUrl` (opcional, solo SelfHosted)

### 3. AuthUser.dart
- [ ] Añadir campos al modelo:
  - `accountType` (String)
  - `hostingMode` (String)
  - `serverUrl` (String?, opcional)
- [ ] Actualizar `fromJson()` y `toJson()`

### 4. Translations.dart
- [ ] Añadir claves:
  - `select_account_type`
  - `community_account`
  - `business_account`
  - `select_deployment`
  - `cloud_deployment`
  - `cloud_desc`
  - `selfhosted_deployment`
  - `selfhosted_desc`
  - `country_optional`
  - `server_url_label`
  - `server_url_hint`
  - `test_connection`
  - `testing_connection`
  - `connection_success`
  - `connection_failed`

---

## 🎯 Próximos Pasos

1. **Modificar RegisterForm.dart**
   - Integrar los nuevos parámetros
   - Añadir UI para serverUrl y prueba de conexión
   - Integrar CountrySelector

2. **Actualizar AuthService.dart**
   - Modificar método register()

3. **Actualizar AuthUser.dart**
   - Añadir nuevos campos al modelo

4. **Modificar Register.dart**
   - Simplificar para usar RegisterFlowScreen

5. **Agregar Traducciones**
   - Actualizar translations.dart

6. **Pruebas**
   - Flujo completo de registro
   - Navegación entre pasos
   - Prueba de conectividad SelfHosted

---

## 📝 Notas

- **Backend:** Ya soporta los nuevos campos (`accountType`, `hostingMode`, `serverUrl`)
- **Kafka:** Los eventos sincronizarán automáticamente Account y Profile services
- **Diseño:** Se mantiene el estilo glassmorphism existente de la app
- **Navegación:** El usuario puede volver atrás en cualquier paso (excepto el primero)

---

**Última actualización:** 23 Abril 2026 - 15:15  
**Próxima revisión:** Al completar RegisterForm.dart
