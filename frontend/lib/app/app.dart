import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/team.dart';
import '../pages/auth_page.dart';
import '../pages/home_page.dart';
import '../pages/member_page.dart';
import '../pages/members_page.dart';
import '../pages/team_page.dart';
import 'app_state.dart';

class Cs2PlayersApp extends StatefulWidget {
  const Cs2PlayersApp({super.key});

  @override
  State<Cs2PlayersApp> createState() => _Cs2PlayersAppState();
}

class _Cs2PlayersAppState extends State<Cs2PlayersApp> {
  final AppSession _session = AppSession();

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      session: _session,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CS2 Players Hub',
        theme: AppTheme.build(),
        initialRoute: '/auth',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/auth':
              return MaterialPageRoute<void>(builder: (_) => const AuthPage());
            case '/home':
              return MaterialPageRoute<void>(builder: (_) => const HomePage());
            case '/':
              return MaterialPageRoute<void>(builder: (_) => const AuthPage());
            case '/members':
              return MaterialPageRoute<void>(builder: (_) => const MembersPage());
            case '/team':
              final team = settings.arguments;
              if (team is Team) {
                return MaterialPageRoute<void>(builder: (_) => TeamPage(team: team));
              }
              return _invalidRoute();
            case '/member':
              final args = settings.arguments;
              if (args is MemberPageArgs) {
                return MaterialPageRoute<void>(builder: (_) => MemberPage(args: args));
              }
              return _invalidRoute();
            default:
              return _invalidRoute();
          }
        },
      ),
    );
  }

  MaterialPageRoute<void> _invalidRoute() {
    return MaterialPageRoute<void>(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('Rota inválida.'),
        ),
      ),
    );
  }
}
