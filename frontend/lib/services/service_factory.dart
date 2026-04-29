import '../app/app_state.dart';
import '../core/config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'team_service.dart';

ApiClient buildClient(AppSession session) {
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    authToken: session.token,
  );
}

AuthService buildAuthService(AppSession session) {
  return AuthService(buildClient(session));
}

TeamService buildTeamService(AppSession session) {
  return TeamService(buildClient(session));
}
