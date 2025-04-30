import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/presentation/screens/auth/login_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/register_screen.dart';
import 'package:constat_tunisie/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/create_report_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/report_details_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/report_list_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/join_report_screen.dart';
import 'package:constat_tunisie/presentation/screens/profile/profile_screen.dart';
import 'package:constat_tunisie/presentation/screens/settings/settings_screen.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Constat Tunisie',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          logger.d('Navigation vers: ${settings.name}');
          
          // Extraire les arguments si présents
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => RegisterScreen());
            case '/dashboard':
              return MaterialPageRoute(builder: (_) => DashboardScreen());
            case '/report/create':
              final invitationCode = args['invitationCode'] as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => CreateReportScreen(invitationCode: invitationCode),
              );
            case '/report/details':
              final reportId = args['reportId'] as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => ReportDetailsScreen(reportId: reportId),
              );
            case '/report/list':
              return MaterialPageRoute(builder: (_) => ReportListScreen());
            case '/report/join':
              return MaterialPageRoute(builder: (_) => JoinReportScreen());
            case '/profile':
              return MaterialPageRoute(builder: (_) => ProfileScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => SettingsScreen());
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(child: Text('Route non trouvée: ${settings.name}')),
                ),
              );
          }
        },
      ),
    );
  }
}
