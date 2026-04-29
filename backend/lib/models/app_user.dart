class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  factory AppUser.fromDb(Map<String, dynamic> map) {
    return AppUser(
      id: _toInt(map['id']),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      passwordHash: (map['password_hash'] ?? '').toString(),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toPublicJson() {
    return {'id': id, 'name': name, 'email': email};
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc() ??
        DateTime.now().toUtc();
  }
}
