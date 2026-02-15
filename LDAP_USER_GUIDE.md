# 🔐 Guía Completa: Login con Active Directory / LDAP en THISJOWI

## 📋 Tabla de Contenidos

1. [¿Qué es LDAP/Active Directory?](#qué-es-ldapactive-directory)
2. [¿Cómo funciona en THISJOWI?](#cómo-funciona-en-thisjowi)
3. [Guía para Usuarios](#guía-para-usuarios)
4. [Guía para Administradores](#guía-para-administradores)
5. [Configuración Técnica](#configuración-técnica)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 ¿Qué es LDAP/Active Directory?

**LDAP** (Lightweight Directory Access Protocol) y **Active Directory** (AD) son sistemas de autenticación corporativa que permiten a las empresas gestionar usuarios de forma centralizada.

### Ventajas para Empresas

✅ **Single Sign-On (SSO)** - Un solo usuario/contraseña para todas las apps  
✅ **Gestión Centralizada** - Administrar usuarios desde un solo lugar  
✅ **Seguridad** - Políticas de contraseñas corporativas  
✅ **Auditoría** - Registro de accesos y actividades  
✅ **Integración** - Compatible con Windows, macOS, Linux  

### Casos de Uso

- **Empresas con Active Directory** (Windows Server)
- **Organizaciones con OpenLDAP** (Linux)
- **Instituciones educativas**
- **Hospitales y centros médicos**
- **Gobierno y sector público**

---

## 🚀 ¿Cómo funciona en THISJOWI?

THISJOWI permite a las empresas usar su **Active Directory/LDAP existente** para autenticar usuarios, sin necesidad de crear cuentas separadas.

### Flujo de Autenticación

```
┌─────────────────────────────────────────────────────────────┐
│                    USUARIO CORPORATIVO                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Abre THISJOWI                                            │
│  2. Selecciona "Login Corporativo (LDAP)"                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Ingresa credenciales corporativas:                       │
│     • Dominio: ejemplo.com                                   │
│     • Usuario: juan.perez                                    │
│     • Contraseña: ********                                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. THISJOWI Backend valida contra Active Directory          │
│     ldap://ad.ejemplo.com:389                                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Si es válido, genera token JWT                           │
│  6. Usuario accede a THISJOWI                                │
└─────────────────────────────────────────────────────────────┘
```

### Arquitectura

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│              │         │              │         │              │
│   THISJOWI   │────────▶│   Backend    │────────▶│    Active    │
│     App      │         │   (Node.js)  │         │   Directory  │
│   (Flutter)  │◀────────│              │◀────────│   (LDAP)     │
│              │         │              │         │              │
└──────────────┘         └──────────────┘         └──────────────┘
      │                         │                         │
      │                         │                         │
   Usuario                   Valida                  Autentica
  Ingresa                 Credenciales              Credenciales
Credenciales              contra LDAP              Corporativas
```

---

## 👤 Guía para Usuarios

### Paso 1: Abrir THISJOWI

Abre la aplicación THISJOWI en tu dispositivo (móvil o desktop).

### Paso 2: Seleccionar Método de Autenticación

En la pantalla inicial, verás dos opciones:

```
┌─────────────────────────────────────────────┐
│                                             │
│  🏢  Login Corporativo (LDAP)               │
│      Para usuarios de empresas              │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│  👤  Cuenta Personal                        │
│      Para usuarios individuales             │
│                                             │
└─────────────────────────────────────────────┘
```

**Selecciona "Login Corporativo (LDAP)"**

### Paso 3: Ingresar Credenciales

Completa el formulario con tus credenciales corporativas:

```
┌─────────────────────────────────────────────┐
│  Dominio de la Empresa                      │
│  ┌───────────────────────────────────────┐  │
│  │ ejemplo.com                           │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Usuario LDAP                               │
│  ┌───────────────────────────────────────┐  │
│  │ juan.perez                            │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Contraseña                                 │
│  ┌───────────────────────────────────────┐  │
│  │ ••••••••••                            │  │
│  └───────────────────────────────────────┘  │
│                                             │
│         [ Iniciar Sesión ]                  │
│                                             │
└─────────────────────────────────────────────┘
```

**Campos:**

- **Dominio**: El dominio de tu empresa (ej: `miempresa.com`)
- **Usuario LDAP**: Tu usuario corporativo (ej: `juan.perez`, NO el email completo)
- **Contraseña**: Tu contraseña de Active Directory

### Paso 4: ¡Listo!

Si las credenciales son correctas, accederás automáticamente a THISJOWI con tu cuenta corporativa.

### 📝 Notas Importantes

- ✅ Usa las **mismas credenciales** que usas para iniciar sesión en tu computadora de trabajo
- ✅ El dominio debe estar **configurado** por tu administrador
- ✅ Si cambias tu contraseña en Active Directory, úsala aquí también
- ❌ **NO** uses tu email completo en el campo de usuario
- ❌ **NO** uses contraseñas de otras aplicaciones

### Ejemplo Real

**Empresa**: Acme Corporation  
**Dominio**: acme.com  
**Usuario Windows**: juan.perez  
**Contraseña**: MiPassword123!

**En THISJOWI:**
- Dominio: `acme.com`
- Usuario: `juan.perez`
- Contraseña: `MiPassword123!`

---

## 👨‍💼 Guía para Administradores

### Requisitos Previos

1. ✅ Servidor Active Directory / LDAP funcionando
2. ✅ Acceso administrativo al servidor LDAP
3. ✅ Cuenta de servicio LDAP (para bind)
4. ✅ Firewall configurado (puerto 389 o 636)

### Paso 1: Configurar Organización en THISJOWI

Como administrador, debes configurar la integración LDAP en THISJOWI:

#### 1.1 Acceder a Configuración

```
Menú → Organización → Configuración LDAP
```

#### 1.2 Completar Formulario

```
┌─────────────────────────────────────────────────────────┐
│  Configuración LDAP                                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Dominio de la Organización                             │
│  ┌────────────────────────────────────────────────────┐ │
│  │ acme.com                                           │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  URL del Servidor LDAP                                  │
│  ┌────────────────────────────────────────────────────┐ │
│  │ ldap://ad.acme.com:389                             │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Base DN                                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │ dc=acme,dc=com                                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Usuario de Servicio (Bind DN)                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ cn=thisjowi-service,ou=Services,dc=acme,dc=com     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Contraseña de Servicio                                 │
│  ┌────────────────────────────────────────────────────┐ │
│  │ ••••••••••                                         │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  Filtro de Búsqueda (opcional)                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ (objectClass=user)                                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ☑ Habilitar LDAP                                       │
│  ☑ Usar SSL/TLS (LDAPS)                                 │
│                                                          │
│         [ Probar Conexión ]  [ Guardar ]                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Paso 2: Probar Conexión

Antes de guardar, **siempre prueba la conexión**:

```bash
# El sistema verificará:
✅ Conectividad al servidor LDAP
✅ Credenciales de servicio válidas
✅ Base DN correcta
✅ Permisos de lectura
```

### Paso 3: Sincronizar Usuarios (Opcional)

Puedes sincronizar usuarios de LDAP a THISJOWI:

```
Configuración LDAP → [ Sincronizar Usuarios ]
```

Esto creará cuentas en THISJOWI para todos los usuarios de Active Directory.

---

## 🔧 Configuración Técnica

### Ejemplos de Configuración

#### Active Directory (Windows Server)

```yaml
Dominio: empresa.com
URL LDAP: ldap://dc01.empresa.com:389
Base DN: dc=empresa,dc=com
Bind DN: cn=thisjowi-svc,cn=Users,dc=empresa,dc=com
Filtro: (&(objectClass=user)(objectCategory=person))
```

#### OpenLDAP (Linux)

```yaml
Dominio: miorg.org
URL LDAP: ldap://ldap.miorg.org:389
Base DN: dc=miorg,dc=org
Bind DN: cn=admin,dc=miorg,dc=org
Filtro: (objectClass=inetOrgPerson)
```

#### Azure Active Directory

```yaml
Dominio: empresa.onmicrosoft.com
URL LDAP: ldaps://empresa.onmicrosoft.com:636
Base DN: dc=empresa,dc=onmicrosoft,dc=com
Bind DN: cn=thisjowi@empresa.onmicrosoft.com
SSL/TLS: Habilitado
```

### Puertos Comunes

- **389**: LDAP sin encriptar
- **636**: LDAPS (LDAP sobre SSL/TLS)
- **3268**: Global Catalog (AD)
- **3269**: Global Catalog SSL

### Atributos LDAP Utilizados

THISJOWI mapea los siguientes atributos:

| Atributo LDAP | Campo THISJOWI |
|---------------|----------------|
| `sAMAccountName` | Usuario |
| `mail` | Email |
| `displayName` | Nombre completo |
| `department` | Departamento |
| `title` | Cargo |
| `telephoneNumber` | Teléfono |

---

## 🔒 Seguridad

### Mejores Prácticas

1. **Usar LDAPS** (puerto 636) en producción
2. **Cuenta de servicio** con permisos mínimos (solo lectura)
3. **Firewall** restringir acceso al servidor LDAP
4. **Certificados SSL** válidos y actualizados
5. **Auditoría** monitorear intentos de login

### Permisos Requeridos

La cuenta de servicio LDAP necesita:

- ✅ Lectura de usuarios
- ✅ Lectura de grupos (opcional)
- ❌ NO necesita escritura
- ❌ NO necesita permisos administrativos

### Ejemplo de Cuenta de Servicio (PowerShell)

```powershell
# Crear usuario de servicio en AD
New-ADUser -Name "THISJOWI Service" `
           -SamAccountName "thisjowi-svc" `
           -UserPrincipalName "thisjowi-svc@empresa.com" `
           -Path "OU=Service Accounts,DC=empresa,DC=com" `
           -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
           -Enabled $true `
           -PasswordNeverExpires $true

# Dar permisos de lectura
Add-ADGroupMember -Identity "Domain Users" -Members "thisjowi-svc"
```

---

## 🆘 Troubleshooting

### Problema: "El dominio no tiene LDAP habilitado"

**Causa**: La organización no está configurada en THISJOWI

**Solución**:
1. Contacta a tu administrador
2. El admin debe configurar LDAP en THISJOWI
3. Verifica que el dominio sea correcto

---

### Problema: "Credenciales inválidas"

**Causa**: Usuario o contraseña incorrectos

**Solución**:
1. Verifica tu usuario (sin `@dominio.com`)
2. Usa la contraseña de Active Directory
3. Prueba iniciar sesión en tu PC con las mismas credenciales
4. Si olvidaste tu contraseña, contacta a IT

---

### Problema: "Error de conexión con servidor LDAP"

**Causa**: Servidor LDAP no accesible

**Solución** (Administradores):
1. Verifica que el servidor LDAP esté funcionando
2. Revisa firewall (puerto 389/636)
3. Prueba conectividad: `telnet ldap.empresa.com 389`
4. Verifica DNS: `nslookup ldap.empresa.com`

---

### Problema: "Timeout al conectarse"

**Causa**: Red lenta o servidor sobrecargado

**Solución**:
1. Verifica tu conexión a internet
2. Intenta nuevamente en unos minutos
3. Contacta a IT si persiste

---

### Problema: "Base DN incorrecta"

**Causa**: Configuración incorrecta del Base DN

**Solución** (Administradores):

```bash
# Obtener Base DN correcto
ldapsearch -x -h ldap.empresa.com -b "" -s base namingContexts

# Ejemplo de salida:
# namingContexts: dc=empresa,dc=com
```

---

## 📊 Comparación: LDAP vs Regular

| Característica | LDAP/AD | Regular |
|----------------|---------|---------|
| **Gestión** | Centralizada (IT) | Individual |
| **Contraseña** | Corporativa | Personal |
| **Cambio de contraseña** | En AD (afecta todo) | Solo THISJOWI |
| **Seguridad** | Políticas corporativas | Políticas de app |
| **Auditoría** | Logs corporativos | Logs de app |
| **SSO** | Posible | No |
| **Ideal para** | Empresas | Usuarios individuales |

---

## 🎓 Casos de Uso Reales

### Caso 1: Empresa Mediana (100-500 empleados)

**Escenario**: Empresa con Active Directory existente

**Configuración**:
- Todos los empleados usan credenciales corporativas
- Sincronización automática de usuarios
- Desactivación automática al salir de la empresa

**Beneficios**:
- ✅ Sin gestión manual de usuarios
- ✅ Seguridad mejorada
- ✅ Onboarding/offboarding automático

---

### Caso 2: Universidad

**Escenario**: Universidad con OpenLDAP

**Configuración**:
- Estudiantes y profesores usan credenciales universitarias
- Grupos LDAP para permisos (estudiantes, profesores, admin)
- Acceso temporal para estudiantes

**Beneficios**:
- ✅ Integración con sistema existente
- ✅ Gestión por semestre
- ✅ Permisos basados en roles

---

### Caso 3: Hospital

**Escenario**: Hospital con requisitos de auditoría

**Configuración**:
- Personal médico usa credenciales hospitalarias
- Auditoría completa de accesos
- Cumplimiento HIPAA

**Beneficios**:
- ✅ Trazabilidad completa
- ✅ Cumplimiento normativo
- ✅ Seguridad mejorada

---

## 📚 Recursos Adicionales

### Documentación

- [RFC 4511 - LDAP Protocol](https://tools.ietf.org/html/rfc4511)
- [Microsoft Active Directory](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
- [OpenLDAP Documentation](https://www.openldap.org/doc/)

### Herramientas Útiles

- **LDAP Admin** (Windows) - GUI para gestionar LDAP
- **Apache Directory Studio** (Cross-platform) - Cliente LDAP
- **ldapsearch** (CLI) - Herramienta de línea de comandos

### Comandos Útiles

```bash
# Probar conexión LDAP
ldapsearch -x -H ldap://servidor.com -D "cn=admin,dc=empresa,dc=com" -W

# Buscar usuario
ldapsearch -x -H ldap://servidor.com -b "dc=empresa,dc=com" "(sAMAccountName=juan.perez)"

# Verificar certificado SSL
openssl s_client -connect servidor.com:636 -showcerts
```

---

## 🎯 Próximos Pasos

### Para Usuarios

1. ✅ Contacta a tu administrador para verificar si LDAP está habilitado
2. ✅ Obtén tus credenciales corporativas
3. ✅ Inicia sesión en THISJOWI con LDAP

### Para Administradores

1. ✅ Configura LDAP en THISJOWI
2. ✅ Prueba la conexión
3. ✅ Sincroniza usuarios
4. ✅ Comunica a los empleados

---

## 📞 Soporte

¿Necesitas ayuda?

- **Usuarios**: Contacta a tu departamento de IT
- **Administradores**: support@thisjowi.com
- **Documentación**: [docs.thisjowi.com/ldap](https://docs.thisjowi.com/ldap)

---

**Última actualización**: Febrero 2026  
**Versión**: 1.0  
**Estado**: ✅ Producción
