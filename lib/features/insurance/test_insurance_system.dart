import 'package:flutter/material.dart';
import 'models/insurance_contract.dart';
import 'models/simple_vehicle_model.dart';
import 'services/contract_service.dart';
import 'services/notification_service.dart';
import 'utils/insurance_utils.dart';

/// 🧪 Test du système d'assurance
class TestInsuranceSystem extends StatefulWidget {
  const TestInsuranceSystem({Key? key}) : super(key: key);

  @override
  State<TestInsuranceSystem> createState() => _TestInsuranceSystemState();
}

class _TestInsuranceSystemState extends State<TestInsuranceSystem> {
  bool _isLoading = false;
  String _testResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Système d\'Assurance'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Tests du Système d\'Assurance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Boutons de test
            _buildTestButton(
              'Test Création Contrat',
              Icons.add_circle,
              Colors.green,
              _testCreateContract,
            ),
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Test Notification',
              Icons.notifications,
              Colors.blue,
              _testNotification,
            ),
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Test Utilitaires',
              Icons.build,
              Colors.orange,
              _testUtils,
            ),
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Test Recherche Conducteur',
              Icons.search,
              Colors.purple,
              _testSearchDriver,
            ),
            
            const SizedBox(height: 20),
            
            // Résultats des tests
            if (_testResult.isNotEmpty) ...[
              const Text(
                '📋 Résultats des Tests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _testResult,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, size: 20),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// 🧪 Test de création de contrat
  Future<void> _testCreateContract() async {
    setState(() {
      _isLoading = true;
      _testResult = '🧪 Test de création de contrat...\n';
    });

    try {
      // Créer un véhicule de test
      final vehicule = SimpleVehicleModel(
        id: 'test-vehicle',
        marque: 'Peugeot',
        modele: '208',
        annee: 2020,
        numeroImmatriculation: '123 TUN 456',
        numeroSerie: 'VF3XXXXXXXX123456',
        puissance: '90 CV',
        energie: 'Essence',
        couleur: 'Blanc',
        usage: 'Personnel',
        proprietaireId: 'test-user',
        createdAt: DateTime.now(),
      );

      // Créer un contrat de test
      final contract = InsuranceContract(
        id: 'test-contract',
        numeroContrat: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        compagnieAssurance: 'STAR',
        agence: 'Tunis Centre',
        gouvernorat: 'Tunis',
        nomAssure: 'Test',
        prenomAssure: 'User',
        cinAssure: '12345678',
        telephoneAssure: '+216 20 123 456',
        adresseAssure: 'Tunis, Tunisie',
        vehicule: vehicule,
        dateDebut: DateTime.now(),
        dateFin: DateTime.now().add(const Duration(days: 365)),
        isActive: true,
        agentId: 'test-agent',
        createdAt: DateTime.now(),
      );

      setState(() {
        _testResult += '✅ Contrat créé avec succès\n';
        _testResult += 'Numéro: ${contract.numeroContrat}\n';
        _testResult += 'Véhicule: ${contract.vehicule.marque} ${contract.vehicule.modele}\n';
        _testResult += 'Immatriculation: ${contract.vehicule.immatriculation}\n';
        _testResult += 'Valide: ${contract.isValid ? "Oui" : "Non"}\n';
        _testResult += 'Jours restants: ${contract.joursRestants}\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Erreur: $e\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🧪 Test de notification
  Future<void> _testNotification() async {
    setState(() {
      _isLoading = true;
      _testResult = '🧪 Test de notification...\n';
    });

    try {
      // Initialiser les notifications
      await InsuranceNotificationService.initializeLocalNotifications();
      
      setState(() {
        _testResult += '✅ Service de notification initialisé\n';
      });

      // Afficher une notification locale de test
      await InsuranceNotificationService.showLocalNotification(
        title: '🧪 Test Notification',
        body: 'Ceci est un test du système de notification',
        data: {'type': 'test', 'timestamp': DateTime.now().toString()},
      );

      setState(() {
        _testResult += '✅ Notification locale envoyée\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Erreur: $e\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🧪 Test des utilitaires
  void _testUtils() {
    setState(() {
      _testResult = '🧪 Test des utilitaires...\n';
    });

    try {
      // Test formatage montant
      final amount = InsuranceUtils.formatAmount(1234.56);
      setState(() {
        _testResult += '✅ Format montant: $amount\n';
      });

      // Test formatage date
      final date = InsuranceUtils.formatDate(DateTime.now());
      setState(() {
        _testResult += '✅ Format date: $date\n';
      });

      // Test calcul jours restants
      final futureDate = DateTime.now().add(const Duration(days: 45));
      final daysRemaining = InsuranceUtils.daysRemaining(futureDate);
      setState(() {
        _testResult += '✅ Jours restants: $daysRemaining\n';
      });

      // Test expiration bientôt
      final expiringSoon = InsuranceUtils.isExpiringSoon(futureDate);
      setState(() {
        _testResult += '✅ Expire bientôt: ${expiringSoon ? "Oui" : "Non"}\n';
      });

      // Test couleurs de statut
      final statusColor = InsuranceUtils.getStatusColor(true, false);
      final statusText = InsuranceUtils.getStatusText(true, false);
      setState(() {
        _testResult += '✅ Statut: $statusText (couleur: ${statusColor.toString()})\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Erreur: $e\n';
      });
    }
  }

  /// 🧪 Test de recherche de conducteur
  Future<void> _testSearchDriver() async {
    setState(() {
      _isLoading = true;
      _testResult = '🧪 Test de recherche de conducteur...\n';
    });

    try {
      // Test avec un email fictif
      const testEmail = 'test@example.com';
      
      setState(() {
        _testResult += 'Recherche de: $testEmail\n';
      });

      final driver = await ContractService.searchConducteurByEmail(testEmail);
      
      if (driver != null) {
        setState(() {
          _testResult += '✅ Conducteur trouvé:\n';
          _testResult += 'Email: ${driver['email']}\n';
          _testResult += 'Nom: ${driver['nom'] ?? "N/A"}\n';
          _testResult += 'Téléphone: ${driver['telephone'] ?? "N/A"}\n';
        });
      } else {
        setState(() {
          _testResult += '⚠️ Aucun conducteur trouvé avec cet email\n';
          _testResult += 'Ceci est normal si l\'email n\'existe pas dans la base\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResult += '❌ Erreur: $e\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
