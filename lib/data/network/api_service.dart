import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/pqr_model.dart';
import '../local/db_helper.dart';

class ApiService {
  static const String baseUrl = 'https://quejapi-back.onrender.com/api';
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