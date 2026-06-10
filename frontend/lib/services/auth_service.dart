import '../models/app_user.dart';
import 'api_client.dart';

class AuthResult {
  const AuthResult({
    required this.token,
    required this.user,
  });

  final String token;
  final AppUser user;
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final payload = await _api.postObject(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return _parseAuthResult(payload);
  }

  Future<AuthResult> register({
    String? name,
    required String email,
    required String password,
  }) async {
    final derivedName = (name == null || name.trim().isEmpty)
        ? email.split('@').first
        : name.trim();

    final payload = await _api.postObject(
      '/auth/register',
      body: {
        'name': derivedName,
        'email': email,
        'password': password,
      },
    );

    return _parseAuthResult(payload);
  }

  Future<AppUser> me() async {
    final payload = await _api.getObject('/auth/me');
    return AppUser.fromJson(payload);
  }

  Future<AppUser> updateMe({
    required String name,
    required String nickname,
    required String imageUrl,
    required int dpi,
    required double sensitivity,
    required String resolution,
    required String viewmodel,
    required String crosshair,
  }) async {
    final payload = await _api.putObject(
      '/auth/me',
      body: {
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
    return AppUser.fromJson(payload);
  }

  Future<void> deleteMe() async {
    await _api.delete('/auth/me');
  }

  AuthResult _parseAuthResult(Map<String, dynamic> payload) {
    final token = payload['token']?.toString() ?? '';
    final user = payload['user'];

    if (token.isEmpty || user is! Map<String, dynamic>) {
      throw ApiException(
        message: 'Resposta inválida no fluxo de autenticação.',
        statusCode: 500,
      );
    }

    return AuthResult(
      token: token,
      user: AppUser.fromJson(user),
    );
  }
}
