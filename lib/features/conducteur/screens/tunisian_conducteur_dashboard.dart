import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/tunisian_insurance_models.dart';
import '../../../services/tunisian_documents_service.dart';

/// 🚗 Dashboard conducteur tunisien
class TunisianConducteurDashboard extends StatefulWidget {
  final String conducteurId;

  const TunisianConducteurDashboard({
    Key? key,
    required this.conducteurId,
  }) : super(key: key);

  @override
  State<TunisianConducteurDashboard> createState() => _TunisianConducteurDashboardState();
}

class _TunisianConducteurDashboardState extends State<TunisianConducteurDashboard> {
  List<VehiculeAssure> _vehicules = [];
  List<ContratAssuranceTunisien> _contrats = [];
  Map<String, dynamic>? _conducteurInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadConducteurData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes Assurances',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_conducteurInfo != null)
            Text(
              '${_conducteurInfo!['prenom']} ${_conducteurInfo!['nom']}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => _scanQRCode(),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(),
        ),
      ],
    );
  }

  /// 📊 Contenu principal
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé rapide
          _buildQuickSummary(),
          const SizedBox(height: 20),
          
          // Mes véhicules
          _buildVehiclesSection(),
          const SizedBox(height: 20),
          
          // Contrats actifs
          _buildActiveContracts(),
          const SizedBox(height: 20),
          
          // Actions rapides
          _buildQuickActions(),
        ],
      ),
    );
  }

  /// 📈 Résumé rapide
  Widget _buildQuickSummary() {
    int vehiculesAssures = _contrats.where((c) => c.statut == 'actif').length;
    int contratsExpires = _contrats.where((c) => c.statut == 'expire').length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'État de vos Assurances',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Véhicules Assurés',
                  vehiculesAssures.toString(),
                  Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'À Renouveler',
                  contratsExpires.toString(),
                  Icons.refresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 🚗 Section véhicules
  Widget _buildVehiclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🚗 Mes Véhicules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addVehicle(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_vehicules.isEmpty)
          _buildEmptyVehicles()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vehicules.length,
            itemBuilder: (context, index) {
              final vehicule = _vehicules[index];
              final contrat = _getContratForVehicule(vehicule.id);
              return _buildVehicleCard(vehicule, contrat);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyVehicles() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined, 
               size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule enregistré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier véhicule pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un véhicule'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehiculeAssure vehicule, ContratAssuranceTunisien? contrat) {
    bool isAssured = contrat != null && contrat.statut == 'actif';
    Color statusColor = isAssured ? Colors.green : Colors.orange;
    String statusText = isAssured ? 'Assuré' : 'Non assuré';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_car, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicule.marque} ${vehicule.modele}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      vehicule.numeroImmatriculation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVehicleInfo('Année', vehicule.annee.toString()),
              _buildVehicleInfo('Couleur', vehicule.couleur),
              _buildVehicleInfo('Puissance', '${vehicule.puissanceFiscale} CV'),
            ],
          ),
          if (contrat != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contrat: ${contrat.numeroContrat}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Échéance: ${_formatDate(contrat.dateEcheance)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showContractDetails(contrat),
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: 'Détails du contrat',
                    ),
                    IconButton(
                      onPressed: () => _downloadDocuments(contrat),
                      icon: const Icon(Icons.download_outlined, size: 20),
                      tooltip: 'Télécharger documents',
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _requestInsurance(vehicule),
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Demander une assurance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  side: BorderSide(color: Colors.blue.shade600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Contrats actifs
  Widget _buildActiveContracts() {
    List<ContratAssuranceTunisien> contratsActifs = 
        _contrats.where((c) => c.statut == 'actif').toList();
    
    if (contratsActifs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Contrats Actifs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...contratsActifs.map((contrat) => _buildContractCard(contrat)),
      ],
    );
  }

  Widget _buildContractCard(ContratAssuranceTunisien contrat) {
    int joursRestants = contrat.dateEcheance.difference(DateTime.now()).inDays;
    Color urgenceColor = joursRestants <= 30 ? Colors.orange : Colors.green;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgenceColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contrat.numeroContrat,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$joursRestants jours',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: urgenceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prime: ${contrat.primeAnnuelle} TND/an',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Échéance: ${_formatDate(contrat.dateEcheance)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              'Déclarer Sinistre',
              Icons.warning_outlined,
              Colors.red,
              () => _declareAccident(),
            ),
            _buildQuickActionCard(
              'Mes Documents',
              Icons.folder_outlined,
              Colors.blue,
              () => _showDocuments(),
            ),
            _buildQuickActionCard(
              'Historique',
              Icons.history_outlined,
              Colors.purple,
              () => _showHistory(),
            ),
            _buildQuickActionCard(
              'Support',
              Icons.support_agent_outlined,
              Colors.green,
              () => _contactSupport(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 Méthodes utilitaires
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _addVehicle,
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  ContratAssuranceTunisien? _getContratForVehicule(String vehiculeId) {
    try {
      return _contrats.firstWhere(
        (contrat) => contrat.vehiculeId == vehiculeId && contrat.statut == 'actif',
      );
    } catch (e) {
      return null;
    }
  }

  /// 📊 Charger les données
  Future<void> _loadConducteurData() async {
    try {
      // TODO: Charger depuis Firestore
      await Future.wait([
        _loadConducteurInfo(),
        _loadVehicules(),
        _loadContrats(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement données conducteur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConducteurInfo() async {
    // TODO: Implémenter
  }

  Future<void> _loadVehicules() async {
    // TODO: Implémenter
  }

  Future<void> _loadContrats() async {
    // TODO: Implémenter
  }

  /// 🎯 Actions
  void _addVehicle() {
    // TODO: Naviguer vers l'ajout de véhicule
  }

  void _requestInsurance(VehiculeAssure vehicule) {
    // TODO: Demander une assurance pour ce véhicule
  }

  void _showContractDetails(ContratAssuranceTunisien contrat) {
    // TODO: Afficher les détails du contrat
  }

  void _downloadDocuments(ContratAssuranceTunisien contrat) async {
    // TODO: Télécharger les documents (police, quittance, macaron)
  }

  void _declareAccident() {
    // TODO: Déclarer un sinistre
  }

  void _showDocuments() {
    // TODO: Afficher tous les documents
  }

  void _showHistory() {
    // TODO: Afficher l'historique
  }

  void _contactSupport() {
    // TODO: Contacter le support
  }

  void _scanQRCode() {
    // TODO: Scanner un QR code pour vérifier un document
  }

  void _showNotifications() {
    // TODO: Afficher les notifications
  }
}

