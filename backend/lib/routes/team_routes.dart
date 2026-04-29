import 'dart:convert';

import 'package:backend/core/json_response.dart';
import 'package:backend/core/request_parsers.dart';
import 'package:backend/repositories/member_repository.dart';
import 'package:backend/repositories/team_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildTeamRouter({
  required TeamRepository teamRepository,
  required MemberRepository memberRepository,
}) {
  final router = Router()
    ..get('/', (Request request) async {
      final teams = await teamRepository.listAll();
      return Response.ok(
        jsonEncode(teams.map((team) => team.toJson()).toList(growable: false)),
        headers: _jsonHeaders,
      );
    })
    ..get('/<id|[0-9]+>', (Request request, String id) async {
      final team = await teamRepository.findById(int.parse(id));
      if (team == null) {
        return errorResponse('Time nao encontrado.', statusCode: 404);
      }
      return jsonResponse(team.toJson());
    })
    ..get('/<id|[0-9]+>/members', (Request request, String id) async {
      final teamId = int.parse(id);
      final team = await teamRepository.findById(teamId);
      if (team == null) {
        return errorResponse('Time nao encontrado.', statusCode: 404);
      }

      final members = await memberRepository.listByTeamId(teamId);
      return Response.ok(
        jsonEncode(
          members.map((member) => member.toJson()).toList(growable: false),
        ),
        headers: _jsonHeaders,
      );
    })
    ..post('/', (Request request) async {
      try {
        final body = await readJsonObject(request);
        final payload = _parseTeamPayload(body);

        final team = await teamRepository.create(
          name: payload.name,
          tag: payload.tag,
          region: payload.region,
          ranking: payload.ranking,
          logoUrl: payload.logoUrl,
        );

        return jsonResponse(team.toJson(), statusCode: 201);
      } on RequestFormatException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on _ValidationException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on PgException catch (e) {
        return errorResponse(
          'Erro ao criar time: ${e.message}',
          statusCode: 400,
        );
      }
    })
    ..put('/<id|[0-9]+>', (Request request, String id) async {
      try {
        final body = await readJsonObject(request);
        final payload = _parseTeamPayload(body);

        final updated = await teamRepository.update(
          id: int.parse(id),
          name: payload.name,
          tag: payload.tag,
          region: payload.region,
          ranking: payload.ranking,
          logoUrl: payload.logoUrl,
        );

        if (updated == null) {
          return errorResponse('Time nao encontrado.', statusCode: 404);
        }

        return jsonResponse(updated.toJson());
      } on RequestFormatException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on _ValidationException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on PgException catch (e) {
        return errorResponse(
          'Erro ao atualizar time: ${e.message}',
          statusCode: 400,
        );
      }
    })
    ..delete('/<id|[0-9]+>', (Request request, String id) async {
      final deleted = await teamRepository.deleteById(int.parse(id));
      if (!deleted) {
        return errorResponse('Time nao encontrado.', statusCode: 404);
      }
      return Response(204);
    });

  return router;
}

class _TeamPayload {
  const _TeamPayload({
    required this.name,
    required this.tag,
    required this.region,
    required this.ranking,
    required this.logoUrl,
  });

  final String name;
  final String tag;
  final String region;
  final int ranking;
  final String? logoUrl;
}

class _ValidationException implements Exception {
  _ValidationException(this.message);

  final String message;
}

_TeamPayload _parseTeamPayload(Map<String, dynamic> body) {
  final name = (body['name'] ?? '').toString().trim();
  final tag = (body['tag'] ?? '').toString().trim();
  final region = (body['region'] ?? '').toString().trim();
  final ranking = _toInt(body['ranking']);
  final logoUrl = _nullable(body['logo_url']);

  if (name.isEmpty) {
    throw _ValidationException('Campo name e obrigatorio.');
  }

  if (tag.isEmpty) {
    throw _ValidationException('Campo tag e obrigatorio.');
  }

  if (region.isEmpty) {
    throw _ValidationException('Campo region e obrigatorio.');
  }

  if (ranking <= 0) {
    throw _ValidationException('Campo ranking deve ser maior que zero.');
  }

  return _TeamPayload(
    name: name,
    tag: tag,
    region: region,
    ranking: ranking,
    logoUrl: logoUrl,
  );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String? _nullable(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return text;
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
