import 'package:postgres/postgres.dart';

class Database {
  Database._(this.pool);

  final Pool pool;

  static Future<Database> connect(String databaseUrl) async {
    final pool = Pool.withUrl(databaseUrl);
    return Database._(pool);
  }

  Future<void> bootstrap() async {
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id BIGSERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await pool.execute('''
      CREATE TABLE IF NOT EXISTS teams (
        id BIGSERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        tag TEXT NOT NULL UNIQUE,
        region TEXT NOT NULL,
        ranking INTEGER NOT NULL CHECK (ranking > 0),
        logo_url TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await pool.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id BIGSERIAL PRIMARY KEY,
        team_id BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
        full_name TEXT NOT NULL,
        nickname TEXT NOT NULL,
        age INTEGER NOT NULL CHECK (age > 0),
        role TEXT NOT NULL CHECK (role IN ('player', 'coach')),
        image_url TEXT,
        in_game_role TEXT,
        dpi INTEGER,
        sensitivity DOUBLE PRECISION,
        resolution TEXT,
        viewmodel TEXT,
        crosshair TEXT NOT NULL DEFAULT '',
        twitter TEXT,
        instagram TEXT,
        twitch TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (team_id, nickname)
      );
    ''');
    await pool.execute(
      'ALTER TABLE members ADD COLUMN IF NOT EXISTS image_url TEXT;',
    );
    await pool.execute(
      'ALTER TABLE members ADD COLUMN IF NOT EXISTS in_game_role TEXT;',
    );
    await pool.execute(
      'ALTER TABLE members ADD COLUMN IF NOT EXISTS dpi INTEGER;',
    );
    await pool.execute(
      'ALTER TABLE members ADD COLUMN IF NOT EXISTS sensitivity DOUBLE PRECISION;',
    );
    await pool.execute(
      'ALTER TABLE members ADD COLUMN IF NOT EXISTS resolution TEXT;',
    );
    await pool.execute(
      'ALTER TABLE members ADD COLUMN IF NOT EXISTS viewmodel TEXT;',
    );

    await _seedTeamsAndMembers();
    await _syncTeamLogos();
    await _syncMemberProfiles();
  }

  Future<void> close() async {
    await pool.close();
  }

  Future<void> _seedTeamsAndMembers() async {
    final countResult = await pool.execute(
      'SELECT COUNT(*) AS count FROM teams',
    );
    final count = _toInt(countResult.first.toColumnMap()['count']);
    if (count > 0) return;

    await pool.runTx((session) async {
      final teamIdByName = <String, int>{};

      for (final team in _seedTeams) {
        final inserted = await session.execute(
          Sql.named('''
            INSERT INTO teams (name, tag, region, ranking, logo_url)
            VALUES (@name, @tag, @region, @ranking, @logo_url)
            RETURNING id
          '''),
          parameters: {
            'name': team.name,
            'tag': team.tag,
            'region': team.region,
            'ranking': team.ranking,
            'logo_url': team.logoUrl,
          },
        );

        final row = inserted.first.toColumnMap();
        teamIdByName[team.name] = _toInt(row['id']);
      }

      for (final member in _seedMembers) {
        final teamId = teamIdByName[member.teamName];
        if (teamId == null) continue;

        await session.execute(
          Sql.named('''
            INSERT INTO members (team_id, full_name, nickname, age, role, image_url, in_game_role, dpi, sensitivity, resolution, viewmodel, crosshair)
            VALUES (@team_id, @full_name, @nickname, @age, @role, @image_url, @in_game_role, @dpi, @sensitivity, @resolution, @viewmodel, @crosshair)
          '''),
          parameters: {
            'team_id': teamId,
            'full_name': member.fullName,
            'nickname': member.nickname,
            'age': member.age,
            'role': member.role,
            'image_url': member.imageUrl,
            'in_game_role': member.inGameRole,
            'dpi': member.dpi,
            'sensitivity': member.sensitivity,
            'resolution': member.resolution,
            'viewmodel': member.viewmodel,
            'crosshair': member.crosshair,
          },
        );
      }
    });
  }

  Future<void> _syncTeamLogos() async {
    for (final team in _seedTeams) {
      await pool.execute(
        Sql.named('''
          UPDATE teams
          SET logo_url = @logo_url
          WHERE name = @name
        '''),
        parameters: {'name': team.name, 'logo_url': team.logoUrl},
      );
    }
  }

