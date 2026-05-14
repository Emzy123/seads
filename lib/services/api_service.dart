import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

/// HTTP client for the SEADS backend. Parses JSON defensively so UI layers
/// do not crash on 4xx bodies, HTML error pages, or alternate envelope shapes.
class ApiService {
  ApiService() : dio = _createDio();

  final Dio dio;

  static Dio _createDio() {
    return Dio(BaseOptions(
      baseUrl: AppConfig.backendUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
    ));
  }

  /// Normalizes list-like DB/API fields (JSON array or comma-separated string).
  static List<String> coerceStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final s = value.toString().trim();
    if (s.isEmpty) return [];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static bool _statusOk(int? code) => code != null && code >= 200 && code < 300;

  static String _errorMessage(dynamic data) {
    if (data is Map) {
      final err = data['error'] ?? data['message'] ?? data['detail'];
      if (err != null) return err.toString();
    }
    return 'Request failed';
  }

  /// Extracts a list from `{ "key": [ ... ] }`, a bare array, or `{ "data": ... }`.
  static List<dynamic> _decodeList(dynamic data, String key) {
    if (data == null) return [];
    if (data is List) return List<dynamic>.from(data);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data as Map);
      final direct = map[key];
      if (direct is List) return List<dynamic>.from(direct);
      final inner = map['data'];
      if (inner is List) return List<dynamic>.from(inner);
      if (inner is Map) {
        final nested = Map<String, dynamic>.from(inner);
        final v = nested[key];
        if (v is List) return List<dynamic>.from(v);
      }
    }
    return [];
  }

  static Map<String, dynamic> _decodeMapEnvelope(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      final map = Map<String, dynamic>.from(data as Map);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      if (map['profile'] is Map) {
        return Map<String, dynamic>.from(map['profile'] as Map);
      }
      return map;
    }
    return {};
  }

  static Map<String, dynamic> _normalizeMedicalProfile(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    for (final key in ['allergies', 'conditions', 'medications']) {
      out[key] = coerceStringList(out[key]);
    }
    return out;
  }

  /// Returns current Firebase ID token or null if not signed in.
  Future<String?> _getToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<Map<String, dynamic>> dispatchAmbulance({
    required double lat,
    required double lng,
    required String patientId,
    required String emergencyType,
    String? description,
  }) async {
    final token = await _getToken();
    final response = await dio.post(
      '/api/dispatch',
      data: {
        'lat': lat,
        'lng': lng,
        'patient_id': patientId,
        'emergency_type': emergencyType,
        'description': description,
      },
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    if (!_statusOk(response.statusCode)) {
      throw Exception(_errorMessage(response.data));
    }
    final data = response.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data as Map);
    }
    return {'message': 'Ambulance request submitted.'};
  }

  Future<void> updateLocation({required double lat, required double lng}) async {
    final token = await _getToken();
    if (token == null) return;

    await dio.put(
      '/api/ambulances/location',
      data: {'lat': lat, 'lng': lng},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    // Background GPS: failures are ignored so the stream keeps running.
  }

  Future<void> updateIncidentStatus({required String incidentId, required String status}) async {
    final token = await _getToken();
    if (token == null) return;

    final response = await dio.put(
      '/api/incidents/$incidentId/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) {
      throw Exception(_errorMessage(response.data));
    }
  }

  Future<List<dynamic>> getAssignments() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/incidents',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'incidents');
  }

  Future<List<dynamic>> getAllAmbulances() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/ambulances',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'ambulances');
  }

  Future<void> saveFcmToken(String fcmToken) async {
    final token = await _getToken();
    if (token == null) return;

    await dio.post(
      '/api/users/fcm-token',
      data: {'fcm_token': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    // Non-fatal if token save fails (e.g. offline).
  }

  Future<List<dynamic>> getEmergencyHistory() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/patients/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'history');
  }

  Future<List<dynamic>> getEmergencyContacts() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/patients/contacts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'contacts');
  }

  Future<Map<String, dynamic>> getMedicalProfile() async {
    final token = await _getToken();
    if (token == null) return {};

    final response = await dio.get(
      '/api/patients/medical-profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return {};
    final decoded = _decodeMapEnvelope(response.data);
    if (decoded.isEmpty) return {};
    return _normalizeMedicalProfile(decoded);
  }

  Future<void> updateMedicalProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) return;

    final response = await dio.put(
      '/api/patients/medical-profile',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) {
      throw Exception(_errorMessage(response.data));
    }
  }

  Future<List<dynamic>> getAssignmentHistory() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/paramedics/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'assignments');
  }

  Future<Map<String, dynamic>> getPerformanceStats({String period = 'week'}) async {
    final token = await _getToken();
    if (token == null) return {};

    final response = await dio.get(
      '/api/paramedics/stats',
      queryParameters: {'period': period},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return {};
    return _decodeMapEnvelope(response.data);
  }

  Future<List<dynamic>> getFleet() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/dispatchers/fleet',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'fleet');
  }

  Future<List<dynamic>> getStaff() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/dispatchers/staff',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'staff');
  }

  Future<List<dynamic>> getIncidentLog({Map<String, dynamic>? filters}) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await dio.get(
      '/api/dispatchers/incidents',
      queryParameters: _stringifyQuery(filters),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return [];
    return _decodeList(response.data, 'incidents');
  }

  /// Dio query parameters must be `String` | `num` for reliable encoding.
  static Map<String, dynamic>? _stringifyQuery(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return null;
    return filters.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  Future<Map<String, dynamic>> getAnalytics({String period = 'week'}) async {
    final token = await _getToken();
    if (token == null) return {};

    final response = await dio.get(
      '/api/dispatchers/analytics',
      queryParameters: {'period': period},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (!_statusOk(response.statusCode)) return {};
    return _decodeMapEnvelope(response.data);
  }
}
