import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../screens/insurance_dashboard.dart'; // Supprimé
import '../../vehicles/screens/my_vehicles_screen.dart';
import '../../../utils/user_type.dart';

/// 🧭 Widget de navigation pour les fonctionnalités d'assurance
class InsuranceNavigation {
  
  /// 🏠 Naviguer vers le tableau de bord assurance (pour les agents)
  static void navigateToInsuranceDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Dashboard Assurance')),
          body: const Center(
            child: Text('🚧 Dashboard assurance à implémenter'),
          ),
        ),
      ),
    );
  }

  /// 🚗 Naviguer vers "Mes Véhicules" (pour les conducteurs)
  static void navigateToMyVehicles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyVehiclesScreen(),
      ),
    );
  }

  /// 🔍 Vérifier le rôle de l'utilisateur et naviguer vers l'interface appropriée
  static Future<void> navigateBasedOnRole(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez vous connecter'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Récupérer le rôle depuis Firestore en utilisant le système existant
      final userTypeDoc = await FirebaseFirestore.instance
          .collection('user_types')
          .doc(user.uid)
          .get();

      if (!userTypeDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Type d\'utilisateur non trouvé. Veuillez contacter l\'administrateur.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userTypeString = userTypeDoc.data()?['type'] as String? ?? 'conducteur';
      final userType = UserType.values.firstWhere(
        (type) => type.toString().split('.').last == userTypeString,
        orElse: () => UserType.conducteur,
      );

      // Navigation selon le rôle
      if (!context.mounted) return;

      switch (userType) {
        case UserType.assureur:
          navigateToInsuranceDashboard(context);
          break;
        case UserType.conducteur:
          navigateToMyVehicles(context);
          break;
        case UserType.expert:
          // Les experts peuvent aussi accéder au système d'assurance
          navigateToInsuranceDashboard(context);
          break;
        case UserType.admin:
          // Les admins ont accès au tableau de bord
          navigateToInsuranceDashboard(context);
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🎯 Widget bouton d'accès rapide pour l'assurance
  static Widget buildInsuranceAccessButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => navigateBasedOnRole(context),
        icon: const Icon(Icons.security, size: 24),
        label: const Text(
          'Gestion Assurance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 📱 Widget carte d'accès pour le menu principal
  static Widget buildInsuranceCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => navigateBasedOnRole(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assurance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gérer vos contrats\net véhicules',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔔 Widget de notification pour nouveaux contrats
  static Widget buildNotificationBadge(BuildContext context, int count) {
    if (count == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

}
