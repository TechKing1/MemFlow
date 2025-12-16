import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/case_model.dart';
import 'repositories/case_repository.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/operations/operations_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CaseRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forensense',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/operations': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          if (args == null) {
            return const Scaffold(
              body: Center(child: Text('Error: No case ID provided')),
            );
          }
          return OperationsScreen(caseId: args);
        },
      },
      onGenerateRoute: (settings) {
        // Handle any undefined routes
        if (settings.name == '/operations' && settings.arguments is String) {
          return MaterialPageRoute(
            builder: (context) => OperationsScreen(
              caseId: settings.arguments as String,
            ),
          );
        }
        return null;
      },
    );
  }
}
