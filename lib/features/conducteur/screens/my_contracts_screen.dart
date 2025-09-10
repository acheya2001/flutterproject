import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/contract_documents_widget.dart';

/// 📋 Écran des contrats du conducteur
class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({Key? key}) : super(key: key);

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _conducteurId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadConducteurInfo();
    });
  }

  Future<void> _loadConducteurInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _conducteurId = currentUser.uid;
      }
    } catch (e) {
      print('❌ Erreur chargement conducteur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Mes Contrats d\'Assurance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _conducteurId == null
              ? _buildErrorState()
              : _buildContractsList(),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de connexion',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger vos contrats',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des contrats
  Widget _buildContractsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('contrats')
          .where('conducteurId', isEqualTo: _conducteurId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage('Erreur lors du chargement des contrats');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final contracts = snapshot.data?.docs ?? [];

        if (contracts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final contractData = contract.data() as Map<String, dynamic>;
            contractData['id'] = contract.id;

            return _buildContractCard(contractData);
          },
        );
      },
    );
  }

  /// 📄 Carte de contrat
  Widget _buildContractCard(Map<String, dynamic> contractData) {
    final statut = contractData['statut'] ?? '';
    final isActive = statut.toLowerCase() == 'actif';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [Colors.green.shade50, Colors.blue.shade50]
              : [Colors.grey.shade100, Colors.grey.shade200],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du contrat
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contrat N° ${contractData['numeroContrat'] ?? ''}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contractData['vehiculeInfo']?['immatriculation'] ?? 'Véhicule',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? '✅ Actif' : '⏸️ ${statut}',
                        style: TextStyle(
                          color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informations du véhicule
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${contractData['vehiculeInfo']?['marque'] ?? ''} ${contractData['vehiculeInfo']?['modele'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Type d'assurance
                Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      contractData['typeContratDisplay'] ?? contractData['typeContrat'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Validité
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Valide jusqu\'au ${_formatDate(contractData['dateFin'])}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Documents (seulement pour les contrats actifs)
          if (isActive)
            ContractDocumentsWidget(
              contractId: contractData['id'],
              contractData: contractData,
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
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat trouvé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos contrats d\'assurance apparaîtront ici',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Assurer un véhicule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ Message d'erreur
  Widget _buildErrorMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isLoading = true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return date.toString();
    }
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}

