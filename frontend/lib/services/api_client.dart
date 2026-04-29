import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException({
    required this.message,
    required this.statusCode,
  });

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.authToken,
  });

  final String baseUrl;
  final String? authToken;

  Future<Map<String, dynamic>> getObject(
    String path,
  ) async {
    final response = await _request(method: 'GET', path: path);
    final jsonBody = _decode(response);
    if (jsonBody is Map<String, dynamic>) {
      return jsonBody;
    }

    throw ApiException(
      message: 'Resposta inesperada do servidor.',
      statusCode: response.statusCode,
    );
  }

  Future<List<dynamic>> getList(
    String path,
  ) async {
    final response = await _request(method: 'GET', path: path);
    final jsonBody = _decode(response);
    if (jsonBody is List<dynamic>) {
      return jsonBody;
    }

    throw ApiException(
      message: 'Resposta inesperada do servidor.',
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> postObject(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _request(method: 'POST', path: path, body: body);
    final jsonBody = _decode(response);
    if (jsonBody is Map<String, dynamic>) {
      return jsonBody;
    }

    throw ApiException(
      message: 'Resposta inesperada do servidor.',
      statusCode: response.statusCode,
    );
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    late final http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        default:
          throw UnsupportedError('Método $method não suportado');
      }
    } catch (_) {
      throw ApiException(
        message: 'Não foi possível conectar à API. Verifique se o backend está rodando.',
        statusCode: 0,
      );
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        message: _extractError(response),
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }

  String _extractError(http.Response response) {
    if (response.body.isEmpty) {
      return 'Falha ao processar requisição.';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message != null) {
          return message.toString();
        }
      }
    } catch (_) {
      return 'Falha ao processar requisição.';
    }

    return 'Falha ao processar requisição.';
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
