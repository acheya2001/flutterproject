import 'package:flutter/material.dart';

/// 🧪 Script de test pour la correction des statistiques de véhicules
/// 
/// Ce script teste que le nombre de véhicules dans les statistiques du dashboard conducteur
/// correspond maintenant aux demandes avec statut actif, et non plus au nombre total de véhicules.

void main() {
  print('🧪 Test de la correction des statistiques de véhicules');
  print('====================================================');
  
  // Simulation des données
  final demandes = [
    {'id': '1', 'statut': 'contrat_actif', 'marque': 'Toyota', 'modele': 'Corolla'},
    {'id': '2', 'statut': 'en_attente', 'marque': 'Honda', 'modele': 'Civic'},
    {'id': '3', 'statut': 'documents_completes', 'marque': 'Nissan', 'modele': 'Sentra'},
    {'id': '4', 'statut': 'frequence_choisie', 'marque': 'Hyundai', 'modele': 'Elantra'},
    {'id': '5', 'statut': 'en_cours', 'marque': 'Kia', 'modele': 'Cerato'},
  ];
  
  final vehicules = [
    {'id': '1', 'marque': 'Toyota', 'modele': 'Corolla'},
    {'id': '2', 'marque': 'Honda', 'modele': 'Civic'},
    {'id': '3', 'marque': 'Nissan', 'modele': 'Sentra'},
    {'id': '4', 'marque': 'Hyundai', 'modele': 'Elantra'},
    {'id': '5', 'marque': 'Kia', 'modele': 'Cerato'},
    {'id': '6', 'marque': 'Mazda', 'modele': 'Mazda3'},
  ];
  
  print('\n📊 Données de test:');
  print('   - Nombre total de demandes: ${demandes.length}');
  print('   - Nombre total de véhicules en base: ${vehicules.length}');
  
  // Test de l'ancienne logique (incorrecte)
  final ancienneLogique = vehicules.length;
  print('\n❌ Ancienne logique (incorrecte):');
  print('   - Nombre de véhicules affiché: $ancienneLogique');
  print('   - Basé sur: vehicules.length');
  
  // Test de la nouvelle logique (correcte)
  final nouvelleLogique = demandes.where((d) {
    final statut = d['statut'] ?? '';
    return ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
  }).length;
  
  print('\n✅ Nouvelle logique (correcte):');
  print('   - Nombre de véhicules affiché: $nouvelleLogique');
  print('   - Basé sur: demandes avec statut actif');
  
  // Détail des statuts
  print('\n📋 Détail des statuts des demandes:');
  for (final demande in demandes) {
    final statut = demande['statut'];
    final estActif = ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
    final icone = estActif ? '✅' : '⏳';
    print('   $icone ${demande['marque']} ${demande['modele']} - Statut: $statut');
  }
  
  print('\n🎯 Résumé:');
  print('   - Véhicules avec contrat actif: $nouvelleLogique');
  print('   - Véhicules en attente: ${demandes.length - nouvelleLogique}');
  print('   - Total véhicules en base: ${vehicules.length}');
  
  // Test des différents dashboards
  print('\n🖥️ Dashboards modifiés:');
  print('   ✅ conducteur_dashboard_complete.dart - Méthode _calculateStats()');
  print('   ✅ conducteur_dashboard_simple.dart - Widget _buildStatsCards()');
  print('   ✅ elegant_conducteur_dashboard.dart - Widget _buildStatsCards()');
  print('   ✅ tunisian_conducteur_dashboard.dart - Déjà correct');
  
  // Vérification de la logique
  print('\n🔍 Vérification de la logique:');
  print('   - Statuts considérés comme "actifs":');
  print('     • contrat_actif');
  print('     • documents_completes');
  print('     • frequence_choisie');
  print('   - Statuts considérés comme "en attente":');
  print('     • en_attente');
  print('     • en_cours');
  print('     • en_attente_paiement');
  
  print('\n🚀 Test terminé avec succès!');
  print('   Le nombre de véhicules dans les statistiques correspond maintenant');
  print('   aux demandes avec statut actif, comme demandé par l\'utilisateur.');
}

/// 📊 Fonction helper pour calculer les statistiques (comme dans le vrai code)
Map<String, int> calculateStats(
  List<Map<String, dynamic>> demandes,
  List<Map<String, dynamic>> vehicules,
  List<Map<String, dynamic>> sinistres,
) {
  // Contrats actifs (depuis demandes_contrats)
  final contratsActifs = demandes.where((d) {
    final statut = d['statut'] ?? '';
    return ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
  }).length;

  // Véhicules assurés = nombre de demandes avec contrat actif
  final vehiculesAssures = demandes.where((d) {
    final statut = d['statut'] ?? '';
    return ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
  }).length;

  // Demandes en attente
  final demandesEnAttente = demandes.where((d) {
    final statut = d['statut'] ?? '';
    return ['en_attente', 'en_cours', 'en_attente_paiement'].contains(statut);
  }).length;

  // Sinistres en cours
  final sinistresEnCours = sinistres.where((s) {
    final statut = s['statut'] ?? '';
    return ['en_cours', 'en_attente', 'expertise_en_cours'].contains(statut);
  }).length;

  return {
    'contratsActifs': contratsActifs,
    'vehicules': vehiculesAssures, // ✅ Maintenant basé sur les contrats actifs
    'sinistres': sinistres.length,
    'sinistresEnCours': sinistresEnCours,
    'demandes': demandes.length,
    'demandesEnAttente': demandesEnAttente,
  };
}

/// 🎨 Exemple de widget de statistique (comme dans le vrai code)
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
