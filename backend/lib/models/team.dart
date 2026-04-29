class Team {
  const Team({
    required this.id,
    required this.name,
    required this.tag,
    required this.region,
    required this.ranking,
    this.logoUrl,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String tag;
  final String region;
  final int ranking;
  final String? logoUrl;
  final DateTime createdAt;

  factory Team.fromDb(Map<String, dynamic> map) {
    return Team(
      id: _toInt(map['id']),
      name: (map['name'] ?? '').toString(),
      tag: (map['tag'] ?? '').toString(),
      region: (map['region'] ?? '').toString(),
      ranking: _toInt(map['ranking']),
      logoUrl: _nullableText(map['logo_url']),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'region': region,
      'ranking': ranking,
      'logo_url': logoUrl,
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

  static String? _nullableText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }
}
