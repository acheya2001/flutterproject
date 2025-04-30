import 'package:flutter/material.dart';
import 'package:constat_tunisie/presentation/screens/profile/profile_screen.dart';
import 'package:constat_tunisie/presentation/screens/settings/settings_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/report_list_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/join_report_screen.dart';
// Ajout de l'import manquant
import 'package:constat_tunisie/presentation/screens/report/report_details_screen.dart';
import 'package:logger/logger.dart';

class AppRoutes {
  static final Logger _logger = Logger();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    _logger.d('Navigation vers: ${settings.name}');
    
    // Extraire les arguments si présents
    final args = settings.arguments as Map<String, dynamic>? ?? {};
    
    switch (settings.name) {
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case '/report/list':
        return MaterialPageRoute(builder: (_) => ReportListScreen());
      case '/report/join':
        return MaterialPageRoute(builder: (_) => JoinReportScreen());
      case '/report/details':
        final reportId = args['reportId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ReportDetailsScreen(reportId: reportId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route non trouvée: ${settings.name}')),
          ),
        );
    }
  }
}
