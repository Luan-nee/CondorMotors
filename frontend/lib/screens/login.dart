import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Importar para KeyboardListener
import '../routes/routes.dart';
import '../widgets/background.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/main.api.dart';
import '../main.dart' show api;
import '../api/index.dart' show CondorMotorsApi;
import 'dart:async';

// Clase para manejar el ciclo de vida de la aplicación
class LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback resumeCallBack;
  final VoidCallback pauseCallBack;

  LifecycleObserver({
    required this.resumeCallBack,
    required this.pauseCallBack,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resumeCallBack();
    } else if (state == AppLifecycleState.paused) {
      pauseCallBack();
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _capsLockOn = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late final AnimationController _animationController;
  String _errorMessage = '';
  String _serverIp = 'localhost'; // IP local para el servidor
  late final LifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _loadServerIp();
    _loadSavedCredentials();
    
    // Reducir la velocidad de la animación cuando la app está en segundo plano
    _lifecycleObserver = LifecycleObserver(
      resumeCallBack: () {
        if (!_animationController.isAnimating) {
          _animationController.repeat();
        }
      },
      pauseCallBack: () {
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  Future<void> _loadServerIp() async {
    try {
      final ip = await _storage.read(key: 'server_ip');
      if (ip != null && ip.isNotEmpty) {
        setState(() {
          _serverIp = ip;
        });
        // Actualizar la URL base de la API global
        await _updateApiBaseUrl(_serverIp);
      } else {
        // Si no hay IP guardada, usar localhost
        setState(() {
          _serverIp = 'localhost';
        });
        // Actualizar la URL base de la API global
        await _updateApiBaseUrl('localhost');
      }
    } catch (e) {
      debugPrint('Error al cargar la IP del servidor: $e');
      // En caso de error, asegurar que se use localhost
      setState(() {
        _serverIp = 'localhost';
      });
      // Actualizar la URL base de la API global
      await _updateApiBaseUrl('localhost');
    }
  }

  // Método para actualizar la URL base de la API global
  Future<void> _updateApiBaseUrl(String serverIp) async {
    debugPrint('Actualizando URL base de la API a: http://$serverIp:3000/api');
    try {
      // Reinicializar la API global con la nueva URL base
      api = CondorMotorsApi(baseUrl: 'http://$serverIp:3000/api');
      // Inicializar el servicio de autenticación
      await api.initAuthService();
      debugPrint('API inicializada correctamente con nueva URL base');
    } catch (e) {
      debugPrint('Error al inicializar API con nueva URL base: $e');
    }
  }

  Future<void> _saveServerIp(String ip) async {
    try {
      // Guardar la IP proporcionada
      await _storage.write(key: 'server_ip', value: ip);
      setState(() {
        _serverIp = ip;
      });
      // Actualizar la URL base de la API global
      await _updateApiBaseUrl(ip);
    } catch (e) {
      debugPrint('Error al guardar la IP del servidor: $e');
    }
  }

  void _showServerConfigDialog() {
    final TextEditingController ipController = TextEditingController(text: _serverIp);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración del Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingrese la dirección IP del servidor:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: 'Dirección IP',
                hintText: 'Ej: localhost o 192.168.1.100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            Text(
              '• Para desarrollo local: localhost\n• Para emuladores Android: 10.0.2.2\n• Para dispositivos físicos: IP de tu PC',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIp = ipController.text.trim();
              if (newIp.isNotEmpty) {
                Navigator.pop(context);
                // Mostrar indicador de carga mientras se actualiza la URL
                setState(() {
                  _isLoading = true;
                });
                await _saveServerIp(newIp);
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  // Mostrar mensaje de confirmación
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Servidor actualizado a: $newIp'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.capsLock) {
      setState(() {
        _capsLockOn = HardwareKeyboard.instance.lockModesEnabled
            .contains(KeyboardLockMode.capsLock);
      });
    }
    return false;
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final username = await _storage.read(key: 'username');
      final password = await _storage.read(key: 'password');
      final shouldRemember = await _storage.read(key: 'remember_me');

      if (username != null && password != null && shouldRemember == 'true') {
        setState(() {
          _usernameController.text = username;
          _passwordController.text = password;
          _rememberMe = true;
        });
      }
    } catch (e) {
      // Ignorar errores al cargar credenciales
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _storage.write(key: 'username', value: _usernameController.text);
      await _storage.write(key: 'password', value: _passwordController.text);
      await _storage.write(key: 'remember_me', value: 'true');
    } else {
      await _storage.deleteAll();
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Iniciando proceso de login con usuario: ${_usernameController.text}');
      
      // Usar la API global en lugar de la local
      final usuarioAutenticado = await api.auth.login(
        _usernameController.text,
        _passwordController.text,
      );

      debugPrint('Login exitoso, usuario autenticado: $usuarioAutenticado');
      
      // Guardar los datos del usuario en el servicio global de autenticación
      try {
        await api.authService.saveUserData(usuarioAutenticado);
        debugPrint('Datos de usuario guardados correctamente en el servicio global');
      } catch (e) {
        debugPrint('Error al guardar datos en el servicio global: $e');
        // Continuamos aunque haya error, ya que el token ya está configurado en el cliente API
      }
      
      if (_rememberMe) {
        await _saveCredentials();
      }

      if (!mounted) return;

      // Navegar a la ruta correspondiente según el rol del usuario
      final userData = usuarioAutenticado.toMap();
      final rolCodigo = usuarioAutenticado.rolCuentaEmpleadoCodigo;
      
      debugPrint('Rol del usuario (código original): $rolCodigo');
      
      // Convertir el código de rol a un rol válido
      final rol = _getRoleFromCodigo(rolCodigo);
      debugPrint('Rol convertido para la aplicación: $rol');
      
      // Verificar que el rol sea válido
      if (!Routes.roles.containsKey(rol)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Rol no válido: $rol. Contacte al administrador.';
        });
        return;
      }
      
      final initialRoute = Routes.getInitialRoute(rol);
      debugPrint('Ruta inicial determinada: $initialRoute');
      
      // Actualizar el rol en userData para que coincida con los roles de la aplicación
      userData['rol'] = rol;
      
      Navigator.pushReplacementNamed(
        context,
        initialRoute,
        arguments: userData,
      );
    } catch (e) {
      debugPrint('Error durante el login: $e');
      if (!mounted) return;
      
      String errorMsg = 'Error de autenticación';
      
      if (e is ApiException) {
        switch (e.errorCode) {
          case ApiException.errorUnauthorized:
            errorMsg = 'Usuario o contraseña incorrectos';
            break;
          case ApiException.errorNetwork:
            errorMsg = 'Error de conexión. Verifique su conexión a internet o la configuración del servidor.';
            break;
          case ApiException.errorServer:
            errorMsg = 'Error en el servidor. Intente más tarde.';
            break;
          default:
            errorMsg = 'Error: ${e.message}';
        }
      } else {
        errorMsg = 'Error inesperado: ${e.toString()}';
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }
  
  // Método para convertir código de rol a un rol válido
  String _getRoleFromCodigo(String codigo) {
    // Normalizar el código a mayúsculas para comparación
    final codigoUpper = codigo.toUpperCase();
    
    switch (codigoUpper) {
      case 'ADM':
      case 'ADMIN':
      case 'ADMINISTRADOR':
      case 'ADMINSTRADOR': // Corregir error tipográfico del servidor
        return 'ADMINISTRADOR';
      case 'VEN':
      case 'VENDEDOR':
        return 'VENDEDOR';
      case 'COMP':
      case 'COMPUTER':
      case 'COMPUTADORA':
        return 'COMPUTADORA';
      case 'GER':
      case 'GERENTE':
        return 'ADMINISTRADOR'; // Los gerentes tienen acceso de administrador
      case 'SUP':
      case 'SUPERVISOR':
        return 'ADMINISTRADOR'; // Los supervisores tienen acceso de administrador
      default:
        debugPrint('Rol desconocido: $codigo, intentando usar como está');
        // Si no coincide con ninguno conocido, devolver el código en mayúsculas
        // para intentar que coincida con alguno de los roles definidos
        return codigoUpper;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _animationController,
                  ),
                );
              },
            ),
          ),
          // Botón de configuración del servidor
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: _showServerConfigDialog,
              tooltip: 'Configurar servidor',
            ),
          ),
          // Contenido del login
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Image.asset(
                              'assets/images/condor-motors-logo.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Iniciar Sesión',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Usuario',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.person, color: Color(0xFFE31E24)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su usuario';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            _passwordFocusNode.requestFocus();
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Clave',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFFE31E24)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: const Color(0xFFE31E24),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su clave';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),

                        // Caps Lock warning
                        if (_capsLockOn)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bloq Mayús está activado',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              fillColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFFE31E24);
                                  }
                                  return Colors.white54;
                                },
                              ),
                            ),
                            const Text(
                              'Recordar credenciales',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        // Error message
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Login button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _handleLogin(),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
