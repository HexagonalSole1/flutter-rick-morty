import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/NativeSecurityService.dart';
import 'characters/screens/CharacterListScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación de pantalla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar seguridad nativa
  await NativeSecurityService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick and Morty App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SecureHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SecureHomePage extends StatefulWidget {
  const SecureHomePage({super.key});

  @override
  State<SecureHomePage> createState() => _SecureHomePageState();
}

class _SecureHomePageState extends State<SecureHomePage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // App vuelve al primer plano - reforzar seguridad
        NativeSecurityService.enableScreenSecurity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      // Mantener seguridad incluso cuando la app no está activa
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rick and Morty'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              NativeSecurityService.isSecured
                  ? Icons.security
                  : Icons.security_outlined,
              color: NativeSecurityService.isSecured
                  ? Colors.green
                  : Colors.grey,
            ),
            onPressed: () => _showSecurityInfo(context),
          ),
        ],
      ),
      body: const CharacterListScreen(),
      floatingActionButton: NativeSecurityService.isSupported
          ? FloatingActionButton(
        onPressed: () => _toggleSecurity(),
        tooltip: NativeSecurityService.isSecured
            ? 'Deshabilitar seguridad'
            : 'Habilitar seguridad',
        child: Icon(
            NativeSecurityService.isSecured
                ? Icons.lock
                : Icons.lock_open
        ),
      )
          : null,
    );
  }

  void _toggleSecurity() async {
    bool success = false;
    String message = '';

    if (NativeSecurityService.isSecured) {
      success = await NativeSecurityService.disableScreenSecurity();
      message = success
          ? '🔓 Capturas de pantalla permitidas'
          : '❌ Error al deshabilitar seguridad';
    } else {
      success = await NativeSecurityService.enableScreenSecurity();
      message = success
          ? '🔒 Capturas de pantalla bloqueadas'
          : '❌ Error al habilitar seguridad';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? (NativeSecurityService.isSecured ? Colors.green : Colors.orange)
              : Colors.red,
        ),
      );
    }
    setState(() {});
  }

  void _showSecurityInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estado de Seguridad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  NativeSecurityService.isSecured ? Icons.check_circle : Icons.cancel,
                  color: NativeSecurityService.isSecured ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      NativeSecurityService.isSecured
                          ? 'Capturas de pantalla bloqueadas'
                          : 'Capturas de pantalla permitidas'
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              NativeSecurityService.isSupported
                  ? 'Plataforma: Android ✅'
                  : 'Plataforma: No soportada ❌',
              style: TextStyle(
                color: NativeSecurityService.isSupported
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Funciones protegidas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Capturas de pantalla'),
            const Text('• Grabación de pantalla'),
            const Text('• Vista previa en apps recientes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}