import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/visitor.dart';
import 'visitor_repository.dart';

class ApiVisitorRepository extends VisitorRepository {
  ApiVisitorRepository(String url, {http.Client? client})
    : _base = Uri.parse(url.replaceAll(RegExp(r'/+$'), '')),
      _client = client ?? http.Client() {
    if (_base.scheme != 'https' ||
        _base.host.isEmpty ||
        _base.hasQuery ||
        _base.hasFragment) {
      throw ArgumentError(
        'API_BASE_URL must be an HTTPS visitors collection URL.',
      );
    }
  }
  final Uri _base;
  final http.Client _client;
  Future<dynamic> _request(
    String method, {
    String? id,
    Map<String, dynamic>? body,
  }) async {
    final uri = id == null
        ? _base
        : Uri.parse('$_base/${Uri.encodeComponent(id)}');
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(const Duration(seconds: 20));
      if (response.statusCode == 404) {
        throw const VisitorException(
          'Visitor not found. It may have been deleted.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VisitorException(
          'Request failed (${response.statusCode}). Please try again.',
        );
      }
      return method == 'DELETE' ? null : jsonDecode(response.body);
    } on TimeoutException {
      throw const VisitorException(
        'The server took too long. Check your connection and retry.',
      );
    } on http.ClientException {
      throw const VisitorException(
        'Unable to connect. Check your connection and API URL.',
      );
    } on FormatException {
      throw const VisitorException('The API returned an invalid response.');
    }
  }

  Visitor _visitor(dynamic json) {
    try {
      if (json is! Map<String, dynamic>) throw const FormatException();
      return Visitor.fromJson(json);
    } catch (_) {
      throw const VisitorException(
        'The API returned an invalid visitor record.',
      );
    }
  }

  @override
  Future<List<Visitor>> list() async {
    final json = await _request('GET');
    if (json is! List) {
      throw const VisitorException('The API must return a JSON array.');
    }
    return json.map(_visitor).toList();
  }

  @override
  Future<Visitor> get(String id) async =>
      _visitor(await _request('GET', id: id));
  @override
  Future<Visitor> create(Map<String, dynamic> fields) async =>
      _visitor(await _request('POST', body: fields));
  @override
  Future<Visitor> update(String id, Map<String, dynamic> fields) async =>
      _visitor(await _request('PUT', id: id, body: fields));
  @override
  Future<void> delete(String id) async {
    await _request('DELETE', id: id);
  }

  @override
  void dispose() => _client.close();
}
