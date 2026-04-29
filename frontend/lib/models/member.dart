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

  factory Member.fromJson(Map<String, dynamic> json) {
    final socials = json['socials'];
    final socialMap = socials is Map ? socials.cast<String, dynamic>() : null;

    return Member(
      id: _intFrom(json['id']),
      teamId: _intFrom(json['team_id']),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      age: _intFrom(json['age']),
      role: (json['role'] ?? '').toString(),
      imageUrl: _stringOrNull(json['image_url']),
      inGameRole: _stringOrNull(json['in_game_role']),
      dpi: _intOrNull(json['dpi']),
      sensitivity: _doubleOrNull(json['sensitivity']),
      resolution: _stringOrNull(json['resolution']),
      viewmodel: _stringOrNull(json['viewmodel']),
      crosshair: (json['crosshair'] ?? '').toString(),
      twitter: _stringOrNull(socialMap?['twitter'] ?? json['twitter']),
      instagram: _stringOrNull(socialMap?['instagram'] ?? json['instagram']),
      twitch: _stringOrNull(socialMap?['twitch'] ?? json['twitch']),
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
      'socials': {'twitter': twitter, 'instagram': instagram, 'twitch': twitch},
    };
  }

  static int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
