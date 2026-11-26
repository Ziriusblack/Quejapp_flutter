import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pqr_model.dart';
import '../local/db_helper.dart';

class ApiService {
  static const String baseUrl = 'https://quejapi-back.onrender.com/api';
  static const String iaBaseUrl = 'https://quejapp-nn.onrender.com';
  static const _storage = FlutterSecureStorage();

  // 1. OBTENER ESTADÍSTICAS REALES PARA EL HOME (GET /api/stats/overview)
  static Future<dynamic> obtenerEstadisticasHome() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/stats/overview'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. MÉTODO DE LOGIN CON DETECCIÓN DE ROL
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String? token = data['authenticationToken'];
        if (token == null) return null;
        await _storage.write(key: 'jwt_token', value: token);

        if (data['refreshToken'] != null) {
          await _storage.write(key: 'refresh_token', value: data['refreshToken'].toString());
        }

        final userData = data['userData'];
        if (userData != null && userData['name'] != null) {
          await _storage.write(key: 'user_name', value: userData['name'].toString());
        }

        final List<dynamic> rolesList = (userData != null && userData['roles'] != null)
            ? List<dynamic>.from(userData['roles'])
            : [];

        final String rolesStr = rolesList.join(',').toUpperCase();
        final String rolNormalizado = rolesStr.contains('ADMIN') ? 'ADMIN' : 'USER';

