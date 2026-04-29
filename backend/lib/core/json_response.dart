import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

Response errorResponse(String message, {int statusCode = 400}) {
  return jsonResponse({'message': message}, statusCode: statusCode);
}
