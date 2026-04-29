import 'dart:convert';

import 'package:shelf/shelf.dart';

class RequestFormatException implements Exception {
  RequestFormatException(this.message);

  final String message;
}

Future<Map<String, dynamic>> readJsonObject(Request request) async {
  final body = await request.readAsString();

  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }

  late final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw RequestFormatException('JSON invalido.');
  }

  if (decoded is! Map<String, dynamic>) {
    throw RequestFormatException('Body JSON deve ser um objeto.');
  }

  return decoded;
}

String? bearerTokenFrom(Request request) {
  final value = request.headers['authorization'];
  if (value == null || value.isEmpty) return null;

  const prefix = 'bearer ';
  final normalized = value.trim();
  if (normalized.toLowerCase().startsWith(prefix)) {
    return normalized.substring(prefix.length).trim();
  }

  return null;
}
