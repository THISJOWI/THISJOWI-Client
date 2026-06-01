import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byText("en") +
      // ==================== GENERAL ====================
      {
        "en": "Cancel",
        "es": "Cancelar",
      } +
      {
        "en": "Delete",
        "es": "Eliminar",
      } +
      {
        "en": "Save",
        "es": "Guardar",
      } +
      {
        "en": "Close",
        "es": "Cerrar",
      } +
      {
        "en": "Edit",
        "es": "Editar",
      } +
      {
        "en": "Create",
        "es": "Crear",
      } +
      {
        "en": "Search",
        "es": "Buscar",
      } +
      {
        "en": "Error",
        "es": "Error",
      } +
      {
        "en": "Success",
        "es": "Éxito",
      } +
      {
        "en": "Loading...",
        "es": "Cargando...",
      } +
      {
        "en": "Yes",
        "es": "Sí",
      } +
      {
        "en": "No",
        "es": "No",
      } +
      {
        "en": "Confirm",
        "es": "Confirmar",
      } +
      {
        "en": "or",
        "es": "o",
      } +
      {
        "en": "Use %s",
        "es": "Usar %s",
      } +

      // ==================== AUTH ====================
      {
        "en": "Welcome Back",
        "es": "Bienvenido de nuevo",
      } +
      {
        "en": "Sign in to continue",
        "es": "Inicia sesión para continuar",
      } +
      {
        "en": "Email",
        "es": "Correo electrónico",
      } +
      {
        "en": "Password",
        "es": "Contraseña",
      } +
      {
        "en": "Login",
        "es": "Iniciar sesión",
      } +
      {
        "en": "Register",
        "es": "Registrarse",
      } +
      {
        "en": "Logout",
        "es": "Cerrar sesión",
      } +
      {
        "en": "Create Account",
        "es": "Crear cuenta",
      } +
      {
        "en": "Sign up to get started",
        "es": "Regístrate para comenzar",
      } +
      {
        "en": "Please complete all fields",
        "es": "Por favor completa todos los campos",
      } +
      {
        "en": "Account created! Syncing in background...",
        "es": "¡Cuenta creada! Sincronizando en segundo plano...",
      } +
      {
        "en": "Register failed",
        "es": "Error en el registro",
      } +
      {
        "en": "Invalid credentials",
        "es": "Credenciales inválidas",
      } +
      {
        "en": "Logged in successfully",
        "es": "Sesión iniciada correctamente",
      } +
      {
        "en": "Logged in offline mode",
        "es": "Sesión iniciada en modo offline",
      } +
      {
        "en": "No internet connection. You need to login online at least once.",
        "es":
            "Sin conexión a internet. Necesitas iniciar sesión en línea al menos una vez.",
      } +
      {
        "en": "This user already exists locally. Please sign in.",
        "es": "Este usuario ya existe localmente. Por favor, inicia sesión.",
      } +
      {
        "en":
            "This user is already in the sync queue. Please wait for it to complete.",
        "es":
            "Este usuario ya está en la cola de sincronización. Por favor, espera a que se complete.",
      } +

      // ==================== PASSWORDS ====================
      {
        "en": "Passwords",
        "es": "Contraseñas",
      } +
      {
        "en": "Search passwords",
        "es": "Buscar contraseñas",
      } +
      {
        "en": "No passwords stored",
        "es": "No hay contraseñas guardadas",
      } +
      {
        "en": "Add Password",
        "es": "Agregar contraseña",
      } +
      {
        "en": "Edit Password",
        "es": "Editar contraseña",
      } +
      {
        "en": "Delete password?",
        "es": "¿Eliminar contraseña?",
      } +
      {
        "en": "Password deleted",
        "es": "Contraseña eliminada",
      } +
      {
        "en": "Password copied",
        "es": "Contraseña copiada",
      } +
      {
        "en": "User copied",
        "es": "Usuario copiado",
      } +
      {
        "en": "User",
        "es": "Usuario",
      } +
      {
        "en": "Title",
        "es": "Título",
      } +
      {
        "en": "Username",
        "es": "Usuario",
      } +
      {
        "en": "Website",
        "es": "Sitio web",
      } +
      {
        "en": "New Password",
        "es": "Nueva contraseña",
      } +
      {
        "en": "Confirm Password",
        "es": "Confirmar contraseña",
      } +
      {
        "en": "Current Password",
        "es": "Contraseña actual",
      } +
      {
        "en": "Please enter a title",
        "es": "Por favor ingresa un título",
      } +
      {
        "en": "Please enter a password",
        "es": "Por favor ingresa una contraseña",
      } +
      {
        "en": "Please enter a username",
        "es": "Por favor ingresa un usuario",
      } +
      {
        "en": "Website must start with http:// or https://",
        "es": "El sitio web debe comenzar con http:// o https://",
      } +
      {
        "en": "Please fix the highlighted fields",
        "es": "Por favor corrige los campos marcados",
      } +
      {
        "en": "Password created successfully",
        "es": "Contraseña creada exitosamente",
      } +
      {
        "en": "Create Password",
        "es": "Crear contraseña",
      } +
      {
        "en": "Save Changes",
        "es": "Guardar cambios",
      } +
      {
        "en": "Error saving password",
        "es": "Error al guardar contraseña",
      } +

      // ==================== MESSAGES ====================
      {
        "en": "Messages",
        "es": "Mensajes",
      } +
      {
        "en": "No messages yet",
        "es": "Sin mensajes aún",
      } +

      // ==================== NOTES ====================
      {
        "en": "Notes",
        "es": "Notas",
      } +
      {
        "en": "Search notes",
        "es": "Buscar notas",
      } +
      {
        "en": "No notes yet",
        "es": "Aún no hay notas",
      } +
      {
        "en": "Add Note",
        "es": "Agregar nota",
      } +
      {
        "en": "Edit Note",
        "es": "Editar nota",
      } +
      {
        "en": "Delete note?",
        "es": "¿Eliminar nota?",
      } +
      {
        "en": "Note deleted",
        "es": "Nota eliminada",
      } +
      {
        "en": "Error deleting note",
        "es": "Error al eliminar nota",
      } +
      {
        "en": "Content",
        "es": "Contenido",
      } +

 // ==================== SETTINGS ====================
    {
      "en": "Settings",
      "es": "Configuración",
    } +
    {
      "en": "Profile",
      "es": "Perfil",
    } +
    {
      "en": "Hosting Mode",
      "es": "Modo de Hosting",
    } +
    {
      "en": "Update hosting mode",
      "es": "Actualizar modo de hosting",
    } +
    {
      "en": "Organization",
      "es": "Organización",
    } +
    {
      "en": "LDAP Configuration",
      "es": "Configuración LDAP",
    } +
    {
      "en": "Manage LDAP settings",
      "es": "Gestionar configuración LDAP",
    } +
    {
      "en": "Security",
      "es": "Seguridad",
    } +
    {
      "en": "Change Password",
      "es": "Cambiar contraseña",
    } +
    {
      "en": "Update your password",
      "es": "Actualiza tu contraseña",
    } +
    {
      "en": "Information",
      "es": "Información",
    } +
    {
      "en": "Application Version",
      "es": "Versión de la aplicación",
    } +
    {
      "en": "Account & Privacy",
      "es": "Cuenta y privacidad",
    } +
    {
      "en": "Account",
      "es": "Cuenta",
    } +
    {
      "en": "Delete Account",
      "es": "Eliminar cuenta",
    } +
    {
      "en": "This action cannot be undone",
      "es": "Esta acción no se puede deshacer",
    } +
      {
        "en":
            "Are you sure you want to delete your account? This action cannot be undone.",
        "es":
            "¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.",
      } +
      {
        "en": "Are you sure you want to logout?",
        "es": "¿Estás seguro de que deseas cerrar sesión?",
      } +
      {
        "en": "Account deleted successfully",
        "es": "Cuenta eliminada exitosamente",
      } +
      {
        "en": "Error deleting account",
        "es": "Error al eliminar cuenta",
      } +
      {
        "en": "Confirm Deletion",
        "es": "Confirmar eliminación",
      } +
      {
        "en": "Enter your password to confirm account deletion.",
        "es": "Ingresa tu contraseña para confirmar la eliminación de la cuenta.",
      } +
      {
        "en": "Please enter your password",
        "es": "Por favor ingresa tu contraseña",
      } +
      {
        "en": "Please complete the new password",
        "es": "Por favor completa la nueva contraseña",
      } +
      {
        "en": "The new passwords do not match",
        "es": "Las nuevas contraseñas no coinciden",
      } +
      {
        "en": "Password must be at least 6 characters",
        "es": "La contraseña debe tener al menos 6 caracteres",
      } +
      {
        "en": "Password changed successfully",
        "es": "Contraseña cambiada exitosamente",
      } +
      {
        "en": "Failed to change password",
        "es": "Error al cambiar contraseña",
      } +
      {
        "en": "Error changing password",
        "es": "Error al cambiar contraseña",
      } +
      {
        "en": "Change",
        "es": "Cambiar",
      } +

      // ==================== DEBUG ====================
      {
        "en": "This will delete ALL local data:",
        "es": "Esto eliminará TODOS los datos locales:",
      } +
      {
        "en": "All notes",
        "es": "Todas las notas",
      } +
      {
        "en": "All passwords",
        "es": "Todas las contraseñas",
      } +
      {
        "en": "Cached credentials",
        "es": "Credenciales en caché",
      } +
      {
        "en": "Sync queue",
        "es": "Cola de sincronización",
      } +
      {
        "en": "Are you sure?",
        "es": "¿Estás seguro?",
      } +
      {
        "en": "Yes, Delete All",
        "es": "Sí, eliminar todo",
      } +
      {
        "en": "Database deleted. Restart the app.",
        "es": "Base de datos eliminada. Reinicia la aplicación.",
      } +

      // ==================== OTP ====================
      {
        "en": "Code copied",
        "es": "Código copiado",
      } +
      {
        "en": "Add OTP",
        "es": "Añadir OTP",
      } +
      {
        "en": "Account name",
        "es": "Nombre de cuenta",
      } +
      {
        "en": "Issuer",
        "es": "Emisor",
      } +
      {
        "en": "Secret key",
        "es": "Clave secreta",
      } +
      {
        "en": "Name and secret are required",
        "es": "Nombre y clave son requeridos",
      } +
      {
        "en": "Invalid secret key",
        "es": "Clave secreta inválida",
      } +
      {
        "en": "OTP added",
        "es": "OTP añadido",
      } +
      {
        "en": "Import OTP URI",
        "es": "Importar URI OTP",
      } +
      {
        "en": "Paste the otpauth:// URI from your authenticator app",
        "es": "Pega la URI otpauth:// de tu app autenticadora",
      } +
      {
        "en": "OTP URI",
        "es": "URI OTP",
      } +
      {
        "en": "Import",
        "es": "Importar",
      } +
      {
        "en": "Invalid OTP URI",
        "es": "URI OTP inválida",
      } +
      {
        "en": "OTP imported",
        "es": "OTP importado",
      } +
      {
        "en": "Delete OTP?",
        "es": "¿Eliminar OTP?",
      } +
      {
        "en": "Are you sure you want to delete",
        "es": "¿Estás seguro de que deseas eliminar",
      } +
      {
        "en": "OTP deleted",
        "es": "OTP eliminado",
      } +
      {
        "en": "Authenticator",
        "es": "Autenticador",
      } +
      {
        "en": "Import URI",
        "es": "Importar URI",
      } +
      {
        "en": "Scan QR",
        "es": "Escanear QR",
      } +
      {
        "en": "No OTP entries yet",
        "es": "Aún no hay entradas OTP",
      } +
      {
        "en": "Add your first authenticator code",
        "es": "Añade tu primer código de autenticación",
      } +
      {
        "en": "Add manually",
        "es": "Añadir manualmente",
      } +
      {
        "en": "Tap to copy",
        "es": "Toca para copiar",
      } +
      {
        "en": "Invalid OTP Entry",
        "es": "Entrada OTP inválida",
      } +
      {
        "en": "Secret key is corrupted",
        "es": "La clave secreta está corrupta",
      } +

      // ==================== SYNC ====================
      {
        "en": "Syncing in background...",
        "es": "Sincronizando en segundo plano...",
      } +
      {
        "en": "Sync complete",
        "es": "Sincronización completa",
      } +
      {
        "en": "Sync failed",
        "es": "Error de sincronización",
      } +
      {
        "en": "Offline",
        "es": "Sin conexión",
      } +
      {
        "en": "Online",
        "es": "En línea",
      } +
      {
        "en": "Sync Panel",
        "es": "Panel de Sincronización",
      } +
      {
        "en": "Registrations",
        "es": "Registros",
      } +
      {
        "en": "Sync Now",
        "es": "Sincronizar Ahora",
      } +
      {
        "en": "Syncing...",
        "es": "Sincronizando...",
      } +
      {
        "en": "Sync Successful",
        "es": "Sincronización Exitosa",
      } +
      {
        "en": "Sync Error",
        "es": "Error en Sincronización",
      } +
      {
        "en": "pending",
        "es": "pendiente",
      } +

      // ==================== AUTH ADDITIONAL ====================
      {
        "en": "Welcome",
        "es": "Bienvenido",
      } +
      {
        "en": "Sign in to your account",
        "es": "Inicia sesión en tu cuenta",
      } +
      {
        "en": "Sign In",
        "es": "Iniciar sesión",
      } +
      {
        "en": "Don't have an account? ",
        "es": "¿No tienes una cuenta? ",
      } +
      {
        "en": "Sign Up",
        "es": "Registrarse",
      } +
      {
        "en": "Already have an account? ",
        "es": "¿Ya tienes una cuenta? ",
      } +
      {
        "en": "Create account",
        "es": "Crear cuenta",
      } +
      {
        "en": "Please complete email and password",
        "es": "Por favor completa el correo y contraseña",
      } +
      {
        "en": "Login failed",
        "es": "Error al iniciar sesión",
      } +
      {
        "en": "Forgot Password?",
        "es": "¿Olvidaste tu contraseña?",
      } +
      {
        "en": "Congrats! Account created successfully",
        "es": "¡Felicidades! Cuenta creada exitosamente",
      } +
      {
        "en": "Please enter your email",
        "es": "Por favor ingresa tu correo",
      } +
      {
        "en": "OTP sent to your email",
        "es": "OTP enviado a tu correo",
      } +
      {
        "en": "An error occurred",
        "es": "Ocurrió un error",
      } +
      {
        "en": "Send OTP",
        "es": "Enviar OTP",
      } +
      {
        "en": "Please enter the code",
        "es": "Por favor ingresa el código",
      } +
      {
        "en": "Code verified. Set new password.",
        "es": "Código verificado. Establece nueva contraseña.",
      } +
      {
        "en": "Invalid code",
        "es": "Código inválido",
      } +
      {
        "en": "Connection error",
        "es": "Error de conexión",
      } +
      {
        "en": "Please enter new password",
        "es": "Por favor ingresa la nueva contraseña",
      } +
      {
        "en": "Passwords do not match",
        "es": "Las contraseñas no coinciden",
      } +
      {
        "en": "Password reset successfully",
        "es": "Contraseña restablecida exitosamente",
      } +
      {
        "en": "Failed to reset password",
        "es": "Error al restablecer la contraseña",
      } +
      {
        "en": "Set New Password",
        "es": "Establecer nueva contraseña",
      } +
      {
        "en": "Verification Code",
        "es": "Código de verificación",
      } +
      {
        "en": "Please enter your new password.",
        "es": "Por favor ingresa tu nueva contraseña.",
      } +
      {
        "en": "We sent a verification code to your email.",
        "es": "Enviamos un código de verificación a tu correo.",
      } +
      {
        "en": "Verify Code",
        "es": "Verificar código",
      } +
      {
        "en": "Reset Password",
        "es": "Restablecer contraseña",
      } +
      {
        "en": "Incorrect password for local user",
        "es": "Contraseña incorrecta para usuario local",
      } +
      {
        "en": "Offline login error: %s",
        "es": "Error en login offline: %s",
      } +
      {
        "en": "No results found",
        "es": "No encontramos resultados",
      } +
      {
        "en": "No server connection and user does not exist locally",
        "es": "No hay conexión al servidor y el usuario no existe localmente",
      } +
      {
        "en": "Conversations",
        "es": "Conversaciones",
      } +
      {
        "en": "Find someone",
        "es": "Encuentra a alguien",
      } +

      // ==================== NOTES ADDITIONAL ====================
      {
        "en": "Delete Note?",
        "es": "¿Eliminar nota?",
      } +
      {
        "en": "Are you sure you want to delete",
        "es": "¿Estás seguro de que deseas eliminar",
      } +
      {
        "en": "No have notes yet",
        "es": "Aún no tienes notas",
      } +
      {
        "en": "New Note",
        "es": "Nueva nota",
      } +
      {
        "en": "A note with this title already exists",
        "es": "Ya existe una nota con este título",
      } +
      {
        "en": "Please enter the content",
        "es": "Por favor ingresa el contenido",
      } +
      {
        "en": "Error loading notes",
        "es": "Error al cargar notas",
      } +
      {
        "en": "No Content",
        "es": "Sin contenido",
      } +
      {
        "en": "No Title",
        "es": "Sin título",
      } +
      {
        "en": "Done",
        "es": "Hecho",
      } +

      // ==================== PASSWORDS ADDITIONAL ====================
      {
        "en": "Delete Password?",
        "es": "¿Eliminar contraseña?",
      } +
      {
        "en": "No passwords yet",
        "es": "Aún no hay contraseñas",
      } +
      {
        "en": "Show Password",
        "es": "Mostrar contraseña",
      } +
      {
        "en": "Hide Password",
        "es": "Ocultar contraseña",
      } +

      // ==================== HOME ====================
      {
        "en": "No data yet",
        "es": "Aún no hay datos",
      } +

      // ==================== BIOMETRIC ====================
      {
        "en": "Biometric Authentication",
        "es": "Autenticación biométrica",
      } +
      {
        "en": "Use %s to unlock app",
        "es": "Usar %s para desbloquear",
      } +
      {
        "en": "App Locked",
        "es": "App bloqueada",
      } +
      {
        "en": "Authenticate to continue",
        "es": "Autentícate para continuar",
      } +
      {
        "en": "Authenticate to access THISECURE",
        "es": "Autentícate para acceder a THISECURE",
      } +
      {
        "en": "Authenticate to enable biometric lock",
        "es": "Autentícate para activar el bloqueo biométrico",
      } +
      {
        "en": "Authenticating...",
        "es": "Autenticando...",
      } +
      {
        "en": "Tap to use %s",
        "es": "Toca para usar %s",
      } +
      {
        "en": "Biometric not available",
        "es": "Biometría no disponible",
      } +
      {
        "en": "Your device does not support biometric authentication",
        "es": "Tu dispositivo no soporta autenticación biométrica",
      } +
      {
        "en": "Biometric enabled",
        "es": "Biometría activada",
      } +
      {
        "en": "Biometric disabled",
        "es": "Biometría desactivada",
      } +
      {
        "en": "Authentication failed",
        "es": "Autenticación fallida",
      } +
      {
        "en": "Please try again",
        "es": "Por favor intenta de nuevo",
      } +

      // ==================== ONBOARDING ====================
      {
        "en": "Welcome to THISECURE",
        "es": "Bienvenido a THISECURE",
      } +
      {
        "en": "Your productivity secured manager",
        "es": "Tu gestor de productividad seguro",
      } +
      {
        "en": "Secure Storage",
        "es": "Almacenamiento seguro",
      } +
      {
        "en": "All your passwords encrypted and safe",
        "es": "Todas tus contraseñas cifradas y seguras",
      } +
      {
        "en": "Offline Access",
        "es": "Acceso sin conexión",
      } +
      {
        "en": "Access your data anytime, anywhere",
        "es": "Accede en cualquier momento y lugar",
      } +
      {
        "en": "Synchronization",
        "es": "Sincronización",
      } +
      {
        "en": "Add your first password or note",
        "es": "Agregar tu primera contraseña o nota",
      } +
      {
        "en": "Keep your data synced",
        "es": "Mantén tus datos sincronizados",
      } +
      {
        "en": "Biometric Security",
        "es": "Seguridad biométrica",
      } +
      {
        "en": "Quick and secure access with your fingerprint",
        "es": "Acceso rápido y seguro con tu huella digital",
      } +
      {
        "en": "Get Started",
        "es": "Comenzar",
      } +
      {
        "en": "Next",
        "es": "Siguiente",
      } +
      {
        "en": "Skip",
        "es": "Omitir",
      } +
      {
        "en": "Back",
        "es": "Atrás",
      } +
      {
        "en": "Password Manager",
        "es": "Gestor de contraseñas",
      } +
      {
        "en":
            "Make THISECURE your primary password manager to automatically fill in data in all your applications.",
        "es":
            "Hacer de THISECURE tu gestor de contraseñas principal para completar datos automáticamente en todas tus aplicaciones.",
      } +
      {
        "en": "Later",
        "es": "Más tarde",
      } +
      {
        "en": "Configure",
        "es": "Configurar",
      } +
      {
        "en": "LDAP Login",
        "es": "Inicio de Sesión LDAP",
      } +
      {
        "en": "Empresarial",
        "es": "Empresarial",
      } +
      {
        "en": "Enterprise email",
        "es": "Correo empresarial",
      } +
      {
        "en": "Please enter your enterprise email",
        "es": "Por favor ingrese su correo empresarial",
      } +
      {
        "en": "Use corporate domain credentials",
        "es": "Usa tus credenciales de dominio corporativo",
      } +
      {
        "en": "Use standard login",
        "es": "Usa el inicio de sesión estándar",
      } +
      {
        "en": "LDAP Configuration",
        "es": "Configuración LDAP",
      } +
      {
        "en": "Connection Settings",
        "es": "Ajustes de Conexión",
      } +
      {
        "en": "User Search & Attributes",
        "es": "Búsqueda de Usuarios y Atributos",
      } +
      {
        "en": "Enable LDAP Login",
        "es": "Habilitar Inicio de Sesión LDAP",
      } +
      {
        "en": "Test Connection",
        "es": "Probar Conexión",
      } +
      {
        "en": "Save Configuration",
        "es": "Guardar Configuración",
      } +
      {
        "en": "LDAP URL",
        "es": "URL LDAP",
      } +
      {
        "en": "Base DN",
        "es": "DN Base",
      } +
      {
        "en": "Bind DN (Optional)",
        "es": "Bind DN (Opcional)",
      } +
      {
        "en": "Bind Password (Optional)",
        "es": "Contraseña Bind (Opcional)",
      } +
      {
        "en": "User Search Filter",
        "es": "Filtro de Búsqueda de Usuarios",
      } +
      {
        "en": "Email Attribute",
        "es": "Atributo de Email",
      } +
      {
        "en": "Full Name Attribute",
        "es": "Atributo de Nombre Completo",
      } +
      {
        "en": "No Organization ID found in session",
        "es": "No se encontró el ID de Organización en la sesión",
      } +
      {
        "en": "LDAP Configuration saved",
        "es": "Configuración LDAP guardada",
      } +
      {
        "en": "Enterprise Authentication",
        "es": "Autenticación Empresarial",
      } +
      {
        "en":
            "Do you want to integrate LDAP with your app for corporate domain authentication?",
        "es":
            "¿Quieres integrar LDAP para la autenticación de dominio corporativo?",
      } +
      {
        "en": "Yes, Enable LDAP",
        "es": "Sí, habilitar LDAP",
      } +
      {
        "en": "Allow users to authenticate using corporate LDAP credentials.",
        "es":
            "Permitir que los usuarios se autentiquen usando credenciales corporativas LDAP.",
      } +
      {
        "en": "No, Standard Auth",
        "es": "No, autenticación estándar",
      } +
      {
        "en": "Use regular email/password authentication.",
        "es": "Usar autenticación regular con correo y contraseña.",
      } +
{
"en":
"Configure your LDAP server details for enterprise authentication.",
"es":
"Configura los detalles de tu servidor LDAP para la autenticación empresarial.",
} +

