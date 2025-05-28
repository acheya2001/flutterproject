import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityUtils {
  // Vérifier la connexion internet
  Future<bool> checkConnection() async {
    try {
      // Vérifier la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('[ConnectivityUtils] Pas de connexion réseau');
        return false;
      }

      // Vérifier l'accès à Internet
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('[ConnectivityUtils] Connexion internet disponible');
          return true;
        }
      } on SocketException catch (_) {
        debugPrint('[ConnectivityUtils] Pas d\'accès à Internet');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('[ConnectivityUtils] Erreur lors de la vérification de la connexion: $e');
      return false;
    }
  }

  // Vérifier la qualité de la connexion
  Future<ConnectionQuality> checkConnectionQuality() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      switch (connectivityResult) {
        case ConnectivityResult.mobile:
          return ConnectionQuality.mobile;
        case ConnectivityResult.wifi:
          return ConnectionQuality.wifi;
        case ConnectivityResult.ethernet:
          return ConnectionQuality.ethernet;
        case ConnectivityResult.vpn:
          return ConnectionQuality.vpn;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
          return ConnectionQuality.other;
        case ConnectivityResult.none:
        default:
          return ConnectionQuality.none;
      }
    } catch (e) {
      debugPrint('[ConnectivityUtils] Erreur lors de la vérification de la qualité de connexion: $e');
      return ConnectionQuality.unknown;
    }
  }

  // Surveiller les changements de connectivité
  Stream<ConnectivityResult> getConnectivityStream() {
    return Connectivity().onConnectivityChanged;
  }
}

// Énumération pour la qualité de connexion
enum ConnectionQuality {
  none,
  mobile,
  wifi,
  ethernet,
  vpn,
  other,
  unknown,
}
