import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();

  // Vérifier si l'appareil est connecté à Internet
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de la connectivité: $e');
      return false;
    }
  }

  // Obtenir le type de connexion actuel
  Future<ConnectivityResult> getConnectionType() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      _logger.e('Erreur lors de la récupération du type de connexion: $e');
      return ConnectivityResult.none;
    }
  }

  // Stream pour suivre les changements de connectivité
  Stream<ConnectivityResult> get onConnectivityChanged => 
      _connectivity.onConnectivityChanged;

  // Vérifier si la connexion est mobile
  Future<bool> isMobileConnection() async {
    final result = await getConnectionType();
    return result == ConnectivityResult.mobile;
  }

  // Vérifier si la connexion est WiFi
  Future<bool> isWifiConnection() async {
    final result = await getConnectionType();
    return result == ConnectivityResult.wifi;
  }
}