// ==================== REGISTRO INTERACTIVO ====================
{
"en": "select_account_type",
"es": "Elige tu tipo de cuenta",
} +
{
"en": "community_account",
"es": "Community Account",
} +
{
"en": "business_account",
"es": "Business Account",
} +
{
"en": "select_deployment",
"es": "¿Cómo deseas desplegar?",
} +
{
"en": "cloud_deployment",
"es": "Cloud",
} +
{
"en": "cloud_desc",
"es": "Nosotros gestionamos la infraestructura",
} +
{
"en": "selfhosted_deployment",
"es": "Self-Hosted",
} +
{
"en": "selfhosted_desc",
"es": "Requiere servidor propio",
} +
{
"en": "back_button",
"es": "Atrás",
} +
{
"en": "continue_button",
"es": "Continuar",
} +
{
"en": "server_url_label",
"es": "URL del servidor",
} +
{
"en": "server_url_hint",
"es": "https://mi.servidor.com",
} +
{
"en": "country_optional",
"es": "País (opcional)",
} +
{
"en": "test_connection",
"es": "Probar conexión",
} +
{
"en": "testing_connection",
"es": "Probando conexión...",
} +
{
"en": "connection_success",
"es": "Conexión exitosa",
} +
{
"en": "connection_failed",
"es": "No se pudo conectar al servidor",
} +
{
    "en": "No selection",
    "es": "No seleccionar",
  } +
  {
    "en": "Completa tu registro",
    "es": "Completa tu registro",
  } +
  {
    "en": "Tu selección:",
    "es": "Tu selección:",
  } +
  {
    "en": "select_country",
    "es": "Seleccionar país",
  } +
  {
    "en": "search_country",
    "es": "Buscar país...",
  } +
  {
    "en": "clear",
    "es": "Limpiar",
  } +
  {
    "en": "no_results",
    "es": "No se encontraron resultados",
  } +

