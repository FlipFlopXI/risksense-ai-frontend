import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'risksense_access_token';
  static const _refreshKey = 'risksense_refresh_token';
  static const _roleKey = 'risksense_role';
  final Dio _dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('RISKSENSE_API_URL',
        defaultValue: 'http://10.0.2.2:8000'),
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));
  String? _accessToken;
  String? _refreshToken;
  String? _role;
  Future<void>? _restoreFuture;
  String? get role => _role;
  DateTime? get accessTokenExpiresAt {
    final token = _accessToken;
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
          isUtc: true);
    } catch (_) {
      return null;
    }
  }

  bool get hasStoredSession => _accessToken != null && _refreshToken != null;

  Future<void> restore() => _restoreFuture ??= _readStoredSession();

  Future<void> _readStoredSession() async {
    _accessToken ??= await _storage.read(key: _accessKey);
    _refreshToken ??= await _storage.read(key: _refreshKey);
    _role ??= await _storage.read(key: _roleKey);
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    await restore();
    if (!hasStoredSession) return null;
    try {
      final user = Map<String, dynamic>.from(await get('/auth/me'));
      _role = user['role']?.toString().toUpperCase();
      await _storage.write(key: _roleKey, value: _role);
      return user;
    } on ApiException {
      await logout();
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login',
          data: {'username': email.trim(), 'password': password},
          options: Options(contentType: Headers.formUrlEncodedContentType));
      await _saveTokens(Map<String, dynamic>.from(response.data));
      final user = Map<String, dynamic>.from(await get('/auth/me'));
      _role = user['role']?.toString();
      await _storage.write(key: _roleKey, value: _role);
      return user;
    } on DioException catch (error) {
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      return Map<String, dynamic>.from(
          (await _dio.post('/auth/register', data: body)).data);
    } on DioException catch (error) {
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> resendRegistrationCode(String email) async {
    try {
      return Map<String, dynamic>.from((await _dio
              .post('/auth/register/resend', data: {'email': email.trim()}))
          .data);
    } on DioException catch (error) {
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationCode(
      String email, String code) async {
    try {
      return Map<String, dynamic>.from((await _dio.post('/auth/register/verify',
              data: {'email': email.trim(), 'code': code}))
          .data);
    } on DioException catch (error) {
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> requestPasswordRecovery(String email) async {
    try {
      return Map<String, dynamic>.from((await _dio.post(
              '/auth/password-recovery/start',
              data: {'email': email.trim()}))
          .data);
    } on DioException catch (error) {
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<void> completePasswordRecovery(String email, String code) async {
    try {
      await _dio.post('/auth/password-recovery/complete',
          data: {'email': email.trim(), 'code': code});
    } on DioException catch (error) {
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<void> logout() async {
    final refresh = _refreshToken;
    try {
      if (refresh != null && _accessToken != null) {
        await _dio.post('/auth/logout',
            data: {'refresh_token': refresh}, options: _authorized());
      }
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _role = null;
      await _storage.deleteAll();
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);
  Future<Uint8List> getBytes(String path) async => Uint8List.fromList(
      (await _request('GET', path, responseType: ResponseType.bytes) as List)
          .cast<int>());
  Future<dynamic> post(String path, {Object? data}) =>
      _request('POST', path, data: data);
  Future<dynamic> patch(String path, {Object? data}) =>
      _request('PATCH', path, data: data);
  Future<dynamic> put(String path, {Object? data}) =>
      _request('PUT', path, data: data);
  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<Uri> issueActivationUrl() async {
    final response = Map<String, dynamic>.from(
        await post('/api/v1/access/activation-session') as Map);
    final uri = Uri.tryParse(response['activation_url']?.toString() ?? '');
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                (uri.host == 'localhost' || uri.host == '127.0.0.1')))) {
      throw ApiException(
          'The activation URL returned by the backend is invalid.');
    }
    return _websiteUriForDevice(uri);
  }

  Future<Uri> issueSubscriptionRenewalUrl() async {
    final response = Map<String, dynamic>.from(
        await post('/api/v1/access/subscription-renewal-session') as Map);
    final uri = Uri.tryParse(response['activation_url']?.toString() ?? '');
    if (uri == null ||
        uri.path != '/profile' ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                (uri.host == 'localhost' || uri.host == '127.0.0.1')))) {
      throw ApiException('The renewal URL returned by the backend is invalid.');
    }
    return _websiteUriForDevice(uri);
  }

  Uri _websiteUriForDevice(Uri uri) {
    // The Android emulator reaches services on the development machine through
    // 10.0.2.2. Its own localhost cannot reach the Windows website server.
    final apiHost = Uri.tryParse(_dio.options.baseUrl)?.host;
    if (apiHost == '10.0.2.2' &&
        uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2');
    }
    return uri;
  }

  Future<Map<String, dynamic>> accessStatus() async =>
      Map<String, dynamic>.from(await get('/api/v1/access/status') as Map);

  Future<dynamic> _request(String method, String path,
      {Object? data,
      Map<String, dynamic>? query,
      ResponseType? responseType,
      bool retry = true}) async {
    await restore();
    try {
      return (await _dio.request(path,
              data: data,
              queryParameters: query,
              options: _authorized(method: method, responseType: responseType)))
          .data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && retry && await _refresh()) {
        return _request(method, path,
            data: data, query: query, responseType: responseType, retry: false);
      }
      throw ApiException(_message(error),
          statusCode: error.response?.statusCode);
    }
  }

  Future<bool> _refresh() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _dio
          .post('/auth/refresh', data: {'refresh_token': _refreshToken});
      await _saveTokens(Map<String, dynamic>.from(response.data));
      return true;
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
      _role = null;
      await _storage.deleteAll();
      return false;
    }
  }

  Options _authorized({String? method, ResponseType? responseType}) => Options(
      method: method,
      responseType: responseType,
      headers: _accessToken == null
          ? null
          : {'Authorization': 'Bearer $_accessToken'});

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    if (_accessToken == null || _refreshToken == null) {
      throw ApiException('Incomplete authentication response.');
    }
    await _storage.write(key: _accessKey, value: _accessToken);
    await _storage.write(key: _refreshKey, value: _refreshToken);
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is Map) {
        final message = detail['message']?.toString();
        final fields = detail['fields'] ??
            detail['missing_fields'] ??
            detail['invalid_fields'];
        if (message != null) {
          return fields is List && fields.isNotEmpty
              ? '$message Required fields: ${fields.join(', ')}.'
              : message;
        }
      }
      return detail.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Unable to reach the RiskSense API. Check that the local backend is running.';
    }
    return 'The request could not be completed.';
  }
}
