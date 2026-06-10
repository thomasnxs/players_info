class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.nickname,
    this.imageUrl,
    this.dpi,
    this.sensitivity,
    this.resolution,
    this.viewmodel,
    this.crosshair,
  });

  final int id;
  final String name;
  final String email;
  final String? nickname;
  final String? imageUrl;
  final int? dpi;
  final double? sensitivity;
  final String? resolution;
  final String? viewmodel;
  final String? crosshair;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _intFrom(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nickname: _stringOrNull(json['nickname']),
      imageUrl: _stringOrNull(json['image_url']),
      dpi: _intOrNull(json['dpi']),
      sensitivity: _doubleOrNull(json['sensitivity']),
      resolution: _stringOrNull(json['resolution']),
      viewmodel: _stringOrNull(json['viewmodel']),
      crosshair: _stringOrNull(json['crosshair']),
    );
  }

  Map<String, dynamic> toJson() {
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
    };
  }

  static int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
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

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }
}
