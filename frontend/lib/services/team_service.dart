import '../models/member.dart';
import '../models/team.dart';
import 'api_client.dart';

class TeamService {
  TeamService(this._api);

  final ApiClient _api;

  Future<List<Team>> listTeams() async {
    final payload = await _api.getList('/teams');
    return payload
        .whereType<Map<String, dynamic>>()
        .map(Team.fromJson)
        .toList(growable: false);
  }

  Future<List<Member>> listTeamMembers(int teamId) async {
    final payload = await _api.getList('/teams/$teamId/members');
    return payload
        .whereType<Map<String, dynamic>>()
        .map(Member.fromJson)
        .toList(growable: false);
  }

  Future<List<Member>> listAllMembers() async {
    final payload = await _api.getList('/members');
    return payload
        .whereType<Map<String, dynamic>>()
        .map(Member.fromJson)
        .toList(growable: false);
  }

  Future<Member> findMember(int memberId) async {
    final payload = await _api.getObject('/members/$memberId');
    return Member.fromJson(payload);
  }
}
