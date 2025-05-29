import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeSecurityService {
  static const MethodChannel _channel = MethodChannel('security_channel');
  static bool _isSecured = false;

  /// Habilita la prevención de capturas de pantalla
  static Future<bool> enableScreenSecurity() async {
    if (!isSupported) {
      debugPrint('⚠️ Prevención de capturas no disponible en esta plataforma');
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('enableScreenSecurity');
      _isSecured = result;
      if (result) {
        debugPrint('✅ ${platformName}: Capturas de pantalla bloqueadas');
      } else {
        debugPrint('❌ ${platformName}: No se pudo bloquear capturas');
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Error al habilitar seguridad: ${e.message}');
      return false;
    }
  }

  /// Deshabilita la prevención de capturas de pantalla
  static Future<bool> disableScreenSecurity() async {
    if (!isSupported) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('disableScreenSecurity');
      _isSecured = !result;
      if (result) {
        debugPrint('✅ ${platformName}: Capturas de pantalla permitidas');
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Error al deshabilitar seguridad: ${e.message}');
      return false;
    }
  }

  /// Detecta si se está grabando la pantalla (iOS 11+)
  static Future<bool> checkScreenRecording() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    try {
      final bool isRecording = await _channel.invokeMethod('checkScreenRecording');
      return isRecording;
    } on PlatformException catch (e) {
      debugPrint('❌ Error al verificar grabación: ${e.message}');
      return false;
    }
  }

  /// Verifica si la seguridad está habilitada
  static bool get isSecured => _isSecured;

  /// Verifica si la plataforma soporta estas características
  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

  /// Obtiene el nombre de la plataforma
  static String get platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      default:
        return 'No soportada';
    }
  }

  /// Inicializa la seguridad al abrir la app
  static Future<void> initialize() async {
    if (isSupported) {
      await enableScreenSecurity();

      // Solo para iOS, inicializar monitoreo de grabación
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          await _channel.invokeMethod('startScreenRecordingMonitoring');
          await _channel.invokeMethod('preventAppSwitcherSnapshot');
        } catch (e) {
          debugPrint('⚠️ Error al inicializar funciones adicionales de iOS: $e');
        }
      }
    }
  }

  /// Cleanup cuando se cierra la app
  static Future<void> dispose() async {
    if (isSupported) {
      try {
        await disableScreenSecurity();
      } catch (e) {
        debugPrint('⚠️ Error durante cleanup: $e');
      }
    }
  }
}