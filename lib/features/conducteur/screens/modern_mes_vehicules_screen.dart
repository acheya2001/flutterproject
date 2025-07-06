import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../insurance/services/contrat_vehicule_service.dart';
import '../../insurance/models/contrat_assurance_model.dart';

/// 🚗 Interface moderne pour afficher les véhicules du conducteur
class ModernMesVehiculesScreen extends StatefulWidget {
  const ModernMesVehiculesScreen({Key? key}) : super(key: key);

  @override
  State<ModernMesVehiculesScreen> createState() => _ModernMesVehiculesScreenState();
}

class _ModernMesVehiculesScreenState extends State<ModernMesVehiculesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, dynamic>> _vehiculesAvecContrats = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _chargerVehicules();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _chargerVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vehicules = await ContratVehiculeService.getVehiculesAvecContrats(user.uid);
        setState(() {
          _vehiculesAvecContrats = vehicules;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Véhicules'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _chargerVehicules();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _vehiculesAvecContrats.isEmpty
                  ? _buildEmptyWidget()
                  : _buildVehiculesList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _chargerVehicules();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de véhicule assuré.\nContactez votre agent d\'assurance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehiculesAvecContrats.length,
        itemBuilder: (context, index) {
          final item = _vehiculesAvecContrats[index];
          final vehicule = item['vehicule'] as VehiculeAssureModel;
          final contrat = item['contrat'] as ContratAssuranceModel?;
          final isAssure = item['isAssure'] as bool;
          final expireBientot = item['expireBientot'] as bool;

          return _buildVehiculeCard(vehicule, contrat, isAssure, expireBientot);
        },
      ),
    );
  }

  Widget _buildVehiculeCard(
    VehiculeAssureModel vehicule,
    ContratAssuranceModel? contrat,
    bool isAssure,
    bool expireBientot,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: _getStatusColor(isAssure, expireBientot).withOpacity(0.1),
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
                    color: _getStatusColor(isAssure, expireBientot),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getVehiculeIcon(vehicule.typeVehicule),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule.marque} ${vehicule.modele}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicule.immatriculation,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isAssure, expireBientot),
              ],
            ),
          ),
          
          // Détails du véhicule
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Année', vehicule.annee.toString()),
                _buildDetailRow('Couleur', vehicule.couleur),
                _buildDetailRow('Type', _formatTypeVehicule(vehicule.typeVehicule)),
                _buildDetailRow('Carburant', _formatCarburant(vehicule.carburant)),
                
                if (contrat != null) ...[
                  const Divider(height: 24),
                  _buildContractSection(contrat),
                ],
                
                const SizedBox(height: 16),
                _buildActionButtons(vehicule, contrat, isAssure),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractSection(ContratAssuranceModel contrat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations d\'assurance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('N° Contrat', contrat.numeroContrat),
        _buildDetailRow('Type', _formatTypeContrat(contrat.typeContrat)),
        _buildDetailRow('Validité', '${_formatDate(contrat.dateDebut)} - ${_formatDate(contrat.dateFin)}'),
        _buildDetailRow('Prime mensuelle', '${contrat.getPrime('mensuel')} TND'),
        
        if (contrat.couvertures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Couvertures:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: contrat.couvertures.map((couverture) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  _formatCouverture(couverture),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(bool isAssure, bool expireBientot) {
    String text;
    Color color;
    
    if (!isAssure) {
      text = 'Non assuré';
      color = Colors.red;
    } else if (expireBientot) {
      text = 'Expire bientôt';
      color = Colors.orange;
    } else {
      text = 'Assuré';
      color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(VehiculeAssureModel vehicule, ContratAssuranceModel? contrat, bool isAssure) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _voirDetails(vehicule, contrat),
            icon: const Icon(Icons.info_outline),
            label: const Text('Détails'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isAssure ? () => _declarerAccident(vehicule, contrat!) : null,
            icon: const Icon(Icons.report_problem),
            label: const Text('Déclarer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAssure ? Colors.red[600] : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(bool isAssure, bool expireBientot) {
    if (!isAssure) return Colors.red;
    if (expireBientot) return Colors.orange;
    return Colors.green;
  }

  IconData _getVehiculeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
        return Icons.motorcycle;
      case 'camion':
        return Icons.local_shipping;
      case 'utilitaire':
        return Icons.fire_truck;
      case 'autocar':
        return Icons.directions_bus;
      default:
        return Icons.directions_car;
    }
  }

  String _formatTypeVehicule(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatCarburant(String carburant) {
    final Map<String, String> labels = {
      'essence': 'Essence',
      'diesel': 'Diesel',
      'electrique': 'Électrique',
      'hybride': 'Hybride',
      'gpl': 'GPL',
    };
    return labels[carburant] ?? carburant;
  }

  String _formatTypeContrat(String type) {
    final Map<String, String> labels = {
      'responsabilite_civile': 'Responsabilité civile',
      'tous_risques': 'Tous risques',
      'tiers_collision': 'Tiers collision',
      'vol_incendie': 'Vol et incendie',
    };
    return labels[type] ?? type;
  }

  String _formatCouverture(String couverture) {
    final Map<String, String> labels = {
      'responsabilite_civile': 'RC',
      'dommages_collision': 'Collision',
      'vol': 'Vol',
      'incendie': 'Incendie',
      'bris_de_glace': 'Bris de glace',
      'catastrophes_naturelles': 'Cat. naturelles',
      'assistance_depannage': 'Assistance',
      'protection_juridique': 'Protection juridique',
    };
    return labels[couverture] ?? couverture;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _voirDetails(VehiculeAssureModel vehicule, ContratAssuranceModel? contrat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsBottomSheet(vehicule, contrat),
    );
  }

  Widget _buildDetailsBottomSheet(VehiculeAssureModel vehicule, ContratAssuranceModel? contrat) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Contenu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicule.marque} ${vehicule.modele}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    vehicule.immatriculation,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Détails complets du véhicule et du contrat
                  // ... (à compléter selon les besoins)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _declarerAccident(VehiculeAssureModel vehicule, ContratAssuranceModel contrat) {
    // Navigation vers l'écran de déclaration d'accident avec pré-remplissage
    // Cette fonctionnalité sera implémentée dans la prochaine étape
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Déclaration d\'accident pour ${vehicule.immatriculation}'),
        action: SnackBarAction(
          label: 'Continuer',
          onPressed: () {
            // TODO: Implémenter la navigation vers l'écran de déclaration
          },
        ),
      ),
    );
  }
}
