class Team {
  const Team({
    required this.id,
    required this.name,
    required this.tag,
    required this.region,
    required this.ranking,
    this.logoUrl,
  });

  final int id;
  final String name;
  final String tag;
  final String region;
  final int ranking;
  final String? logoUrl;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: _intFrom(json['id']),
      name: (json['name'] ?? '').toString(),
      tag: (json['tag'] ?? '').toString(),
      region: (json['region'] ?? 'Global').toString(),
      ranking: _intFrom(json['ranking']),
      logoUrl: json['logo_url']?.toString(),
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
    };
  }

  static int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
