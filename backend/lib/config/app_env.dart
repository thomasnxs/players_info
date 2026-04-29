import 'dart:io';

import 'package:dotenv/dotenv.dart';

class AppEnv {
  AppEnv({
    required this.databaseUrl,
    required this.jwtSecret,
    required this.port,
  });

  final String databaseUrl;
  final String jwtSecret;
  final int port;

  static AppEnv load() {
    final env = DotEnv(includePlatformEnvironment: true);
    if (File('.env').existsSync()) {
      env.load();
    }

    final databaseUrl = _normalizeDatabaseUrl(env['DATABASE_URL'] ?? '');
    final jwtSecret = env['JWT_SECRET'] ?? '';
    final port = int.tryParse(env['PORT'] ?? '') ?? 8080;

    if (databaseUrl.isEmpty) {
      throw StateError('DATABASE_URL nao definida.');
    }

    if (jwtSecret.isEmpty) {
      throw StateError('JWT_SECRET nao definida.');
    }

    return AppEnv(databaseUrl: databaseUrl, jwtSecret: jwtSecret, port: port);
  }

  static String _normalizeDatabaseUrl(String value) {
    if (value.isEmpty) return value;

    final uri = Uri.parse(value);
    if (!uri.queryParameters.containsKey('channel_binding')) {
      return value;
    }

    final filtered = Map<String, String>.from(uri.queryParameters)
      ..remove('channel_binding');
    return uri.replace(queryParameters: filtered).toString();
  }
}
