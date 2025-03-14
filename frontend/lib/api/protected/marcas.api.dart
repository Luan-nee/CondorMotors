import '../main.api.dart';
import 'package:flutter/foundation.dart';

/// Modelo para las marcas
class Marca {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? logo;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Marca({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.logo,
    this.activo = true,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      logo: json['logo'],
      activo: json['activo'] ?? true,
      fechaCreacion: json['fechaCreacion'] != null 
          ? DateTime.parse(json['fechaCreacion']) 
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null 
          ? DateTime.parse(json['fechaActualizacion']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'logo': logo,
      'activo': activo,
    };
  }
  
  @override
  String toString() {
    return 'Marca{id: $id, nombre: $nombre, activo: $activo}';
  }
}

class MarcasApi {
  final ApiClient _api;
  
  MarcasApi(this._api);
  
  /// Obtiene todas las marcas
  Future<List<dynamic>> getMarcas() async {
    try {
      debugPrint('MarcasApi: Obteniendo lista de marcas');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'GET',
      );
      
      debugPrint('MarcasApi: Respuesta de getMarcas recibida');
      debugPrint('MarcasApi: Estructura de respuesta: ${response.keys.toList()}');
      
      // Manejar estructura anidada: response.data.data
      if (response['data'] is Map && response['data'].containsKey('data')) {
        debugPrint('MarcasApi: Encontrada estructura anidada en la respuesta');
        final items = response['data']['data'] ?? [];
        debugPrint('MarcasApi: Total de marcas encontradas: ${items.length}');
        return items;
      }
      
      // Si la estructura cambia en el futuro y ya no está anidada
      debugPrint('MarcasApi: Usando estructura directa de respuesta');
      final items = response['data'] ?? [];
      debugPrint('MarcasApi: Total de marcas encontradas: ${items.length}');
      return items;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marcas: $e');
      rethrow;
    }
  }
  
  /// Obtiene una marca por su ID
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> getMarca(String marcaId) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      if (marcaId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      debugPrint('MarcasApi: Obteniendo marca con ID: $marcaId');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$marcaId',
        method: 'GET',
      );
      
      debugPrint('MarcasApi: Respuesta de getMarca recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 404,
          message: 'Marca no encontrada',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marca #$marcaId: $e');
      rethrow;
    }
  }
  
  /// Crea una nueva marca
  Future<Map<String, dynamic>> createMarca(Map<String, dynamic> marcaData) async {
    try {
      // Validar datos mínimos requeridos
      if (!marcaData.containsKey('nombre')) {
        throw ApiException(
          statusCode: 400,
          message: 'Nombre de marca es requerido',
        );
      }
      
      debugPrint('MarcasApi: Creando nueva marca: ${marcaData['nombre']}');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas',
        method: 'POST',
        body: marcaData,
      );
      
      debugPrint('MarcasApi: Respuesta de createMarca recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al crear marca',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al crear marca: $e');
      rethrow;
    }
  }
  
  /// Actualiza una marca existente
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<Map<String, dynamic>> updateMarca(String marcaId, Map<String, dynamic> marcaData) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      if (marcaId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      debugPrint('MarcasApi: Actualizando marca con ID: $marcaId');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/$marcaId',
        method: 'PUT',
        body: marcaData,
      );
      
      debugPrint('MarcasApi: Respuesta de updateMarca recibida');
      
      // Manejar estructura anidada
      Map<String, dynamic>? data;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        data = response['data']['data'];
      } else {
        data = response['data'];
      }
      
      if (data == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Error al actualizar marca',
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('MarcasApi: ERROR al actualizar marca #$marcaId: $e');
      rethrow;
    }
  }
  
  /// Elimina una marca
  /// 
  /// El ID debe ser un string, aunque represente un número
  Future<void> deleteMarca(String marcaId) async {
    try {
      // Validar que marcaId no sea nulo o vacío
      if (marcaId.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de marca no puede estar vacío',
        );
      }
      
      debugPrint('MarcasApi: Eliminando marca con ID: $marcaId');
      await _api.authenticatedRequest(
        endpoint: '/marcas/$marcaId',
        method: 'DELETE',
      );
      
      debugPrint('MarcasApi: Marca eliminada correctamente');
    } catch (e) {
      debugPrint('MarcasApi: ERROR al eliminar marca #$marcaId: $e');
      rethrow;
    }
  }
  
  /// Obtiene solo las marcas activas
  Future<List<dynamic>> getMarcasActivas() async {
    try {
      debugPrint('MarcasApi: Obteniendo marcas activas');
      final response = await _api.authenticatedRequest(
        endpoint: '/marcas/activas',
        method: 'GET',
      );
      
      debugPrint('MarcasApi: Respuesta de getMarcasActivas recibida');
      
      // Manejar estructura anidada
      if (response['data'] is Map && response['data'].containsKey('data')) {
        return response['data']['data'] ?? [];
      }
      
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('MarcasApi: ERROR al obtener marcas activas: $e');
      rethrow;
    }
  }
}
