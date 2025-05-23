import 'package:dio/dio.dart';
import 'package:';

// Servicio para manejar las peticiones HTTP con Dio
class RickAndMortyService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://rickandmortyapi.com/api/',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static Future<Map<String, dynamic>> getCharacters({int page = 1}) async {
    try {
      final response = await _dio.get('character', queryParameters: {'page': page});
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Character> getCharacterById(int id) async {
    try {
      final response = await _dio.get('character/$id');
      return Character.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado';
      case DioExceptionType.badResponse:
        return 'Error del servidor: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'Error de conexión a internet';
      default:
        return 'Error desconocido: ${e.message}';
    }
  }
}
