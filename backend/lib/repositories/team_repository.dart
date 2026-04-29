import 'package:backend/models/team.dart';
import 'package:postgres/postgres.dart';

class TeamRepository {
  const TeamRepository(this._pool);

  final Pool _pool;

  Future<List<Team>> listAll() async {
    final result = await _pool.execute('''
      SELECT id, name, tag, region, ranking, logo_url, created_at
      FROM teams
      ORDER BY ranking ASC, name ASC
    ''');

    return result
        .map((row) => Team.fromDb(row.toColumnMap()))
        .toList(growable: false);
  }

  Future<Team?> findById(int id) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT id, name, tag, region, ranking, logo_url, created_at
        FROM teams
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return Team.fromDb(result.first.toColumnMap());
  }

  Future<int> count() async {
    final result = await _pool.execute('SELECT COUNT(*) AS count FROM teams');
    return _toInt(result.first.toColumnMap()['count']);
  }

  Future<Team> create({
    required String name,
    required String tag,
    required String region,
    required int ranking,
    String? logoUrl,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO teams (name, tag, region, ranking, logo_url)
        VALUES (@name, @tag, @region, @ranking, @logo_url)
        RETURNING id, name, tag, region, ranking, logo_url, created_at
      '''),
      parameters: {
        'name': name,
        'tag': tag,
        'region': region,
        'ranking': ranking,
        'logo_url': logoUrl,
      },
    );

    return Team.fromDb(result.first.toColumnMap());
  }

  Future<Team?> update({
    required int id,
    required String name,
    required String tag,
    required String region,
    required int ranking,
    String? logoUrl,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE teams
        SET name = @name,
            tag = @tag,
            region = @region,
            ranking = @ranking,
            logo_url = @logo_url
        WHERE id = @id
        RETURNING id, name, tag, region, ranking, logo_url, created_at
      '''),
      parameters: {
        'id': id,
        'name': name,
        'tag': tag,
        'region': region,
        'ranking': ranking,
        'logo_url': logoUrl,
      },
    );

    if (result.isEmpty) return null;
    return Team.fromDb(result.first.toColumnMap());
  }

  Future<bool> deleteById(int id) async {
    final result = await _pool.execute(
      Sql.named('DELETE FROM teams WHERE id = @id'),
      parameters: {'id': id},
    );

    return result.affectedRows > 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