        await _storage.write(key: 'user_role', value: rolNormalizado);
        return rolNormalizado;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. OBTENER ESTADO DE SESIÓN ACTUAL
  static Future<String> getRolActual() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) return 'INVITADO';
    final rol = await _storage.read(key: 'user_role');
    return rol ?? 'USER';
  }

  // 4. CERRAR SESIÓN
  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
  }

  // 5. MÉTODO DE REGISTRO
  static Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required String birthdateIso,
    required int gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'password': password,
          'birthdate': birthdateIso,
          'gender': gender,
          'role': 0,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['authenticationToken'] != null) {
          await _storage.write(key: 'jwt_token', value: data['authenticationToken']);
          await _storage.write(key: 'user_role', value: 'USER');
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

// 6. REGISTRAR PQR (CON RESPALDO OFFLINE EN SQLITE -> POST /api/user/complaint)
  static Future<String> registrarNuevaSolicitud({
    required int type,
    required int category,
    required String subject,
    required String description,
  }) async {
    final result = await Connectivity().checkConnectivity();

    final bool isOffline = result is List
        ? (result as List).contains(ConnectivityResult.none)
        : result == ConnectivityResult.none;

    final pqrLocal = PqrModel(
      tipo: '$type|$category|$subject',
      descripcion: description,
      latitud: 0.0,
      longitud: 0.0,
      sincronizado: false,
    );

    if (isOffline) {
      await DbHelper.instance.insertPqr(pqrLocal);
      return 'Sin conexión. La solicitud se guardó localmente y se enviará luego.';
    }

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/user/complaint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          'category': category,
          'subject': subject,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 'OK';
      } else {
        await DbHelper.instance.insertPqr(pqrLocal);
        return 'Error del servidor (${response.statusCode}). Guardado localmente por seguridad.';
      }
    } catch (e) {
      await DbHelper.instance.insertPqr(pqrLocal);
      return 'Fallo de red. La solicitud se guardó localmente.';
    }
  }

  // 7. SINCRONIZAR PENDIENTES AL RECUPERAR CONEXIÓN
  static Future<void> sincronizarPendientes() async {
    final result = await Connectivity().checkConnectivity();
    final bool isOffline = result is List
        ? (result as List).contains(ConnectivityResult.none)
        : result == ConnectivityResult.none;

    if (!isOffline) {
      final pendientes = await DbHelper.instance.getPqrsNoSincronizadas();
      final token = await _storage.read(key: 'jwt_token');

      for (var pqr in pendientes) {
        try {
          final pqrParaEnviar = PqrModel(
            tipo: pqr.tipo,
            descripcion: pqr.descripcion,
            latitud: pqr.latitud,
            longitud: pqr.longitud,
            sincronizado: true,
          );

          final response = await http.post(
            Uri.parse('$baseUrl/user/complaint'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(pqrParaEnviar.toMap()),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            await DbHelper.instance.deletePqr(pqr.idLocal!);
          }
        } catch (e) {
          print('Fallo al sincronizar PQR ID: ${pqr.idLocal}');
        }
      }
    }
  }

  // 8. OBTENER LAS PQRS DEL USUARIO (POST /api/user/complaints con ComplaintSearch)
  static Future<dynamic> obtenerMisPqrs({
    String searchTerm = '',
    int? status,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('$baseUrl/user/complaints'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'searchTerm': searchTerm.isEmpty ? null : searchTerm,
          'status': status,
          'page': page,
          'size': size,
          'sortBy': 'recievedDate',
          'sortDirection': 'desc',
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['content'] != null) {
          return {
            'items': List<dynamic>.from(decoded['content']),
            'total': decoded['totalElements'] ?? (decoded['content'] as List).length,
          };
        } else if (decoded is List) {
          return {
            'items': decoded,
            'total': decoded.length,
          };
        }
      }
      return {'items': [], 'total': 0};
    } catch (e) {
      return {'items': [], 'total': 0};
    }
  }

  // 9. OBTENER DETALLE COMPLETO DE UNA PQR POR ID (GET /api/user/complaints/{id})
  static Future<dynamic> obtenerDetallePqr(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/user/complaints/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
// Pega estos 4 métodos DENTRO de la clase ApiService (lib/data/network/api_service.dart),
// antes de la última llave }. Si ya tienes alguno, no lo dupliques.

  // 10. OBTENER ESTADÍSTICAS DEL DASHBOARD ADMIN (GET /api/stats/overview)
  static Future obtenerEstadisticasAdmin({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final Map<String, String> queryParams = {};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final uri = Uri.parse('$baseUrl/stats/overview').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          return decoded;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

// 11. OBTENER PQRS PRIORIZADAS POR IA (GET /api/stats/priorities)
  static Future<List> obtenerPqrsPriorizadas({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final Map<String, String> queryParams = {};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final uri = Uri.parse('$baseUrl/stats/priorities').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Detalle de una PQR para el admin (GET /api/admin/complaints/{id})
  static Future<Map<String, dynamic>?> obtenerDetalleAdmin(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final r = await http.get(
        Uri.parse('$baseUrl/admin/complaints/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 70));
      if (r.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Responder / cambiar estado (PUT /api/admin/complaints/{id})
  // status: 0 Nuevo, 1 En Proceso, 2 Resuelto, 3 Cerrado
  static Future<String?> actualizarPqrAdmin({
    required String id,
    required int status,
    required String response,
    required String department,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final r = await http.put(
        Uri.parse('$baseUrl/admin/complaints/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status, 'response': response, 'department': department}),
      ).timeout(const Duration(seconds: 70));
      return (r.statusCode == 200 || r.statusCode == 201) ? null : 'Error ${r.statusCode}: ${r.body}';
    } catch (e) {
      return 'Sin conexión: $e';
    }
  }

  // Lista paginada de radicados para el admin (POST /api/admin/complaints)
  // Devuelve null si hubo error de red/servidor.
  static Future<Map<String, dynamic>?> obtenerRadicadosAdmin({
    String searchTerm = '',
    int? status,
    int page = 0,
    int size = 5,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final r = await http.post(
        Uri.parse('$baseUrl/admin/complaints'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'searchTerm': searchTerm.isEmpty ? null : searchTerm,
          'status': status,
          'page': page,
          'size': size,
          'sortBy': 'recievedDate',
          'sortDirection': 'desc',
        }),
      ).timeout(const Duration(seconds: 70));

      if (r.statusCode == 200) {
        final d = jsonDecode(utf8.decode(r.bodyBytes));
        if (d is Map && d['content'] is List) {
          final items = List<dynamic>.from(d['content']);
          return {
            'items': items,
            'total': (d['totalElements'] as num?)?.toInt() ?? items.length,
            'totalPages': (d['totalPages'] as num?)?.toInt() ?? 1,
          };
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

   static Future<String?> solicitarCodigoRecuperacion(String email) async {
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 70));
      return r.statusCode == 200 ? null : 'No se pudo enviar el código (error ${r.statusCode}).';
    } catch (_) {
      return 'Sin conexión con el servidor. Intenta de nuevo.';
    }
  }

  // Cambia la contraseña con el código (POST /api/auth/reset-password)
  static Future<String?> restablecerContrasena({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 70));
      if (r.statusCode == 200) return null;
      try {
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        if (j is Map && j['message'] != null) return j['message'].toString();
      } catch (_) {}
      return 'No se pudo cambiar la contraseña (error ${r.statusCode}).';
    } catch (_) {
      return 'Sin conexión con el servidor. Intenta de nuevo.';
    }
  }

// 12. CONSULTAR PREDICCIÓN DE TIEMPO A LA RED NEURONAL EN RENDER (POST /predecir)
  static Future<dynamic> predecirTiempoPqr({
    required int type,
    required int category,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$iaBaseUrl/predecir'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'category': category,
          'subject': subject,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _respaldoOffline(PqrModel pqr) async {
    final pqrOffline = PqrModel(
      tipo: pqr.tipo,
      descripcion: pqr.descripcion,
      latitud: pqr.latitud,
      longitud: pqr.longitud,
      sincronizado: false,
    );
    await DbHelper.instance.insertPqr(pqrOffline);
  }
}