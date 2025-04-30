import 'package:firebase_core/firebase_core.dart';
import 'package:constat_tunisie/firebase_options.dart';
import 'package:logger/logger.dart';

class FirebaseService {
  static final Logger _logger = Logger();

  static Future<bool> initialize() async {
    try {
      _logger.i("Initialisation de Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logger.i("Firebase initialisé avec succès");
      return true;
    } catch (e) {
      _logger.e("Erreur d'initialisation Firebase: $e");
      return false;
    }
  }
}