// ==================== SYSTEM SETTINGS ====================
{
  "en": "System",
  "es": "Sistema",
} +
{
  "en": "System Settings",
  "es": "Ajustes del Sistema",
} +
{
  "en": "OS-level settings and permissions for THISECURE",
  "es": "Configuraciones y permisos a nivel de SO para THISECURE",
} +
{
  "en": "Default Password Manager",
  "es": "Gestor de contraseñas principal",
} +
{
  "en": "Password Manager Status",
  "es": "Estado del gestor de contraseñas",
} +
{
  "en": "Set THISECURE as your system's default password manager to autofill credentials across all apps",
  "es": "Configura THISECURE como gestor de contraseñas principal para autorellenar credenciales en todas las apps",
} +
{
  "en": "THISECURE is your default password manager",
  "es": "THISECURE es tu gestor de contraseñas principal",
} +
{
  "en": "Open system autofill settings",
  "es": "Abrir ajustes de autofill del sistema",
} +
{
  "en": "THISECURE is not the default password manager",
  "es": "THISECURE no es el gestor de contraseñas principal",
} +
{
  "en": "Autofill not supported on this device",
  "es": "Autofill no soportado en este dispositivo",
} +
{
  "en": "App Permissions",
  "es": "Permisos de la app",
} +
{
  "en": "Open App Settings",
  "es": "Abrir Ajustes de la App",
} +
{
  "en": "Manage THISECURE permissions in system settings",
  "es": "Gestionar permisos de THISECURE en ajustes del sistema",
} +
{
  "en": "Notifications",
  "es": "Notificaciones",
} +
{
  "en": "Granted",
  "es": "Concedido",
} +
{
  "en": "Denied",
  "es": "Denegado",
} +
{
  "en": "Unknown",
  "es": "Desconocido",
} +
{
  "en": "Autofill Service",
  "es": "Servicio de Autofill",
} +
{
  "en": "Active",
  "es": "Activo",
} +
{
  "en": "Inactive",
  "es": "Inactivo",
} +
{
  "en": "Biometric Permission",
  "es": "Permiso biométrico",
} +
{
  "en": "Platform",
  "es": "Plataforma",
} +
{
  "en": "Available",
  "es": "Disponible",
} +
{
  "en": "Not available",
  "es": "No disponible",
} +
{
  "en": "Enable THISECURE as your autofill provider in system settings",
  "es": "Activa THISECURE como proveedor de autofill en los ajustes del sistema",
} +
{
  "en": "On Android, go to Settings > Passwords & accounts > Autofill service",
  "es": "En Android, ve a Ajustes > Contraseñas y cuentas > Servicio de autofill",
} +
{
  "en": "On iOS, go to Settings > Passwords > AutoFill Passwords",
  "es": "En iOS, ve a Ajustes > Contraseñas > Autorrellenar contraseñas",
} +
{
  "en": "On macOS, go to System Settings > Passwords",
  "es": "En macOS, ve a Ajustes del Sistema > Contraseñas",
} +
{
  "en": "Open System Settings",
  "es": "Abrir Ajustes del Sistema",
} +
{
  "en": "App Group Sharing",
  "es": "Compartir entre apps",
} +
{
  "en": "Share credentials with iOS/macOS credential provider extension",
  "es": "Compartir credenciales con la extensión de proveedor de iOS/macOS",
} +
{
  "en": "Credential Provider Extension",
  "es": "Extensión de proveedor de credenciales",
} +
{
  "en": "Required for system-wide autofill on iOS and macOS",
  "es": "Necesario para autofill en todo el sistema en iOS y macOS",
} +
{
  "en": "System Permissions",
  "es": "Permisos del Sistema",
} +
{
  "en": "Open system notification settings",
  "es": "Abrir ajustes de notificaciones",
} +
{
  "en": "Notification permission",
  "es": "Permiso de notificaciones",
} +
{
  "en": "Checking system settings...",
  "es": "Verificando configuración del sistema...",
};

String get i18n => localize(this, _t);

  String i18nFor(String locale) => i18n;

  String fill(List<Object> params) => localizeFill(this, params);
}
