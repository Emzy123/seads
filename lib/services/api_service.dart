import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';
import '../core/api_exception.dart';
import '../core/auth_token_cache.dart';

/// HTTP client for the SEADS backend. Parses JSON defensively; surfaces
/// [ApiException] for screen-level error handling.
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


  static List<dynamic> _decodeList(dynamic data, String key) {
    if (data == null) return [];
    if (data is List) return List<dynamic>.from(data);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
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
      final map = Map<String, dynamic>.from(data);
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

  static Map<String, dynamic>? _stringifyQuery(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return null;
    return filters.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  Future<String> _requireToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken() ?? AuthTokenCache.token;
    if (token == null) throw ApiException.notSignedIn();
    AuthTokenCache.save(token);
    return token;
  }

  Options _authOptions(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  void _ensureOk(Response<dynamic> response) {
    if (!_statusOk(response.statusCode)) {
      throw ApiException.fromResponse(response);
    }
  }

  Future<List<dynamic>> _getList(String path, String listKey, {Map<String, dynamic>? query}) async {
    final token = await _requireToken();
    final response = await dio.get(
      path,
      queryParameters: query,
      options: _authOptions(token),
    );
    _ensureOk(response);
    return _decodeList(response.data, listKey);
  }

  Future<Map<String, dynamic>> _getMap(String path, {Map<String, dynamic>? query}) async {
    final token = await _requireToken();
    final response = await dio.get(
      path,
      queryParameters: query,
      options: _authOptions(token),
    );
    _ensureOk(response);
    return _decodeMapEnvelope(response.data);
  }

  Future<Map<String, dynamic>> dispatchAmbulance({
    required double lat,
    required double lng,
    required String patientId,
    required String emergencyType,
    String? description,
  }) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/dispatch',
      data: {
        'lat': lat,
        'lng': lng,
        'patient_id': patientId,
        'emergency_type': emergencyType,
        'description': description,
      },
      options: _authOptions(token),
    );
    _ensureOk(response);
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'message': 'Ambulance request submitted.'};
  }

  Future<void> updateLocation({required double lat, required double lng}) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;
    await dio.put(
      '/api/ambulances/location',
      data: {'lat': lat, 'lng': lng},
      options: _authOptions(token),
    );
  }

  Future<void> updateIncidentStatus({required String incidentId, required String status}) async {
    final token = await _requireToken();
    final response = await dio.put(
      '/api/incidents/$incidentId/status',
      data: {'status': status},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  /// Paramedic: returns only incidents assigned to the calling paramedic's ambulance.
  Future<List<dynamic>> getAssignments() => _getList('/api/incidents', 'incidents');

  /// Dispatcher: returns ALL active incidents (optionally filtered).
  Future<List<dynamic>> getDispatcherIncidents({Map<String, dynamic>? filters}) =>
      _getList('/api/dispatchers/incidents', 'incidents', query: _stringifyQuery(filters));

  Future<List<dynamic>> getAllAmbulances() => _getList('/api/ambulances', 'ambulances');

  Future<void> saveFcmToken(String fcmToken) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;
    await dio.post(
      '/api/users/fcm-token',
      data: {'fcm_token': fcmToken},
      options: _authOptions(token),
    );
  }

  Future<List<dynamic>> getEmergencyHistory() => _getList('/api/patients/history', 'history');

  Future<List<dynamic>> getEmergencyContacts() => _getList('/api/patients/contacts', 'contacts');

  Future<Map<String, dynamic>> getMedicalProfile() async {
    final token = await _requireToken();
    final response = await dio.get(
      '/api/patients/medical-profile',
      options: _authOptions(token),
    );
    if (response.statusCode == 404) return {};
    _ensureOk(response);
    final decoded = _decodeMapEnvelope(response.data);
    if (decoded.isEmpty) return {};
    return _normalizeMedicalProfile(decoded);
  }

  Future<void> updateMedicalProfile(Map<String, dynamic> data) async {
    final token = await _requireToken();
    final response = await dio.put(
      '/api/patients/medical-profile',
      data: data,
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<List<dynamic>> getAssignmentHistory() =>
      _getList('/api/paramedics/history', 'assignments');

  Future<Map<String, dynamic>> getPerformanceStats({String period = 'week'}) =>
      _getMap('/api/paramedics/stats', query: {'period': period});

  Future<List<dynamic>> getEquipment() =>
      _getList('/api/paramedics/equipment', 'equipment');

  Future<void> submitEquipmentChecklist(List<Map<String, dynamic>> items) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/paramedics/equipment/checklist',
      data: {'items': items},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<List<dynamic>> getShifts({DateTime? from, DateTime? to}) {
    final query = <String, dynamic>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    return _getList('/api/paramedics/shifts', 'shifts', query: query.isEmpty ? null : query);
  }

  Future<void> requestShiftSwap({required String shiftId, String? message}) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/paramedics/shifts/swap-request',
      data: {'shift_id': shiftId, if (message != null) 'message': message},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<List<dynamic>> getFleet() => _getList('/api/dispatchers/fleet', 'fleet');

  Future<List<dynamic>> getStaff() => _getList('/api/dispatchers/staff', 'staff');

  Future<List<dynamic>> getIncidentLog({Map<String, dynamic>? filters}) =>
      _getList('/api/dispatchers/incidents', 'incidents', query: _stringifyQuery(filters));

  Future<Map<String, dynamic>> getAnalytics({String period = 'week'}) =>
      _getMap('/api/dispatchers/analytics', query: {'period': period});

  Future<void> updateAmbulanceStatus({
    required String ambulanceId,
    required String status,
  }) async {
    final token = await _requireToken();
    final response = await dio.put(
      '/api/ambulances/$ambulanceId/status',
      data: {'status': status},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<Map<String, dynamic>> addEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
    bool isPrimary = false,
  }) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/patients/contacts',
      data: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'is_primary': isPrimary,
      },
      options: _authOptions(token),
    );
    _ensureOk(response);
    return _decodeMapEnvelope(response.data);
  }

  Future<Map<String, dynamic>> updateEmergencyContact({
    required String contactId,
    required String name,
    required String phone,
    required String relationship,
    bool? isPrimary,
  }) async {
    final token = await _requireToken();
    final response = await dio.put(
      '/api/patients/contacts/$contactId',
      data: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        if (isPrimary != null) 'is_primary': isPrimary,
      },
      options: _authOptions(token),
    );
    _ensureOk(response);
    return _decodeMapEnvelope(response.data);
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    final token = await _requireToken();
    final response = await dio.delete(
      '/api/patients/contacts/$contactId',
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<void> updateParamedicStatus(String status) async {
    final token = await _requireToken();
    final response = await dio.put(
      '/api/paramedics/status',
      data: {'status': status},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<void> assignAmbulance({
    required String incidentId,
    required String ambulanceId,
  }) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/dispatchers/assign',
      data: {
        'incident_id': incidentId,
        'ambulance_id': ambulanceId,
      },
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<Map<String, dynamic>> getActiveIncident() async {
    final token = await _requireToken();
    try {
      final response = await dio.get(
        '/api/patients/active-incident',
        options: _authOptions(token),
      );
      if (response.statusCode == 404) return {};
      _ensureOk(response);
      return _decodeMapEnvelope(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return {};
      rethrow;
    }
  }

  Future<List<dynamic>> getShiftSwapRequests() async {
    return _getList('/api/paramedics/shifts/swap-requests', 'swap_requests');
  }

  Future<void> acceptShiftSwap({
    required String requestId,
    required String yourShiftId,
  }) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/paramedics/shifts/swap-requests/$requestId/accept',
      data: {'your_shift_id': yourShiftId},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<void> declineShiftSwap(String requestId) async {
    final token = await _requireToken();
    final response = await dio.post(
      '/api/paramedics/shifts/swap-requests/$requestId/decline',
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  Future<void> updateShiftStatus({
    required String shiftId,
    required String status,
  }) async {
    final token = await _requireToken();
    final response = await dio.put(
      '/api/paramedics/shifts/$shiftId/status',
      data: {'status': status},
      options: _authOptions(token),
    );
    _ensureOk(response);
  }

  static ApiException wrapError(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final response = error.response;
      if (response != null) return ApiException.fromResponse(response);
      return ApiException(error.message ?? 'Network error');
    }
    return ApiException(error.toString());
  }
}
