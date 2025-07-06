import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicule_assure_model.dart';
import '../services/vehicule_assure_service.dart';
import '../services/test_vehicules_service.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/contract_verification_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constats/screens/accident_declaration_screen.dart';

/// 🚗 Écran de sélection de véhicule pour déclaration d'accident
class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final VehiculeAssureService _vehiculeService = VehiculeAssureService();
  final TestVehiculesService _testService = TestVehiculesService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur: Utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🚗 Sélectionnez votre véhicule'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête informatif
          _buildHeader(),
          
          // Liste des véhicules
          Expanded(
            child: StreamBuilder<List<VehiculeAssureModel>>(
              stream: _vehiculeService.getVehiculesAssures(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final vehicules = snapshot.data ?? [];

                if (vehicules.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildVehiclesList(vehicules);
              },
            ),
          ),
          
          // Bouton d'ajout de véhicule
          _buildAddVehicleButton(),
        ],
      ),
    );
  }

  /// 📋 En-tête avec informations
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérification Automatique',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Votre contrat d\'assurance sera vérifié automatiquement',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🎯 Sélectionnez le véhicule impliqué dans l\'accident. Nous vérifierons automatiquement que votre contrat d\'assurance est valide.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des véhicules
  Widget _buildVehiclesList(List<VehiculeAssureModel> vehicules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicules.length,
      itemBuilder: (context, index) {
        final vehicule = vehicules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VehicleCard(
            vehicule: vehicule,
            onTap: () => _selectVehicle(vehicule),
            isLoading: _isLoading,
          ),
        );
      },
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun véhicule assuré',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous n\'avez aucun véhicule enregistré avec un contrat d\'assurance valide.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createTestVehicles,
              icon: const Icon(Icons.science),
              label: const Text('🧪 Créer des véhicules de test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showAddVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un véhicule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ➕ Bouton d'ajout de véhicule
  Widget _buildAddVehicleButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _showAddVehicleDialog,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Ajouter un autre véhicule'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.purple,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.purple[200]!),
          ),
        ),
      ),
    );
  }

  /// 🚗 Sélectionner un véhicule
  void _selectVehicle(VehiculeAssureModel vehicule) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier que le contrat est toujours valide
      if (!vehicule.isContratActif) {
        _showContractExpiredDialog(vehicule);
        return;
      }

      // Naviguer vers la déclaration d'accident
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AccidentDeclarationScreen(
              selectedVehicle: vehicule,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ⚠️ Dialog contrat expiré
  void _showContractExpiredDialog(VehiculeAssureModel vehicule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Contrat Expiré'),
          ],
        ),
        content: Text(
          'Le contrat d\'assurance pour ${vehicule.vehicule.marque} ${vehicule.vehicule.modele} '
          '(${vehicule.vehicule.immatriculation}) a expiré le ${_formatDate(vehicule.contrat.dateFin)}.\n\n'
          'Veuillez renouveler votre contrat avant de déclarer un accident.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Naviguer vers renouvellement contrat
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Renouveler'),
          ),
        ],
      ),
    );
  }

  /// 🧪 Créer des véhicules de test
  void _createTestVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _testService.createTestVehicles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Véhicules de test créés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Rafraîchir la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ➕ Dialog ajout véhicule
  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => const ContractVerificationDialog(),
    ).then((result) {
      if (result == true) {
        // Rafraîchir la liste
        setState(() {});
      }
    });
  }

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}
