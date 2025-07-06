import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_router.dart';
import 'features/admin/services/simple_super_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[CONSTAT_APP] Firebase initialized successfully');

    // Créer le Super Admin simplifié
    await SimpleSuperAdmin.createSuperAdmin();
    debugPrint('[CONSTAT_APP] Super Admin initialisé');
  } catch (e) {
    debugPrint('[CONSTAT_APP] Firebase initialization failed: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Constat Tunisie',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.splash,
      debugShowCheckedModeBanner: false,
    );
  }
}
