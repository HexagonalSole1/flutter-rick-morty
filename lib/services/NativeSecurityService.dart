import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeSecurityService {
  static const MethodChannel _channel = MethodChannel('security_channel');
  static bool _isSecured = false;

  /// Habilita la prevención de capturas de pantalla
  static Future<bool> enableScreenSecurity() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('⚠️ Prevención de capturas solo disponible en Android');
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('enableScreenSecurity');
      _isSecured = result;
      if (result) {
        debugPrint('✅ Capturas de pantalla bloqueadas');
      } else {
        debugPrint('❌ No se pudo bloquear capturas');
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Error al habilitar seguridad: ${e.message}');
      return false;
    }
  }

  /// Deshabilita la prevención de capturas de pantalla
  static Future<bool> disableScreenSecurity() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('disableScreenSecurity');
      _isSecured = !result;
      if (result) {
        debugPrint('✅ Capturas de pantalla permitidas');
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Error al deshabilitar seguridad: ${e.message}');
      return false;
    }
  }

  /// Verifica si la seguridad está habilitada
  static bool get isSecured => _isSecured;

  /// Verifica si la plataforma soporta estas características
  static bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Inicializa la seguridad al abrir la app
  static Future<void> initialize() async {
    if (isSupported) {
      await enableScreenSecurity();
    }
  }
}