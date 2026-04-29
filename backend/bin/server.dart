import 'dart:io';

import 'package:backend/config/app_env.dart';
import 'package:backend/core/json_response.dart';
import 'package:backend/database/database.dart';
import 'package:backend/repositories/member_repository.dart';
import 'package:backend/repositories/team_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/routes/auth_routes.dart';
import 'package:backend/routes/member_routes.dart';
import 'package:backend/routes/team_routes.dart';
import 'package:backend/services/auth_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  final env = AppEnv.load();
  final database = await Database.connect(env.databaseUrl);
  await database.bootstrap();

  final authService = AuthService(
    userRepository: UserRepository(database.pool),
    jwtSecret: env.jwtSecret,
  );
  final teamRepository = TeamRepository(database.pool);
  final memberRepository = MemberRepository(database.pool);

  final router = Router()
    ..get('/health', (_) async => jsonResponse({'status': 'ok'}))
    ..mount('/auth', buildAuthRouter(authService).call)
    ..mount(
      '/teams',
      buildTeamRouter(
        teamRepository: teamRepository,
        memberRepository: memberRepository,
      ).call,
    )
    ..mount(
      '/members',
      buildMemberRouter(
        memberRepository: memberRepository,
        teamRepository: teamRepository,
      ).call,
    );

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);
  stdout.writeln('API on http://${server.address.host}:${server.port}');

  await ProcessSignal.sigint.watch().first;
  stdout.writeln('\nEncerrando servidor...');
  await server.close(force: true);
  await database.close();
}
