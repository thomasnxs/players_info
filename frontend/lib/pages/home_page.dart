import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../models/team.dart';
import '../services/api_client.dart';
import '../services/service_factory.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  List<Team> _teams = const [];
  late final PageController _pageController;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.28);
    _pageController.addListener(() {
      if (!_pageController.hasClients) return;
      setState(() {
        _page = _pageController.page ?? 0;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeams());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Home'),
        actions: [
          TextButton(
            onPressed: () async {
              await session.clearAuth();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadTeams,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 340,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                final distance = (_page - index).abs().clamp(0, 1);
                final scale = 1 - (distance * 0.18);

                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: _TeamLogoItem(
                      team: team,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/team',
                        arguments: team,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _teams.length <= 1 ? null : _goPrevious,
                child: const Text('Anterior'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _teams.length <= 1 ? null : _goNext,
                child: const Text('Próximo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadTeams() async {
    final session = AppStateScope.of(context);
    final service = buildTeamService(session);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teams = await service.listTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar os times.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _goPrevious() async {
    if (!_pageController.hasClients || _teams.isEmpty) return;
    final current = _page.round().clamp(0, _teams.length - 1);
    final target = (current - 1).clamp(0, _teams.length - 1);
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goNext() async {
    if (!_pageController.hasClients || _teams.isEmpty) return;
    final current = _page.round().clamp(0, _teams.length - 1);
    final target = (current + 1).clamp(0, _teams.length - 1);
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }
}

class _TeamLogoItem extends StatelessWidget {
  const _TeamLogoItem({required this.team, required this.onTap});

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetForTeam(team);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 136,
                    height: 136,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66FFFFFF),
                          blurRadius: 44,
                          spreadRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 188,
                    height: 188,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) =>
                          _LogoFallback(label: 'erro: $assetPath'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              team.name,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported,
            size: 34,
            color: Colors.white70,
          ),
          if (label != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
