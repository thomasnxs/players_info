class Member {
  const Member({
    required this.id,
    required this.teamId,
    required this.fullName,
    required this.nickname,
    required this.age,
    required this.role,
    this.imageUrl,
    this.inGameRole,
    this.dpi,
    this.sensitivity,
    this.resolution,
    this.viewmodel,
    required this.crosshair,
    this.twitter,
    this.instagram,
    this.twitch,
    required this.createdAt,
  });

  final int id;
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
  final DateTime createdAt;

  factory Member.fromDb(Map<String, dynamic> map) {
    return Member(
      id: _toInt(map['id']),
      teamId: _toInt(map['team_id']),
      fullName: (map['full_name'] ?? '').toString(),
      nickname: (map['nickname'] ?? '').toString(),
      age: _toInt(map['age']),
      role: (map['role'] ?? '').toString(),
      imageUrl: _nullableText(map['image_url']),
      inGameRole: _nullableText(map['in_game_role']),
      dpi: _toNullableInt(map['dpi']),
      sensitivity: _toNullableDouble(map['sensitivity']),
      resolution: _nullableText(map['resolution']),
      viewmodel: _nullableText(map['viewmodel']),
      crosshair: (map['crosshair'] ?? '').toString(),
      twitter: _nullableText(map['twitter']),
      instagram: _nullableText(map['instagram']),
      twitch: _nullableText(map['twitch']),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'socials': {'twitter': twitter, 'instagram': instagram, 'twitch': twitch},
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
