import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityUtils {
  // Vérifier la connexion Internet
  Future<bool> checkConnection() async {
    try {
      // Vérifier d'abord la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('[ConnectivityUtils] Pas de connectivité détectée');
        return false;
      }
      
      // Vérifier si nous pouvons réellement accéder à Internet
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('[ConnectivityUtils] Connexion Internet disponible');
          return true;
        }
      } catch (e) {
        debugPrint('[ConnectivityUtils] Pas d\'accès Internet: $e');
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('[ConnectivityUtils] Erreur lors de la vérification de la connexion: $e');
      return false;
    }
  }
  
  // Vérifier la connexion à un serveur spécifique
  Future<bool> checkServerConnection(String url) async {
    try {
      // Vérifier d'abord la connectivité de base
      final hasInternet = await checkConnection();
      if (!hasInternet) {
        return false;
      }
      
      // Essayer de se connecter au serveur spécifique
      final response = await HttpClient().getUrl(Uri.parse(url))
          .then((request) => request.close())
          .timeout(const Duration(seconds: 10));
      
      debugPrint('[ConnectivityUtils] Statut de connexion au serveur: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      debugPrint('[ConnectivityUtils] Erreur lors de la connexion au serveur: $e');
      return false;
    }
  }
  
  // Obtenir le type de connexion actuel
  Future<String> getConnectionType() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      switch (connectivityResult) {
        case ConnectivityResult.mobile:
          return 'Mobile';
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.none:
          return 'Aucune';
        default:
          return 'Inconnue';
      }
    } catch (e) {
      debugPrint('[ConnectivityUtils] Erreur lors de la détermination du type de connexion: $e');
      return 'Erreur';
    }
  }
  
  // Surveiller les changements de connectivité
  Stream<ConnectivityResult> getConnectivityStream() {
    return Connectivity().onConnectivityChanged;
  }
}