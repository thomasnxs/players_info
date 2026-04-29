import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../models/member.dart';
import '../services/api_client.dart';
import '../services/service_factory.dart';
import '../widgets/page_frame.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<Member> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Listagem global de integrantes'),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadMembers,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text('${member.nickname} (${member.role})'),
            subtitle: Text('Team ID: ${member.teamId}  |  Idade: ${member.age}'),
            trailing: const Icon(Icons.person_outline),
          ),
        );
      },
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
      final members = await teamService.listAllMembers();
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
        _error = 'Erro ao carregar integrantes.';
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
