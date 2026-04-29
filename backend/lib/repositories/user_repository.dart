import 'package:backend/models/app_user.dart';
import 'package:postgres/postgres.dart';

class UserRepository {
  const UserRepository(this._pool);

  final Pool _pool;

  Future<AppUser?> findByEmail(String email) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT id, name, email, password_hash, created_at
        FROM users
        WHERE email = @email
        LIMIT 1
      '''),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;
    return AppUser.fromDb(result.first.toColumnMap());
  }

  Future<AppUser?> findById(int id) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT id, name, email, password_hash, created_at
        FROM users
        WHERE id = @id
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return AppUser.fromDb(result.first.toColumnMap());
  }

  Future<AppUser> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO users (name, email, password_hash)
        VALUES (@name, @email, @password_hash)
        RETURNING id, name, email, password_hash, created_at
      '''),
      parameters: {'name': name, 'email': email, 'password_hash': passwordHash},
    );

    return AppUser.fromDb(result.first.toColumnMap());
  }
}
