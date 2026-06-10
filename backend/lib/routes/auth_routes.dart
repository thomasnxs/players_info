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
  router.put('/me', (Request request) async {
    try {
      final token = bearerTokenFrom(request);
      if (token == null || token.isEmpty) {
        return errorResponse('Token ausente.', statusCode: 401);
      }

      final body = await readJsonObject(request);
      final payload = _parseProfilePayload(body);

      final user = await authService.updateMe(
        token: token,
        name: payload.name,
        nickname: payload.nickname,
        imageUrl: payload.imageUrl,
        dpi: payload.dpi,
        sensitivity: payload.sensitivity,
        resolution: payload.resolution,
        viewmodel: payload.viewmodel,
        crosshair: payload.crosshair,
      );

      return jsonResponse(user.toPublicJson());
    } on RequestFormatException catch (e) {
      return errorResponse(e.message, statusCode: 400);
    } on AuthException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on _ValidationException catch (e) {
      return errorResponse(e.message, statusCode: 400);
    }
  });
  router.delete('/me', (Request request) async {
    try {
      final token = bearerTokenFrom(request);
      if (token == null || token.isEmpty) {
        return errorResponse('Token ausente.', statusCode: 401);
      }

      await authService.deleteMe(token);
      return Response(204);
    } on AuthException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    }
  });

  return router;
}

class _ProfilePayload {
  const _ProfilePayload({
    required this.name,
    required this.nickname,
    required this.imageUrl,
    required this.dpi,
    required this.sensitivity,
    required this.resolution,
    required this.viewmodel,
    required this.crosshair,
  });

  final String name;
  final String nickname;
  final String imageUrl;
  final int dpi;
  final double sensitivity;
  final String resolution;
  final String viewmodel;
  final String crosshair;
}

_ProfilePayload _parseProfilePayload(Map<String, dynamic> body) {
  final name = (body['name'] ?? '').toString().trim();
  final nickname = (body['nickname'] ?? '').toString().trim();
  final imageUrl = (body['image_url'] ?? '').toString().trim();
  final dpi = _toInt(body['dpi']);
  final sensitivity = _toDouble(body['sensitivity']);
  final resolution = (body['resolution'] ?? '').toString().trim();
  final viewmodel = (body['viewmodel'] ?? '').toString().trim();
  final crosshair = (body['crosshair'] ?? '').toString().trim();

  if (name.isEmpty) {
    throw _ValidationException('Campo name e obrigatorio.');
  }
  if (nickname.isEmpty) {
    throw _ValidationException('Campo nickname e obrigatorio.');
  }
  if (imageUrl.isEmpty) {
    throw _ValidationException('Campo image_url e obrigatorio.');
  }
  if (dpi <= 0) {
    throw _ValidationException('Campo dpi deve ser maior que zero.');
  }
  if (sensitivity <= 0) {
    throw _ValidationException('Campo sensitivity deve ser maior que zero.');
  }
  if (resolution.isEmpty) {
    throw _ValidationException('Campo resolution e obrigatorio.');
  }
  if (viewmodel.isEmpty) {
    throw _ValidationException('Campo viewmodel e obrigatorio.');
  }
  if (crosshair.isEmpty) {
    throw _ValidationException('Campo crosshair e obrigatorio.');
  }

  return _ProfilePayload(
    name: name,
    nickname: nickname,
    imageUrl: imageUrl,
    dpi: dpi,
    sensitivity: sensitivity,
    resolution: resolution,
    viewmodel: viewmodel,
    crosshair: crosshair,
  );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class _ValidationException implements Exception {
  _ValidationException(this.message);

  final String message;
}