  Future<void> _syncMemberProfiles() async {
    for (final member in _seedMembers) {
      await pool.execute(
        Sql.named('''
          UPDATE members m
          SET full_name = @full_name,
              age = @age,
              image_url = @image_url,
              in_game_role = @in_game_role,
              dpi = @dpi,
              sensitivity = @sensitivity,
              resolution = @resolution,
              viewmodel = @viewmodel,
              crosshair = @crosshair
          FROM teams t
          WHERE m.team_id = t.id
            AND t.name = @team_name
            AND m.nickname = @nickname
        '''),
        parameters: {
          'team_name': member.teamName,
          'nickname': member.nickname,
          'full_name': member.fullName,
          'age': member.age,
          'image_url': member.imageUrl,
          'in_game_role': member.inGameRole,
          'dpi': member.dpi,
          'sensitivity': member.sensitivity,
          'resolution': member.resolution,
          'viewmodel': member.viewmodel,
          'crosshair': member.crosshair,
        },
      );
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class _SeedTeam {
  const _SeedTeam({
    required this.name,
    required this.tag,
    required this.region,
    required this.ranking,
    required this.logoUrl,
  });

  final String name;
  final String tag;
  final String region;
  final int ranking;
  final String logoUrl;
}

class _SeedMember {
  const _SeedMember({
    required this.teamName,
    required this.nickname,
    required this.role,
    required this.fullName,
    required this.age,
    this.imageUrl,
    this.inGameRole,
    this.dpi,
    this.sensitivity,
    this.resolution,
    this.viewmodel,
    required this.crosshair,
  });

  final String teamName;
  final String nickname;
  final String role;
  final String fullName;
  final int age;
  final String? imageUrl;
  final String? inGameRole;
  final int? dpi;
  final double? sensitivity;
  final String? resolution;
  final String? viewmodel;
  final String crosshair;
}

const _seedTeams = [
  _SeedTeam(
    name: 'Vitality',
    tag: 'VIT',
    region: 'EU',
    ranking: 1,
    logoUrl:
        'https://img-cdn.hltv.org/teamlogo/yeXBldn9w8LZCgdElAenPs.png?ixlib=java-2.1.0&w=50&s=15eaba0b75250065d20162d2cb05e3e6',
  ),
  _SeedTeam(
    name: 'Natus Vincere',
    tag: 'NAVI',
    region: 'EU',
    ranking: 2,
    logoUrl:
        'https://img-cdn.hltv.org/teamlogo/9iMirAi7ArBLNU8p3kqUTZ.svg?ixlib=java-2.1.0&s=4dd8635be16122656093ae9884675d0c',
  ),
  _SeedTeam(
    name: 'FURIA',
    tag: 'FURIA',
    region: 'BR',
    ranking: 3,
    logoUrl:
        'https://img-cdn.hltv.org/teamlogo/mvNQc4csFGtxXk5guAh8m1.svg?ixlib=java-2.1.0&s=11e5056829ad5d6c06c5961bbe76d20c',
  ),
  _SeedTeam(
    name: 'Spirit',
    tag: 'SPIRIT',
    region: 'CIS',
    ranking: 4,
    logoUrl:
        'https://img-cdn.hltv.org/teamlogo/ywdn4tmAvXfllLeV2SkkvF.png?ixlib=java-2.1.0&w=50&s=9c70c7fbb048348f70f686acd2369c58',
  ),
  _SeedTeam(
    name: 'Falcons',
    tag: 'FALCONS',
    region: 'MENA',
    ranking: 5,
    logoUrl:
        'https://img-cdn.hltv.org/teamlogo/4eJSkDQINNM6Tbs4WvLzkN.png?ixlib=java-2.1.0&w=50&s=d8c857ea47046f61eca695beab0d12ef',
  ),
];

const _seedMembers = [
  _SeedMember(
    teamName: 'Vitality',
    nickname: 'apEX',
    role: 'player',
    fullName: 'Dan Madesclaire',
    age: 33,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/3M9h08qvl3YOsaRcAvKhs4.png?ixlib=java-2.1.0&w=400&s=c1acc9777d9e3165140548582e9bf1f5',
    inGameRole: 'IGL',
    dpi: 400,
    sensitivity: 1.91,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 60; viewmodel_offset_x 2; viewmodel_offset_y 2; viewmodel_offset_z -2; viewmodel_presetpos 1',
    crosshair: 'CSGO-766L7-m9SjA-SycWv-766Wv-4fWjM',
  ),
  _SeedMember(
    teamName: 'Vitality',
    nickname: 'ropz',
    role: 'player',
    fullName: 'Robin Kool',
    age: 26,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/YQ9kQQ3aop1JZQE9xJ140r.png?ixlib=java-2.1.0&w=400&s=d4c7a00036511e25b4854ba3d3af80ca',
    dpi: 400,
    sensitivity: 1.77,
    resolution: '1920x1080 (16:9 Native)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-MMQuh-Hs3Sj-Qv9zd-VaCmc-3QqNO',
  ),
  _SeedMember(
    teamName: 'Vitality',
    nickname: 'ZywOo',
    role: 'player',
    fullName: 'Mathieu Herbaut',
    age: 25,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/blnoWFtH8GUJZjhr8H0P4u.png?ixlib=java-2.1.0&w=400&s=dc0fe6bd817ef852f59185ccf6b6c868',
    dpi: 400,
    sensitivity: 2.0,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-4ENaA-AH2oJ-np6BN-EODuy-5RGOP',
  ),
  _SeedMember(
    teamName: 'Vitality',
    nickname: 'flameZ',
    role: 'player',
    fullName: 'Shahar Shushan',
    age: 22,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/LUQi5dX9boyO0uDadUGht5.png?ixlib=java-2.1.0&w=400&s=1c5c46fe41e79b19a69b479d8abbbb41',
    dpi: 400,
    sensitivity: 3.0,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-fH7Xz-V6k4v-mNpxk-jG2Xv-4fWjM',
  ),
  _SeedMember(
    teamName: 'Vitality',
    nickname: 'mezii',
    role: 'player',
    fullName: 'William Merriman',
    age: 27,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/7GVUrVLAQkgnuovRkk5Bxw.png?ixlib=java-2.1.0&w=400&s=00b346853396c35e5889b00be2766c99',
    dpi: 400,
    sensitivity: 2.2,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 3; viewmodel_offset_y 3; viewmodel_offset_z -3; viewmodel_presetpos 0',
    crosshair: 'CSGO-Jp66H-896vS-S6666-66666-4fWjM',
  ),
  _SeedMember(
    teamName: 'Vitality',
    nickname: 'XTQZZZ',
    role: 'coach',
    fullName: 'XTQZZZ',
    age: 20,
    crosshair: '',
  ),
  _SeedMember(
    teamName: 'Natus Vincere',
    nickname: 'Aleksib',
    role: 'player',
    fullName: 'Aleksi Virolainen',
    age: 29,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/7-TvianW79yWk13gdw-Jc5.png?ixlib=java-2.1.0&w=400&s=f94eda5a77f332bc02821e6b845ca207',
    inGameRole: 'IGL',
    dpi: 800,
    sensitivity: 1.05,
    resolution: '1440x1080 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-zYpW9-N5K5S-mNpxk-jG2Xv-4fWjM',
  ),
  _SeedMember(
    teamName: 'Natus Vincere',
    nickname: 'iM',
    role: 'player',
    fullName: 'Mihai Ivan',
    age: 26,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/lWNcoOFOcHF3uIERANZRXh.png?ixlib=java-2.1.0&w=400&s=cd5df4d5e89df8cab0e4a7edd6db0d8b',
    dpi: 800,
    sensitivity: 1.2,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 60; viewmodel_offset_x 0; viewmodel_offset_y 0; viewmodel_offset_z -2; viewmodel_presetpos 1',
    crosshair: 'CSGO-6OToT-fH7Xz-V6k4v-mNpxk-4fWjM',
  ),
  _SeedMember(
    teamName: 'Natus Vincere',
    nickname: 'b1t',
    role: 'player',
    fullName: 'Valeriy Vakhovskiy',
    age: 23,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/9qh2YbZOLfeIAPCYfgxAd3.png?ixlib=java-2.1.0&w=400&s=cef57317978ef255ee2c48e322c25560',
    dpi: 400,
    sensitivity: 1.42,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-74q7o-bvpfG-mvA6s-6bAtd-OnMHA',
  ),
  _SeedMember(
    teamName: 'Natus Vincere',
    nickname: 'w0nderful',
    role: 'player',
    fullName: 'Ihor Zhdanov',
    age: 21,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/OepRRBoc68iVojIfgK3JIA.png?ixlib=java-2.1.0&w=400&s=99dcc1115ffec1ed275a5cf4eacca825',
    dpi: 400,
    sensitivity: 1.27,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-6zX79-TjJvS-P9zXv-766Wv-4fWjM',
  ),
  _SeedMember(
    teamName: 'Natus Vincere',
    nickname: 'makazze',
    role: 'player',
    fullName: 'Drin Shaqiri',
    age: 18,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/U6KmIKHcqg2OpMrNn-Aqk6.png?ixlib=java-2.1.0&w=400&s=420f1bcb0e6943b68fafb5e2d933197c',
    dpi: 800,
    sensitivity: 0.75,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-9vS66-mNpxk-jG2Xv-4fWjM-766Wv',
  ),
  _SeedMember(
    teamName: 'Natus Vincere',
    nickname: 'B1ad3',
    role: 'coach',
    fullName: 'B1ad3',
    age: 20,
    crosshair: '',
  ),
  _SeedMember(
    teamName: 'FURIA',
    nickname: 'FalleN',
    role: 'player',
    fullName: 'Gabriel Toledo',
    age: 34,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/gQbb4I0TeHmxx7bYBOtd7T.png?ixlib=java-2.1.0&w=400&s=744dd676bd5ad23e4adfc8dc8fcbaa80',
    dpi: 400,
    sensitivity: 1.4,
    resolution: '1440x1080 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-Dc8yR-4FLT7-uQi3c-4JyyR-FTsFF',
  ),
  _SeedMember(
    teamName: 'FURIA',
    nickname: 'yuurih',
    role: 'player',
    fullName: 'Yuri Boian',
    age: 26,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/ZapU9KMKIlH1bDpSlV6MO1.png?ixlib=java-2.1.0&w=400&s=09cb203041b92340db49939164bc6f99',
    dpi: 400,
    sensitivity: 1.25,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-6X6vS-P9zXv-766Wv-4fWjM-SycWv',
  ),
  _SeedMember(
    teamName: 'FURIA',
    nickname: 'YEKINDAR',
    role: 'player',
    fullName: 'Mareks Galinskis',
    age: 26,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/IO3vEa2fT2qFPRlrPid7hf.png?ixlib=java-2.1.0&w=400&s=2826592c7787a70711b1ca5651ab25a7',
    dpi: 800,
    sensitivity: 1.2,
    resolution: '1920x1080 (16:9 Native)',
    viewmodel:
        'viewmodel_fov 65; viewmodel_offset_x -0.5; viewmodel_offset_y 1; viewmodel_offset_z -2; viewmodel_presetpos 0',
    crosshair: 'CSGO-ySLmr-MRRob-xAdOd-Ekkkf-JkA6Q',
  ),
  _SeedMember(
    teamName: 'FURIA',
    nickname: 'KSCERATO',
    role: 'player',
    fullName: 'Kaike Cerato',
    age: 26,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/z0vT0V815B0MdeeKhcf44Y.png?ixlib=java-2.1.0&w=400&s=32afd770ba5023b0eefc0712e029065a',
    dpi: 800,
    sensitivity: 1.45,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-mR62V-fO6S2-m5fB6-N6U6z-4fWjM',
  ),
  _SeedMember(
    teamName: 'FURIA',
    nickname: 'molodoy',
    role: 'player',
    fullName: 'Danil Golubenko',
    age: 21,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/oPoWLYFq87cIs2cYDo8id7.png?ixlib=java-2.1.0&w=400&s=26d135bacbf9f98ff775421c3ca2bf4c',
    dpi: 400,
    sensitivity: 2.5,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-7sqFO-JJitc-mJxyL-arZc2-tDu8O',
  ),
  _SeedMember(
    teamName: 'FURIA',
    nickname: 'sidde',
    role: 'coach',
    fullName: 'sidde',
    age: 20,
    crosshair: '',
  ),
  _SeedMember(
    teamName: 'Spirit',
    nickname: 'sh1ro',
    role: 'player',
    fullName: 'Dmitry Sokolov',
    age: 24,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/Grz5vLIlrpeI7IQmm8d-jH.png?ixlib=java-2.1.0&w=400&s=3cfc5c3d0dbe422578931aabe14faa3c',
    dpi: 800,
    sensitivity: 1.03,
    resolution: '1280x960 (4:3 Black Bars)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-bk5KR-52jw7-tKRaw-7kzdw-hOxoO',
  ),
  _SeedMember(
    teamName: 'Spirit',
    nickname: 'magixx',
    role: 'player',
    fullName: 'Boris Vorobiev',
    age: 22,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/1V7ijAaTXl3umTr7cPo0VF.png?ixlib=java-2.1.0&w=400&s=fd243be6d54de849949d6a837c3abe5e',
    dpi: 400,
    sensitivity: 2.2,
    resolution: '1920x1080 (16:9 Native)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-fH7Xz-V6k4v-mNpxk-jG2Xv-4fWjM',
  ),
  _SeedMember(
    teamName: 'Spirit',
    nickname: 'tN1R',
    role: 'player',
    fullName: 'Andrey Tatarinovich',
    age: 25,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/PONEIASU8jyJz2lnNS13bp.png?ixlib=java-2.1.0&w=400&s=c995668c01532a97dc5709f25f479f8d',
    dpi: 800,
    sensitivity: 0.5,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 1',
    crosshair: 'CSGO-SycWv-766Wv-4fWjM-V6k4v-mNpxk',
  ),
  _SeedMember(
    teamName: 'Spirit',
    nickname: 'zont1x',
    role: 'player',
    fullName: 'Myroslav Plakhotia',
    age: 20,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/wi3shJIerTjUCELul_JOus.png?ixlib=java-2.1.0&w=400&s=ce5a7296c8ec30e2bae0592b3be12667',
    dpi: 800,
    sensitivity: 1.05,
    resolution: '1024x768 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-fyPd3-QhkaN-7BVjF-Ftqfj-E5hWA',
  ),
  _SeedMember(
    teamName: 'Spirit',
    nickname: 'donk',
    role: 'player',
    fullName: 'Danil Kryshkovets',
    age: 19,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/C4b0sMnty05S40UmXhLRD4.png?ixlib=java-2.1.0&w=400&s=8d846371bff4a867c0fcc3e038e02b1f',
    dpi: 800,
    sensitivity: 1.25,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-3a3HM-jCvMU-8xk4L-L9yMn-dAHnK',
  ),
  _SeedMember(
    teamName: 'Spirit',
    nickname: 'hally',
    role: 'coach',
    fullName: 'hally',
    age: 20,
    crosshair: '',
  ),
  _SeedMember(
    teamName: 'Falcons',
    nickname: 'karrigan',
    role: 'player',
    fullName: 'Finn Andersen',
    age: 36,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/5LUkKnJkRvzZRqDDnvldiC.png?ixlib=java-2.1.0&w=400&s=b0543e702a84517a48de00fc25e83f9d',
    inGameRole: 'IGL',
    dpi: 400,
    sensitivity: 1.4,
    resolution: '1600x1024 (16:10 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-z3333-33333-33333-33333-4fWjM',
  ),
  _SeedMember(
    teamName: 'Falcons',
    nickname: 'NiKo',
    role: 'player',
    fullName: 'Nikola Kovac',
    age: 29,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/ZrAcgiRTFgDyDj4k04-xAh.png?ixlib=java-2.1.0&w=400&s=afb5419d8de8399ef582f5446702a278',
    dpi: 1600,
    sensitivity: 0.42,
    resolution: '1280x800 (16:10 Stretched)',
    viewmodel:
        'viewmodel_fov 65; viewmodel_offset_x -0.5; viewmodel_offset_y 1; viewmodel_offset_z -2; viewmodel_presetpos 1',
    crosshair: 'CSGO-MDNOE-ZiGOk-ia7EX-evBaL-HOkTL',
  ),
  _SeedMember(
    teamName: 'Falcons',
    nickname: 'TeSeS',
    role: 'player',
    fullName: 'Rene Madsen',
    age: 24,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/M7vtVu2MP606MqUmkW7ha4.png?ixlib=java-2.1.0&w=400&s=a0e159d3ec0ec708bb1db0eefbddb40b',
    dpi: 400,
    sensitivity: 2.909,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-P9zXv-766Wv-4fWjM-SycWv-766L7',
  ),
  _SeedMember(
    teamName: 'Falcons',
    nickname: 'm0NESY',
    role: 'player',
    fullName: 'Ilya Osipov',
    age: 20,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/e20I1I0Ld0bWn_VI31pf08.png?ixlib=java-2.1.0&w=400&s=6f89be52bc56efdd00b207268a1f7cfe',
    dpi: 400,
    sensitivity: 2.3,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 3',
    crosshair: 'CSGO-ytP68-r4fM6-Kov7G-fR6Mv-4fWjM',
  ),
  _SeedMember(
    teamName: 'Falcons',
    nickname: 'kyousuke',
    role: 'player',
    fullName: 'Maksim Lukin',
    age: 18,
    imageUrl:
        'https://img-cdn.hltv.org/playerbodyshot/_s6UUQ4E92xw1uSWWCafsK.png?ixlib=java-2.1.0&w=400&s=d94a122aa9a8ec89f0727656b69e2415',
    dpi: 800,
    sensitivity: 1.28,
    resolution: '1280x960 (4:3 Stretched)',
    viewmodel:
        'viewmodel_fov 68; viewmodel_offset_x 2.5; viewmodel_offset_y 0; viewmodel_offset_z -1.5; viewmodel_presetpos 1',
    crosshair: 'CSGO-4ttyQ-vfwMK-Gz9fL-hY6zW-4fWjM',
  ),
  _SeedMember(
    teamName: 'Falcons',
    nickname: 'zonic',
    role: 'coach',
    fullName: 'zonic',
    age: 20,
    crosshair: '',
  ),
];
