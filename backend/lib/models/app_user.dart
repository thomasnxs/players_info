class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.nickname,
    this.imageUrl,
    this.dpi,
    this.sensitivity,
    this.resolution,
    this.viewmodel,
    this.crosshair,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String passwordHash;
  final String? nickname;
  final String? imageUrl;
  final int? dpi;
  final double? sensitivity;
  final String? resolution;
  final String? viewmodel;
  final String? crosshair;
  final DateTime createdAt;

  factory AppUser.fromDb(Map<String, dynamic> map) {
    return AppUser(
      id: _toInt(map['id']),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      passwordHash: (map['password_hash'] ?? '').toString(),
      nickname: _nullableText(map['nickname']),
      imageUrl: _nullableText(map['image_url']),
      dpi: _toNullableInt(map['dpi']),
      sensitivity: _toNullableDouble(map['sensitivity']),
      resolution: _nullableText(map['resolution']),
      viewmodel: _nullableText(map['viewmodel']),
      crosshair: _nullableText(map['crosshair']),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toPublicJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nickname': nickname,
      'image_url': imageUrl,
      'dpi': dpi,
      'sensitivity': sensitivity,
      'resolution': resolution,
      'viewmodel': viewmodel,
      'crosshair': crosshair,
      'created_at': createdAt.toIso8601String(),
    };
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

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }
}
