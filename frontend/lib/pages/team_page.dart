import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/app_state.dart';
import '../models/member.dart';
import '../models/team.dart';
import '../pages/member_page.dart';
import '../services/api_client.dart';
import '../services/service_factory.dart';
import '../widgets/player_showcase_card.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  bool _loading = true;
  String? _error;
  List<Member> _members = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                      return;
                    }

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    'Voltar',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _TeamError(message: _error!, onRetry: _loadMembers)
                    : _RosterSection(team: widget.team, members: _members),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMembers() async {
    final session = AppStateScope.of(context);
    final teamService = buildTeamService(session);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final members = await teamService.listTeamMembers(widget.team.id);
      if (!mounted) return;
      setState(() {
        _members = members;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel carregar o roster.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _RosterSection extends StatelessWidget {
  const _RosterSection({required this.team, required this.members});

  final Team team;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final players = members
        .where((member) => member.role == 'player')
        .toList(growable: false);
    final coach = members.where((member) => member.role == 'coach').firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomHeight = constraints.maxHeight < 620 ? 116.0 : 148.0;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: players
                    .map(
                      (player) => Expanded(
                        child: PlayerShowcaseCard(
                          player: player,
                          enableHoverZoom: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/member',
                            arguments: MemberPageArgs(
                              team: team,
                              member: player,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: bottomHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _TeamIdentity(team: team)),
                  const SizedBox(width: 14),
                  SizedBox(width: 160, child: _CoachCard(coach: coach)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeamIdentity extends StatelessWidget {
  const _TeamIdentity({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(left: 52),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66FFFFFF),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  _assetForTeam(team),
                  width: 92,
                  height: 92,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 92, height: 92),
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                team.name,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach});

  final Member? coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17191E),
        border: Border.all(color: const Color(0xFF262A33)),
      ),
      alignment: Alignment.bottomLeft,
      child: Text(
        coach == null ? 'coach' : 'coach\n${coach!.nickname}',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
    );
  }
}

String _assetForTeam(Team team) {
  final normalizedTag = team.tag.toLowerCase().trim();
  if (normalizedTag == 'vit') return 'logos_times/vitality.png';
  if (normalizedTag == 'navi') return 'logos_times/natus_vincere.png';
  if (normalizedTag == 'furia') return 'logos_times/furia.png';
  if (normalizedTag == 'spirit') return 'logos_times/team_spirit.png';
  if (normalizedTag == 'falcons') return 'logos_times/falcons.png';

  final normalizedName = team.name.toLowerCase().trim();
  if (normalizedName.contains('vitality')) return 'logos_times/vitality.png';
  if (normalizedName.contains('natus') || normalizedName.contains('navi')) {
    return 'logos_times/natus_vincere.png';
  }
  if (normalizedName.contains('furia')) return 'logos_times/furia.png';
  if (normalizedName.contains('spirit')) return 'logos_times/team_spirit.png';
  if (normalizedName.contains('falcons')) return 'logos_times/falcons.png';

  return 'logos_times/placeholder_white.png';
}

class _TeamError extends StatelessWidget {
  const _TeamError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Erro ao carregar integrantes'),
            const SizedBox(height: 6),
            Text(message),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onRetry, child: const Text('Recarregar')),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final element in this) {
      return element;
    }
    return null;
  }
}
