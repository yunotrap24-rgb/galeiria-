import 'dart:convert';

import 'package:http/http.dart' as http;

class GaleiriaClient {
  GaleiriaClient({required this.baseUrl, this.token, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  String baseUrl;
  String? token;
  final http.Client _http;

  Map<String, String> get authHeaders {
    final value = token?.trim();
    return value == null || value.isEmpty ? const {} : {'authorization': 'Bearer $value'};
  }

  Map<String, String> _headers({bool json = false}) => {
        ...authHeaders,
        if (json) 'content-type': 'application/json',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final root = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final values = query?.map((key, value) => MapEntry(key, value.toString()));
    return Uri.parse('$root$path').replace(queryParameters: values);
  }

  Future<dynamic> _decode(http.Response response) async {
    _ensureSuccess(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> health() async {
    return (await _decode(await _http.get(_uri('/health'), headers: _headers()))) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> serverInfo() async {
    return (await _decode(await _http.get(_uri('/api/v1/server'), headers: _headers()))) as Map<String, dynamic>;
  }

  Future<String> localPairingToken() async {
    final data = (await _decode(await _http.get(_uri('/api/v1/server/pairing-token'), headers: _headers()))) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<Map<String, dynamic>> stats() async {
    return (await _decode(await _http.get(_uri('/api/v1/stats'), headers: _headers()))) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> photos({int limit = 100, int offset = 0}) async {
    final data = await _decode(await _http.get(
      _uri('/api/v1/photos', {'limit': limit, 'offset': offset}),
      headers: _headers(),
    )) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> photo(int id) async {
    return (await _decode(await _http.get(_uri('/api/v1/photos/$id'), headers: _headers()))) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> search(String query, {int limit = 100}) async {
    final data = await _decode(await _http.get(
      _uri('/api/v1/search', {'q': query, 'limit': limit}),
      headers: _headers(),
    )) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> exactDuplicates({int limit = 100}) async {
    final data = await _decode(await _http.get(
      _uri('/api/v1/duplicates/exact', {'limit': limit}),
      headers: _headers(),
    )) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> nearDuplicates({int maxDistance = 5, int limit = 200}) async {
    final data = await _decode(await _http.get(
      _uri('/api/v1/duplicates/near', {'max_distance': maxDistance, 'limit': limit}),
      headers: _headers(),
    )) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> startScan(String path) async {
    final response = await _http.post(
      _uri('/api/v1/scan-jobs'),
      headers: _headers(json: true),
      body: jsonEncode({'path': path}),
    );
    return (await _decode(response)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scanJob(int id) async {
    return (await _decode(await _http.get(_uri('/api/v1/scan-jobs/$id'), headers: _headers()))) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> tags() async {
    final data = await _decode(await _http.get(_uri('/api/v1/tags'), headers: _headers())) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTag(String name) async {
    final response = await _http.post(
      _uri('/api/v1/tags'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name}),
    );
    return (await _decode(response)) as Map<String, dynamic>;
  }

  Future<void> assignTag(int photoId, int tagId, {String source = 'user', double? confidence}) async {
    await _decode(await _http.post(
      _uri('/api/v1/photos/$photoId/tags'),
      headers: _headers(json: true),
      body: jsonEncode({'tag_id': tagId, 'source': source, 'confidence': confidence}),
    ));
  }

  Future<List<Map<String, dynamic>>> projects() async {
    final data = await _decode(await _http.get(_uri('/api/v1/projects'), headers: _headers())) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProject(String name, {String description = ''}) async {
    final response = await _http.post(
      _uri('/api/v1/projects'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name, 'description': description}),
    );
    return (await _decode(response)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> project(int id) async {
    return (await _decode(await _http.get(_uri('/api/v1/projects/$id'), headers: _headers()))) as Map<String, dynamic>;
  }

  Future<void> addPhotoToProject(int projectId, int photoId, {String stage = 'reference'}) async {
    await _decode(await _http.post(
      _uri('/api/v1/projects/$projectId/photos'),
      headers: _headers(json: true),
      body: jsonEncode({'photo_id': photoId, 'stage': stage}),
    ));
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
