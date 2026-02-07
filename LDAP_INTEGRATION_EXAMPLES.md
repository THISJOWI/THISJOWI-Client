// Ejemplo de integración en main.dart

// Añadir esta importación
import 'screens/auth/authSelection.dart';
import 'screens/auth/ldapLogin.dart';

// En MaterialApp, añadir estas rutas:
MaterialApp(
  // ... otras propiedades ...
  routes: {
    // Rutas de autenticación
    '/authSelection': (context) => const AuthSelectionScreen(),
    '/ldapLogin': (context) => const LdapLoginScreen(),
    '/login': (context) => const LoginScreen(),
    
    // Rutas principales
    '/home': (context) => const MyBottomNavigation(),
    '/splash': (context) => const SplashScreen(),
    
    // Otras rutas...
  },
  
  // Si estás usando navegación por nombre, establece la ruta inicial:
  initialRoute: '/splash', // o '/authSelection' si ya autenticaste
)

// Ejemplo en SplashScreen para redirigir a authSelection:
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    final token = await authService.getToken();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (token != null && token.isNotEmpty) {
          // Usuario ya autenticado, ir a home
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Usuario no autenticado, mostrar opciones de login
          Navigator.of(context).pushReplacementNamed('/authSelection');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 24),
            const Text(
              'ThisJowi',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Ejemplo en Settings para mostrar información de usuario LDAP:
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LdapAuthService _ldapAuthService = LdapAuthService();

  Future<void> _handleLogout() async {
    await _ldapAuthService.clearLdapSession();
    
    final authService = AuthService();
    await authService.logout();
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/authSelection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: FutureBuilder<User?>(
        future: _ldapAuthService.getLdapUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LdapUserCard(
                    user: user,
                    onLogout: _handleLogout,
                  ),
                  const SizedBox(height: 24),
                  // Otros settings...
                ],
              ),
            );
          }
          
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

// Ejemplo de uso en un botón de login:
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushNamed('/authSelection');
  },
  child: const Text('Autenticarse'),
)

// Ejemplo de verificar sesión LDAP:
FutureBuilder<User?>(
  future: LdapAuthService().getLdapUserInfo(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data?.isLdapUser == true) {
      return Text('Usuario LDAP: ${snapshot.data?.ldapUsername}');
    }
    return const Text('No autenticado vía LDAP');
  },
)
