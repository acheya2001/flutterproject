import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../insurance/services/contract_service.dart';

/// 🚗 Écran "Mes Véhicules" pour les conducteurs
class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({Key? key}) : super(key: key);

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final String conducteurId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🚗 Mes Véhicules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ContractService.getConducteurVehicles(conducteurId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final vehicles = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(vehicles[index]);
            },
          );
        },
      ),
    );
  }

  /// 🚗 Carte de véhicule
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final assurance = vehicle['assurance'] as Map<String, dynamic>?;
    final isInsured = assurance != null && assurance['status'] == 'active';
    final isExpiringSoon = _isExpiringSoon(assurance);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(isInsured, isExpiringSoon).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(isInsured, isExpiringSoon).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: _getStatusColor(isInsured, isExpiringSoon),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['immatriculation'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vehicle['marque'] ?? ''} ${vehicle['modele'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isInsured, isExpiringSoon),
              ],
            ),
          ),
          
          // Détails du véhicule
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('🎨 Couleur', vehicle['couleur'] ?? 'Non spécifiée'),
                _buildDetailRow('📅 Année', vehicle['annee']?.toString() ?? 'N/A'),
                _buildDetailRow('⚡ Énergie', vehicle['energie'] ?? 'N/A'),
                _buildDetailRow('🔧 Puissance', '${vehicle['puissance'] ?? 'N/A'} CV'),
                
                if (isInsured) ...[
                  const SizedBox(height: 16),
                  _buildInsuranceSection(assurance!),
                ],
                
                const SizedBox(height: 16),
                _buildActionButtons(vehicle, isInsured),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🛡️ Section assurance
  Widget _buildInsuranceSection(Map<String, dynamic> assurance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Assurance Active',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('🏢 Compagnie', assurance['compagnie'] ?? 'N/A'),
          _buildDetailRow('📋 Contrat', assurance['numeroContrat'] ?? 'N/A'),
          _buildDetailRow('🏪 Agence', assurance['agence'] ?? 'N/A'),
          _buildDetailRow('👤 Agent', assurance['agent'] ?? 'N/A'),
          _buildDetailRow('📅 Expire le', _formatDate(assurance['dateFin'])),
          
          if (_isExpiringSoon(assurance))
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre assurance expire bientôt ! Contactez votre agent.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons(Map<String, dynamic> vehicle, bool isInsured) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewVehicleDetails(vehicle),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Voir les détails'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[600],
              side: BorderSide(color: Colors.blue[600]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (isInsured) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _contactAgent(vehicle),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Contacter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isInsured, bool isExpiringSoon) {
    Color color;
    String text;
    IconData icon;

    if (!isInsured) {
      color = Colors.red;
      text = 'Non assuré';
      icon = Icons.warning;
    } else if (isExpiringSoon) {
      color = Colors.orange;
      text = 'Expire bientôt';
      icon = Icons.schedule;
    } else {
      color = Colors.green;
      text = 'Assuré';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger vos véhicules',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Center(
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
          const SizedBox(height: 8),
          Text(
            'Vos véhicules assurés apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(height: 8),
                Text(
                  'Comment obtenir une assurance ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contactez un agent d\'assurance qui créera un contrat pour votre véhicule. Vous recevrez une notification une fois le contrat activé.',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔧 Méthodes utilitaires
  Color _getStatusColor(bool isInsured, bool isExpiringSoon) {
    if (!isInsured) return Colors.red;
    if (isExpiringSoon) return Colors.orange;
    return Colors.green;
  }

  bool _isExpiringSoon(Map<String, dynamic>? assurance) {
    if (assurance == null || assurance['dateFin'] == null) return false;

    try {
      final endDate = assurance['dateFin'].toDate() as DateTime;
      final now = DateTime.now();
      final daysRemaining = endDate.difference(now).inDays;
      return daysRemaining <= 30 && daysRemaining > 0;
    } catch (e) {
      return false;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final date = timestamp.toDate() as DateTime;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// 🎯 Actions
  void _viewVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${vehicle['immatriculation']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('🚗 Véhicule', [
                'Immatriculation: ${vehicle['immatriculation'] ?? 'N/A'}',
                'Marque: ${vehicle['marque'] ?? 'N/A'}',
                'Modèle: ${vehicle['modele'] ?? 'N/A'}',
                'Année: ${vehicle['annee']?.toString() ?? 'N/A'}',
                'Couleur: ${vehicle['couleur'] ?? 'N/A'}',
                'Énergie: ${vehicle['energie'] ?? 'N/A'}',
                'Puissance: ${vehicle['puissance']?.toString() ?? 'N/A'} CV',
                'Usage: ${vehicle['usage'] ?? 'N/A'}',
              ]),

              if (vehicle['assurance'] != null) ...[
                const SizedBox(height: 16),
                _buildInfoSection('🛡️ Assurance', [
                  'Compagnie: ${vehicle['assurance']['compagnie'] ?? 'N/A'}',
                  'Contrat: ${vehicle['assurance']['numeroContrat'] ?? 'N/A'}',
                  'Agence: ${vehicle['assurance']['agence'] ?? 'N/A'}',
                  'Agent: ${vehicle['assurance']['agent'] ?? 'N/A'}',
                  'Début: ${_formatDate(vehicle['assurance']['dateDebut'])}',
                  'Fin: ${_formatDate(vehicle['assurance']['dateFin'])}',
                  'Statut: ${vehicle['assurance']['status'] ?? 'N/A'}',
                ]),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '• $item',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }

  void _contactAgent(Map<String, dynamic> vehicle) {
    final assurance = vehicle['assurance'] as Map<String, dynamic>?;
    if (assurance == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter l\'agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent: ${assurance['agent'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Agence: ${assurance['agence'] ?? 'N/A'}'),
            Text('Compagnie: ${assurance['compagnie'] ?? 'N/A'}'),
            const SizedBox(height: 16),
            const Text(
              'Vous pouvez contacter votre agent pour:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Renouveler votre contrat'),
            const Text('• Modifier vos garanties'),
            const Text('• Déclarer un sinistre'),
            const Text('• Poser des questions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter l'appel ou l'envoi d'email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de contact à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Appeler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
