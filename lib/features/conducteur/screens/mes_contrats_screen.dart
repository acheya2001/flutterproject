import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/post_contract_service.dart';

/// 📋 Écran des contrats du conducteur
class MesContratsScreen extends StatefulWidget {
  const MesContratsScreen({Key? key}) : super(key: key);

  @override
  State<MesContratsScreen> createState() => _MesContratsScreenState();
}

class _MesContratsScreenState extends State<MesContratsScreen> {
  List<Map<String, dynamic>> _contrats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContrats();
  }

  /// 📋 Charger les contrats du conducteur
  Future<void> _loadContrats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final contratsQuery = await FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      final contrats = <Map<String, dynamic>>[];
      
      for (final doc in contratsQuery.docs) {
        final contractData = doc.data();
        contractData['id'] = doc.id;
        
        // Récupérer les données complètes (carte verte, échéancier)
        final summary = await PostContractService.getConducteurContractSummary(doc.id);
        contractData['carteVerte'] = summary['carteVerte'];
        contractData['echeancier'] = summary['echeancier'];
        
        contrats.add(contractData);
      }

      setState(() {
        _contrats = contrats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement contrats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Contrats d\'Assurance'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contrats.isEmpty
              ? _buildEmptyState()
              : _buildContratsList(),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat d\'assurance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos contrats d\'assurance apparaîtront ici',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des contrats
  Widget _buildContratsList() {
    return RefreshIndicator(
      onRefresh: _loadContrats,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contrats.length,
        itemBuilder: (context, index) {
          final contrat = _contrats[index];
          return _buildContratCard(contrat);
        },
      ),
    );
  }

  /// 📄 Carte de contrat
  Widget _buildContratCard(Map<String, dynamic> contrat) {
    final dateDebut = (contrat['dateDebut'] as Timestamp?)?.toDate();
    final dateFin = (contrat['dateFin'] as Timestamp?)?.toDate();
    final isActive = dateFin?.isAfter(DateTime.now()) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du contrat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade600 : Colors.grey.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.verified : Icons.history,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contrat['numeroContrat'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isActive ? 'Contrat Actif' : 'Contrat Expiré',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contrat['typeContrat'] ?? 'RC',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu du contrat
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Informations véhicule
                _buildInfoRow(
                  'Véhicule',
                  '${contrat['vehiculeInfo']?['marque'] ?? 'N/A'} ${contrat['vehiculeInfo']?['modele'] ?? 'N/A'}',
                  Icons.directions_car,
                ),
                _buildInfoRow(
                  'Immatriculation',
                  contrat['vehiculeInfo']?['numeroImmatriculation'] ?? 'N/A',
                  Icons.confirmation_number,
                ),
                _buildInfoRow(
                  'Période',
                  '${_formatDate(dateDebut)} - ${_formatDate(dateFin)}',
                  Icons.calendar_today,
                ),
                _buildInfoRow(
                  'Prime annuelle',
                  '${contrat['montantPrime'] ?? 0} DT',
                  Icons.payments,
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showContractDetails(contrat),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (contrat['carteVerte'] != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCarteVerte(contrat['carteVerte']),
                          icon: const Icon(Icons.credit_card, size: 16),
                          label: const Text('Carte Verte'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// 👁️ Afficher les détails du contrat
  void _showContractDetails(Map<String, dynamic> contrat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contrat ${contrat['numeroContrat']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${contrat['typeContrat']}'),
              Text('Assuré: ${contrat['nomAssure']} ${contrat['prenomAssure']}'),
              Text('Prime: ${contrat['montantPrime']} DT'),
              // Ajouter plus de détails selon les besoins
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 🛡️ Afficher la carte verte
  void _showCarteVerte(Map<String, dynamic> carteVerte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛡️ Carte Verte d\'Assurance'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Police: ${carteVerte['numeroPolice']}'),
              Text('Compagnie: ${carteVerte['compagnieAssurance']}'),
              Text('Véhicule: ${carteVerte['vehicule']?['marque']} ${carteVerte['vehicule']?['modele']}'),
              Text('Immatriculation: ${carteVerte['vehicule']?['immatriculation']}'),
              // Ajouter plus de détails de la carte verte
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter le téléchargement PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📄 Téléchargement PDF à implémenter')),
              );
            },
            child: const Text('Télécharger PDF'),
          ),
        ],
      ),
    );
  }
}
