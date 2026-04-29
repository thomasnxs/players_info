import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../models/team.dart';
import '../services/api_client.dart';
import '../services/service_factory.dart';
import '../widgets/page_frame.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String? _error;
  List<Team> _teams = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeams());
  }

  @override
  Widget build(BuildContext context) {
    final session = AppStateScope.of(context);

    if (!session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
      });
    }

    return PageFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 760
                  ? 2
                  : 1;

          return RefreshIndicator(
            onRefresh: _loadTeams,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              children: [
                _Header(onLogout: _logout),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _ErrorState(
                    message: _error!,
                    onRetry: _loadTeams,
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _teams.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      return _TeamCard(
                        team: team,
                        index: index,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/team',
                          arguments: team,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadTeams() async {
    final session = AppStateScope.of(context);
    final teamService = buildTeamService(session);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teams = await teamService.listTeams();
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
        _error = 'Nao foi possivel carregar os times.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final session = AppStateScope.of(context);
    await session.clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final session = AppStateScope.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Times de CS2', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Bem-vindo, ${session.user?.name ?? 'jogador'}'),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/members'),
              child: const Text('Listagem global'),
            ),
            ElevatedButton(
              onPressed: onLogout,
              child: const Text('Sair'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.index,
    required this.onTap,
  });

  final Team team;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.tag, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(team.name),
                const Spacer(),
                Row(
                  children: [
                    _Pill(label: team.region),
                    const SizedBox(width: 8),
                    _Pill(label: '#${team.ranking}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFB923C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x66FB923C)),
      ),
      child: Text(label),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Erro ao carregar times'),
            const SizedBox(height: 6),
            Text(message),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
