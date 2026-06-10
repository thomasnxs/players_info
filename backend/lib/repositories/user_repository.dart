import 'package:backend/models/app_user.dart';
import 'package:postgres/postgres.dart';

class UserRepository {
  const UserRepository(this._pool);

  final Pool _pool;

  Future<AppUser?> findByEmail(String email) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT id, name, email, password_hash, nickname, image_url, dpi, sensitivity, resolution, viewmodel, crosshair, created_at
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
        SELECT id, name, email, password_hash, nickname, image_url, dpi, sensitivity, resolution, viewmodel, crosshair, created_at
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
    String? nickname,
    String? imageUrl,
    int? dpi,
    double? sensitivity,
    String? resolution,
    String? viewmodel,
    String? crosshair,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO users (name, email, password_hash, nickname, image_url, dpi, sensitivity, resolution, viewmodel, crosshair)
        VALUES (@name, @email, @password_hash, @nickname, @image_url, @dpi, @sensitivity, @resolution, @viewmodel, @crosshair)
        RETURNING id, name, email, password_hash, nickname, image_url, dpi, sensitivity, resolution, viewmodel, crosshair, created_at
      '''),
      parameters: {
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'nickname': nickname,
        'image_url': imageUrl,
        'dpi': dpi,
        'sensitivity': sensitivity,
        'resolution': resolution,
        'viewmodel': viewmodel,
        'crosshair': crosshair,
      },
    );

    return AppUser.fromDb(result.first.toColumnMap());
  }

  Future<AppUser?> updateProfile({
    required int id,
    required String name,
    String? nickname,
    String? imageUrl,
    int? dpi,
    double? sensitivity,
    String? resolution,
    String? viewmodel,
    String? crosshair,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE users
        SET name = @name,
            nickname = @nickname,
            image_url = @image_url,
            dpi = @dpi,
            sensitivity = @sensitivity,
            resolution = @resolution,
            viewmodel = @viewmodel,
            crosshair = @crosshair
        WHERE id = @id
        RETURNING id, name, email, password_hash, nickname, image_url, dpi, sensitivity, resolution, viewmodel, crosshair, created_at
      '''),
      parameters: {
        'id': id,
        'name': name,
        'nickname': nickname,
        'image_url': imageUrl,
        'dpi': dpi,
        'sensitivity': sensitivity,
        'resolution': resolution,
        'viewmodel': viewmodel,
        'crosshair': crosshair,
      },
    );

    if (result.isEmpty) return null;
    return AppUser.fromDb(result.first.toColumnMap());
  }

  Future<bool> deleteById(int id) async {
    final result = await _pool.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
