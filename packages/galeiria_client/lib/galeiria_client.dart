import 'dart:convert';

import 'package:http/http.dart' as http;

class GaleiriaClient {
  GaleiriaClient({required this.baseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  String baseUrl;
  final http.Client _http;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final values = query?.map((key, value) => MapEntry(key, value.toString()));
    return Uri.parse('$root$path').replace(queryParameters: values);
  }

  Future<Map<String, dynamic>> health() async {
    final response = await _http.get(_uri('/health'));
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stats() async {
    final response = await _http.get(_uri('/api/v1/stats'));
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> photos({int limit = 100, int offset = 0}) async {
    final response = await _http.get(_uri('/api/v1/photos', {'limit': limit, 'offset': offset}));
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> exactDuplicates({int limit = 100}) async {
    final response = await _http.get(_uri('/api/v1/duplicates/exact', {'limit': limit}));
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> nearDuplicates({int maxDistance = 5, int limit = 200}) async {
    final response = await _http.get(_uri('/api/v1/duplicates/near', {
      'max_distance': maxDistance,
      'limit': limit,
    }));
    _ensureSuccess(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> startScan(String path) async {
    final response = await _http.post(
      _uri('/api/v1/scan-jobs'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'path': path}),
    );
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scanJob(int id) async {
    final response = await _http.get(_uri('/api/v1/scan-jobs/$id'));
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String thumbnailUrl(int photoId) => '${_root()}/api/v1/photos/$photoId/thumbnail';
  String fileUrl(int photoId) => '${_root()}/api/v1/photos/$photoId/file';

  String _root() => baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GaleiriaApiException(response.statusCode, response.body);
    }
  }

  void close() => _http.close();
}

class GaleiriaApiException implements Exception {
  GaleiriaApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'GaleiriaApiException($statusCode): $body';
}
