import 'package:backend/models/app_user.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthException implements Exception {
  AuthException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class AuthService {
  AuthService({
    required UserRepository userRepository,
    required String jwtSecret,
  }) : _users = userRepository,
       _jwtSecret = jwtSecret;

  final UserRepository _users;
  final String _jwtSecret;

  Future<AuthResult> register({
    String? name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    _validateCredentials(email: normalizedEmail, password: password);
    final derivedName = _deriveName(name, normalizedEmail);

    final existing = await _users.findByEmail(normalizedEmail);
    if (existing != null) {
      throw AuthException(message: 'E-mail ja cadastrado.', statusCode: 400);
    }

    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    final user = await _users.create(
      name: derivedName,
      email: normalizedEmail,
      passwordHash: passwordHash,
    );

    return AuthResult(token: _createToken(user), user: user);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw AuthException(
        message: 'E-mail e senha sao obrigatorios.',
        statusCode: 400,
      );
    }

    final user = await _users.findByEmail(normalizedEmail);
    if (user == null || !BCrypt.checkpw(password, user.passwordHash)) {
      throw AuthException(message: 'Credenciais invalidas.', statusCode: 401);
    }

    return AuthResult(token: _createToken(user), user: user);
  }

  Future<AppUser> me(String token) async {
    final userId = _verifyAndReadUserId(token);
    final user = await _users.findById(userId);
    if (user == null) {
      throw AuthException(message: 'Usuario nao encontrado.', statusCode: 404);
    }

    return user;
  }

  String _createToken(AppUser user) {
    final jwt = JWT(
      {'email': user.email},
      subject: user.id.toString(),
      issuer: 'players-info-backend',
    );

    return jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(days: 7));
  }

  int _verifyAndReadUserId(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final subject = jwt.subject;
      final id = int.tryParse(subject ?? '');
      if (id == null) {
        throw AuthException(message: 'Token invalido.', statusCode: 401);
      }
      return id;
    } on JWTExpiredException {
      throw AuthException(message: 'Token expirado.', statusCode: 401);
    } on JWTException {
      throw AuthException(message: 'Token invalido.', statusCode: 401);
    }
  }

  void _validateCredentials({required String email, required String password}) {
    if (!email.contains('@')) {
      throw AuthException(message: 'E-mail invalido.', statusCode: 400);
    }

    if (password.length < 6) {
      throw AuthException(
        message: 'Senha deve ter no minimo 6 caracteres.',
        statusCode: 400,
      );
    }

    if (password.length > 72) {
      throw AuthException(
        message: 'Senha deve ter no maximo 72 caracteres.',
        statusCode: 400,
      );
    }
  }

  String _deriveName(String? name, String email) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return email.split('@').first;
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();
}
