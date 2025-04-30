import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/presentation/screens/auth/login_screen.dart';
import 'package:constat_tunisie/presentation/screens/auth/register_screen.dart';
import 'package:constat_tunisie/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:constat_tunisie/presentation/screens/report/create_report_screen.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Ajout du paramètre key
  const MyApp({Key? key}) : super(key: key);

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
        routes: {
          '/': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/report/create': (context) => CreateReportScreen(),
        },
        onUnknownRoute: (settings) {
          logger.d('Route inconnue: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Page temporaire')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Page en construction',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text('Route: ${settings.name}'),
                    SizedBox(height: 24),
                    ElevatedButton(
                      // Correction: Utiliser le contexte correct
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
