import 'package:backend/core/json_response.dart';
import 'package:backend/core/request_parsers.dart';
import 'package:backend/services/auth_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildAuthRouter(AuthService authService) {
  final router = Router()
    ..post('/register', (Request request) async {
      try {
        final body = await readJsonObject(request);
        final email = (body['email'] ?? '').toString();
        final password = (body['password'] ?? '').toString();
        final name = (body['name'] ?? '').toString();

        final result = await authService.register(
          name: name,
          email: email,
          password: password,
        );

        return jsonResponse({
          'token': result.token,
          'user': result.user.toPublicJson(),
        }, statusCode: 201);
      } on RequestFormatException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on AuthException catch (e) {
        return errorResponse(e.message, statusCode: e.statusCode);
      }
    })
    ..post('/login', (Request request) async {
      try {
        final body = await readJsonObject(request);
        final email = (body['email'] ?? '').toString();
        final password = (body['password'] ?? '').toString();

        final result = await authService.login(
          email: email,
          password: password,
        );

        return jsonResponse({
          'token': result.token,
          'user': result.user.toPublicJson(),
        });
      } on RequestFormatException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on AuthException catch (e) {
        return errorResponse(e.message, statusCode: e.statusCode);
      }
    })
    ..get('/me', (Request request) async {
      try {
        final token = bearerTokenFrom(request);
        if (token == null || token.isEmpty) {
          return errorResponse('Token ausente.', statusCode: 401);
        }

        final user = await authService.me(token);
        return jsonResponse(user.toPublicJson());
      } on AuthException catch (e) {
        return errorResponse(e.message, statusCode: e.statusCode);
      }
    });

  return router;
}
