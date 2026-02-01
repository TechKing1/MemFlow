import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/case_model.dart';
import 'repositories/case_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/new_dashboard_screen.dart';
import 'screens/help/help_screen.dart';
import 'screens/operations/operations_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/upload/upload_case_screen.dart';
import 'theme/app_theme.dart';
import 'utils/page_transitions.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [Provider(create: (_) => CaseRepository())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemForensics',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        // Use custom page transitions for all routes
        Widget page;

        switch (settings.name) {
          case '/login':
            page = const LoginScreen();
            return FadePageRoute(page: page);
          case '/dashboard':
            page = const NewDashboardScreen();
            return FadePageRoute(page: page);
          case '/upload':
            page = const UploadCaseScreen();
            return FadePageRoute(page: page);
          case '/reports':
            page = const ReportsScreen();
            return FadePageRoute(page: page);
          case '/settings':
            page = const SettingsScreen();
            return FadePageRoute(page: page);
          case '/help':
            page = const HelpScreen();
            return FadePageRoute(page: page);
          case '/operations':
            final args = settings.arguments as String?;
            if (args == null) {
              page = const Scaffold(
                backgroundColor: Color(0xFF0A0E1A),
                body: Center(
                  child: Text(
                    'Error: No case ID provided',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            } else {
              page = OperationsScreen(caseId: args);
            }
            return FadePageRoute(page: page);
          default:
            page = const Scaffold(
              backgroundColor: Color(0xFF0A0E1A),
              body: Center(
                child: Text(
                  'Page not found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
            return FadePageRoute(page: page);
        }
      },
    );
  }
}
