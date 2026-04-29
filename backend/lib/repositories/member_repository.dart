import 'package:backend/models/member.dart';
import 'package:postgres/postgres.dart';

class MemberRepository {
  const MemberRepository(this._pool);

  final Pool _pool;

  Future<List<Member>> listAll() async {
    final result = await _pool.execute('''
      SELECT id, team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair, twitter, instagram, twitch, created_at
      FROM members
      ORDER BY team_id ASC, role DESC, nickname ASC
    ''');

    return result
        .map((row) => Member.fromDb(row.toColumnMap()))
        .toList(growable: false);
  }

  Future<Member?> findById(int id) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT id, team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair, twitter, instagram, twitch, created_at
        FROM members
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return Member.fromDb(result.first.toColumnMap());
  }

  Future<List<Member>> listByTeamId(int teamId) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT id, team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair, twitter, instagram, twitch, created_at
        FROM members
        WHERE team_id = @team_id
        ORDER BY role DESC, nickname ASC
      '''),
      parameters: {'team_id': teamId},
    );

    return result
        .map((row) => Member.fromDb(row.toColumnMap()))
        .toList(growable: false);
  }

  Future<Member> create({
    required int teamId,
    required String fullName,
    required String nickname,
    required int age,
    required String role,
    String? imageUrl,
    String? inGameRole,
    int? dpi,
    double? sensitivity,
    String? resolution,
    String? viewmodel,
    required String crosshair,
    String? twitter,
    String? instagram,
    String? twitch,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO members (team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair, twitter, instagram, twitch)
        VALUES (@team_id, @full_name, @nickname, @age, @role, @image_url, @in_game_role, @dpi, @sensitivity, @resolution, @viewmodel, @crosshair, @twitter, @instagram, @twitch)
        RETURNING id, team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair, twitter, instagram, twitch, created_at
      '''),
      parameters: {
        'team_id': teamId,
        'full_name': fullName,
        'nickname': nickname,
        'age': age,
        'role': role,
        'image_url': imageUrl,
        'in_game_role': inGameRole,
        'dpi': dpi,
        'sensitivity': sensitivity,
        'resolution': resolution,
        'viewmodel': viewmodel,
        'crosshair': crosshair,
        'twitter': twitter,
        'instagram': instagram,
        'twitch': twitch,
      },
    );

    return Member.fromDb(result.first.toColumnMap());
  }

  Future<Member?> update({
    required int id,
    required int teamId,
    required String fullName,
    required String nickname,
    required int age,
    required String role,
    String? imageUrl,
    String? inGameRole,
    int? dpi,
    double? sensitivity,
    String? resolution,
    String? viewmodel,
    required String crosshair,
    String? twitter,
    String? instagram,
    String? twitch,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE members
        SET team_id = @team_id,
            full_name = @full_name,
            nickname = @nickname,
            age = @age,
            role = @role,
            image_url = @image_url,
            in_game_role = @in_game_role,
            dpi = @dpi,
            sensitivity = @sensitivity,
            resolution = @resolution,
            viewmodel = @viewmodel,
            crosshair = @crosshair,
            twitter = @twitter,
            instagram = @instagram,
            twitch = @twitch
        WHERE id = @id
        RETURNING id, team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair, twitter, instagram, twitch, created_at
      '''),
      parameters: {
        'id': id,
        'team_id': teamId,
        'full_name': fullName,
        'nickname': nickname,
        'age': age,
        'role': role,
        'image_url': imageUrl,
        'in_game_role': inGameRole,
        'dpi': dpi,
        'sensitivity': sensitivity,
        'resolution': resolution,
        'viewmodel': viewmodel,
        'crosshair': crosshair,
        'twitter': twitter,
        'instagram': instagram,
        'twitch': twitch,
      },
    );

    if (result.isEmpty) return null;
    return Member.fromDb(result.first.toColumnMap());
  }

  Future<bool> deleteById(int id) async {
    final result = await _pool.execute(
      Sql.named('DELETE FROM members WHERE id = @id'),
      parameters: {'id': id},
    );

    return result.affectedRows > 0;
  }
}
