import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/app_state.dart';
import '../models/member.dart';
import '../models/team.dart';
import '../services/service_factory.dart';
import '../widgets/page_frame.dart';
import '../widgets/player_showcase_card.dart';

class MemberPageArgs {
  const MemberPageArgs({required this.team, required this.member});

  final Team team;
  final Member member;
}

class MemberPage extends StatefulWidget {
  const MemberPage({super.key, required this.args});

  final MemberPageArgs args;

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  late Member _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _member = widget.args.member;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLatestData());
  }

  @override
  Widget build(BuildContext context) {
    final infoCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _member.nickname,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              _member.fullName,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(label: 'Idade', value: '${_member.age}'),
                _InfoChip(
                  label: 'Funcao',
                  value: _member.inGameRole ?? _member.role,
                ),
                _InfoChip(
                  label: 'Time',
                  value: '${widget.args.team.name} (${widget.args.team.tag})',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final imageCard = SizedBox(
      height: 520,
      child: PlayerShowcaseCard(
        player: _member,
        baseImageScale: 1,
        imageYOffset: 0,
      ),
    );

    final configCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuracoes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  label: 'DPI',
                  value: _member.dpi?.toString() ?? '-',
                ),
                _InfoChip(
                  label: 'Sens',
                  value: _member.sensitivity?.toString() ?? '-',
                ),
                _InfoChip(
                  label: 'Res',
                  value: _member.resolution ?? 'Nao informado',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final crosshairCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crosshair',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SelectableText(
                _member.crosshair.isEmpty ? 'Nao informado' : _member.crosshair,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    final viewmodelCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viewmodel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SelectableText(
                (_member.viewmodel == null || _member.viewmodel!.isEmpty)
                    ? 'Nao informado'
                    : _member.viewmodel!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    return PageFrame(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${_member.nickname} - ${widget.args.team.tag}'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (!isWide) {
                return Column(
                  children: [
                    infoCard,
                    const SizedBox(height: 14),
                    imageCard,
                    const SizedBox(height: 14),
                    configCard,
                    const SizedBox(height: 14),
                    crosshairCard,
                    const SizedBox(height: 14),
                    viewmodelCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        infoCard,
                        const SizedBox(height: 14),
                        configCard,
                        const SizedBox(height: 14),
                        crosshairCard,
                        const SizedBox(height: 14),
                        viewmodelCard,
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: imageCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadLatestData() async {
    final session = AppStateScope.of(context);
    final service = buildTeamService(session);

    try {
      final updated = await service.findMember(_member.id);
      if (!mounted) return;
      setState(() {
        _member = updated;
      });
    } catch (_) {
      // Ignora: a tela já abre com os dados recebidos da listagem.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111317),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.montserrat(color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            TextSpan(text: value, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
