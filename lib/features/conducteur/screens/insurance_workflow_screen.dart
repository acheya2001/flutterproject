import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/insurance/models/insurance_structure_model.dart';
import '../../../features/insurance/models/digital_contract_model.dart';
// import '../../../common/widgets/custom_app_bar.dart';
import 'add_vehicle_for_insurance_screen.dart';
import 'contract_review_screen.dart';

/// 🔄 Écran principal du workflow d'assurance pour le conducteur
class InsuranceWorkflowScreen extends StatefulWidget {
  const InsuranceWorkflowScreen({Key? key}) : super(key: key);

  @override
  State<InsuranceWorkflowScreen> createState() => _InsuranceWorkflowScreenState();
}

class _InsuranceWorkflowScreenState extends State<InsuranceWorkflowScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assurance'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Assurance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkflowExplanation(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildPendingVehicles(user.uid),
            const SizedBox(height: 20),
            _buildActiveContracts(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowExplanation() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Comment ça marche ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWorkflowStep(
              '1',
              'Soumettez votre véhicule',
              'Remplissez le formulaire avec les détails de votre véhicule',
              Icons.directions_car,
              Colors.blue,
            ),
            _buildWorkflowStep(
              '2',
              'Validation par l\'agence',
              'L\'admin agence examine et valide votre demande',
              Icons.verified_user,
              Colors.orange,
            ),
            _buildWorkflowStep(
              '3',
              'Création du contrat',
              'Un agent crée votre contrat personnalisé',
              Icons.description,
              Colors.purple,
            ),
            _buildWorkflowStep(
              '4',
              'Signature et paiement',
              'Vous examinez, signez et payez votre contrat',
              Icons.payment,
              Colors.green,
            ),
            _buildWorkflowStep(
              '5',
              'Documents numériques',
              'Recevez carte verte, quittance et certificat',
              Icons.verified,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStep(String number, String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Nouvelle Demande',
                'Ajouter un véhicule',
                Icons.add_circle,
                Colors.blue,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddVehicleForInsuranceScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Mes Contrats',
                'Voir les propositions',
                Icons.description,
                Colors.green,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ContractReviewScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVehicles(String conducteurId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚗 Mes Demandes en Cours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('vehicules_en_attente')
              .where('conducteurId', isEqualTo: conducteurId)
              .where('status', whereIn: [
                VehicleStatus.enAttenteValidation.value,
                VehicleStatus.valide.value,
                VehicleStatus.contratEnCours.value,
                VehicleStatus.contratPropose.value,
              ])
              .orderBy('submittedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles = snapshot.data?.docs ?? [];

            if (vehicles.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune demande en cours',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: vehicles.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = VehicleStatus.values.firstWhere(
                  (s) => s.value == data['status'],
                  orElse: () => VehicleStatus.enAttenteValidation,
                );
                
                return _buildVehicleStatusCard(data, status);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVehicleStatusCard(Map<String, dynamic> data, VehicleStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status.icon,
                color: status.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['marque']} ${data['modele']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data['numeroImmatriculation'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.displayName,
                style: TextStyle(
                  color: status.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContracts(String conducteurId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Mes Contrats Actifs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('contrats_numeriques')
              .where('conducteurId', isEqualTo: conducteurId)
              .where('statut', isEqualTo: ContractStatus.actif.value)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final contracts = snapshot.data?.docs ?? [];

            if (contracts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun contrat actif',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: contracts.map((doc) {
                final contract = DigitalContract.fromFirestore(doc);
                return _buildActiveContractCard(contract);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveContractCard(DigitalContract contract) {
    final daysUntilExpiry = contract.dateFin.difference(DateTime.now()).inDays;
    final isNearExpiry = daysUntilExpiry <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isNearExpiry ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isNearExpiry ? Icons.warning : Icons.verified,
                color: isNearExpiry ? Colors.orange : Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contract.typeContrat.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'N° ${contract.numeroContrat}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (isNearExpiry)
                    Text(
                      'Expire dans $daysUntilExpiry jours',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${contract.primeAnnuelle.toStringAsFixed(0)} DT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
