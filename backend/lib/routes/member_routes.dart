import 'dart:convert';

import 'package:backend/core/json_response.dart';
import 'package:backend/core/request_parsers.dart';
import 'package:backend/repositories/member_repository.dart';
import 'package:backend/repositories/team_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildMemberRouter({
  required MemberRepository memberRepository,
  required TeamRepository teamRepository,
}) {
  final router = Router()
    ..get('/', (Request request) async {
      final members = await memberRepository.listAll();
      return Response.ok(
        jsonEncode(members.map((m) => m.toJson()).toList(growable: false)),
        headers: _jsonHeaders,
      );
    })
    ..get('/<id|[0-9]+>', (Request request, String id) async {
      final member = await memberRepository.findById(int.parse(id));
      if (member == null) {
        return errorResponse('Integrante nao encontrado.', statusCode: 404);
      }
      return jsonResponse(member.toJson());
    })
    ..post('/', (Request request) async {
      try {
        final body = await readJsonObject(request);
        final payload = _parseMemberPayload(body);

        final team = await teamRepository.findById(payload.teamId);
        if (team == null) {
          return errorResponse('Time informado nao existe.', statusCode: 404);
        }

        final member = await memberRepository.create(
          teamId: payload.teamId,
          fullName: payload.fullName,
          nickname: payload.nickname,
          age: payload.age,
          role: payload.role,
          imageUrl: payload.imageUrl,
          inGameRole: payload.inGameRole,
          dpi: payload.dpi,
          sensitivity: payload.sensitivity,
          resolution: payload.resolution,
          viewmodel: payload.viewmodel,
          crosshair: payload.crosshair,
          twitter: payload.twitter,
          instagram: payload.instagram,
          twitch: payload.twitch,
        );

        return jsonResponse(member.toJson(), statusCode: 201);
      } on RequestFormatException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on _ValidationException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on PgException catch (e) {
        return errorResponse(
          'Erro ao criar integrante: ${e.message}',
          statusCode: 400,
        );
      }
    })
    ..put('/<id|[0-9]+>', (Request request, String id) async {
      try {
        final body = await readJsonObject(request);
        final payload = _parseMemberPayload(body);

        final team = await teamRepository.findById(payload.teamId);
        if (team == null) {
          return errorResponse('Time informado nao existe.', statusCode: 404);
        }

        final updated = await memberRepository.update(
          id: int.parse(id),
          teamId: payload.teamId,
          fullName: payload.fullName,
          nickname: payload.nickname,
          age: payload.age,
          role: payload.role,
          imageUrl: payload.imageUrl,
          inGameRole: payload.inGameRole,
          dpi: payload.dpi,
          sensitivity: payload.sensitivity,
          resolution: payload.resolution,
          viewmodel: payload.viewmodel,
          crosshair: payload.crosshair,
          twitter: payload.twitter,
          instagram: payload.instagram,
          twitch: payload.twitch,
        );

        if (updated == null) {
          return errorResponse('Integrante nao encontrado.', statusCode: 404);
        }

        return jsonResponse(updated.toJson());
      } on RequestFormatException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on _ValidationException catch (e) {
        return errorResponse(e.message, statusCode: 400);
      } on PgException catch (e) {
        return errorResponse(
          'Erro ao atualizar integrante: ${e.message}',
          statusCode: 400,
        );
      }
    })
    ..delete('/<id|[0-9]+>', (Request request, String id) async {
      final deleted = await memberRepository.deleteById(int.parse(id));
      if (!deleted) {
        return errorResponse('Integrante nao encontrado.', statusCode: 404);
      }
      return Response(204);
    });

  return router;
}

class _MemberPayload {
  const _MemberPayload({
    required this.teamId,
    required this.fullName,
    required this.nickname,
    required this.age,
    required this.role,
    required this.imageUrl,
    required this.inGameRole,
    required this.dpi,
    required this.sensitivity,
    required this.resolution,
    required this.viewmodel,
    required this.crosshair,
    required this.twitter,
    required this.instagram,
    required this.twitch,
  });

  final int teamId;
  final String fullName;
  final String nickname;
  final int age;
  final String role;
  final String? imageUrl;
  final String? inGameRole;
  final int? dpi;
  final double? sensitivity;
  final String? resolution;
  final String? viewmodel;
  final String crosshair;
  final String? twitter;
  final String? instagram;
  final String? twitch;
}

class _ValidationException implements Exception {
  _ValidationException(this.message);

  final String message;
}

_MemberPayload _parseMemberPayload(Map<String, dynamic> body) {
  final teamId = _toInt(body['team_id']);
  final nickname = (body['nickname'] ?? '').toString().trim();
  final role = (body['role'] ?? '').toString().trim().toLowerCase();
  final age = body['age'] == null ? 20 : _toInt(body['age']);
  final imageUrl = _nullable(body['image_url']);
  final inGameRole = _nullable(body['in_game_role']);
  final dpi = _toNullableInt(body['dpi']);
  final sensitivity = _toNullableDouble(body['sensitivity']);
  final resolution = _nullable(body['resolution']);
  final viewmodel = _nullable(body['viewmodel']);
  final crosshair = (body['crosshair'] ?? '').toString();
  final fullNameValue = _nullable(body['full_name']);
  final fullName = (fullNameValue == null || fullNameValue.isEmpty)
      ? nickname
      : fullNameValue;

  final twitter = _nullable(body['twitter']);
  final instagram = _nullable(body['instagram']);
  final twitch = _nullable(body['twitch']);

  if (teamId <= 0) {
    throw _ValidationException('Campo team_id e obrigatorio.');
  }

  if (nickname.isEmpty) {
    throw _ValidationException('Campo nickname e obrigatorio.');
  }

  if (role != 'player' && role != 'coach') {
    throw _ValidationException('Campo role deve ser player ou coach.');
  }

  if (age <= 0) {
    throw _ValidationException('Campo age deve ser maior que zero.');
  }

  return _MemberPayload(
    teamId: teamId,
    fullName: fullName,
    nickname: nickname,
    age: age,
    role: role,
    imageUrl: imageUrl,
    inGameRole: inGameRole,
    dpi: dpi,
    sensitivity: sensitivity,
    resolution: resolution,
    viewmodel: viewmodel,
    crosshair: crosshair,
    twitter: twitter,
    instagram: instagram,
    twitch: twitch,
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

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
