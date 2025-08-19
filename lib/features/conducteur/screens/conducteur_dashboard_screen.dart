import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/conducteur_profile_model.dart';
import '../models/conducteur_vehicle_model.dart';
import '../services/conducteur_auth_service.dart';
import '../../constat/models/sinistre_model.dart';

/// 🏠 Dashboard principal du conducteur
class ConducteurDashboardScreen extends StatefulWidget {
  const ConducteurDashboardScreen({super.key});

  @override
  State<ConducteurDashboardScreen> createState() => _ConducteurDashboardScreenState();
}

class _ConducteurDashboardScreenState extends State<ConducteurDashboardScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  ConducteurProfileModel? _profile;
  List<ConducteurVehicleModel> _vehicles = [];
  List<SinistreModel> _sinistres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 [DEBUG] Chargement du profil pour: ${_currentUser!.uid}');

      // Charger le profil
      final profile = await ConducteurAuthService.getConducteurProfile(_currentUser!.uid);
      print('🔍 [DEBUG] Profil chargé: ${profile?.firstName} ${profile?.lastName}');

      // Charger les véhicules
      print('🔍 [DEBUG] Chargement des véhicules...');
      final vehicles = await ConducteurAuthService.getConducteurVehicles(_currentUser!.uid);
      print('🔍 [DEBUG] Véhicules chargés: ${vehicles.length} véhicules trouvés');

      for (int i = 0; i < vehicles.length; i++) {
        final vehicle = vehicles[i];
        print('🔍 [DEBUG] Véhicule $i: ${vehicle.brand} ${vehicle.model} (${vehicle.plate})');
      }

      // TODO: Charger l'historique des sinistres

      setState(() {
        _profile = profile;
        _vehicles = vehicles;
        _isLoading = false;
      });

      print('🔍 [DEBUG] Dashboard mis à jour - isLoading: $_isLoading, vehicles: ${_vehicles.length}');
    } catch (e) {
      print('🔍 [DEBUG] Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mon Espace',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/conducteur/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/conducteur/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de bienvenue
              _buildWelcomeHeader(),
              const SizedBox(height: 24),

              // Actions rapides
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Mes véhicules
              _buildVehiclesSection(),
              const SizedBox(height: 24),

              // Contrats actifs
              _buildActiveContractsSection(),
              const SizedBox(height: 24),

              // Historique des sinistres
              _buildSinistresHistorySection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/constat/selection'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Constat'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _profile?.profileImageUrl != null
                ? NetworkImage(_profile!.profileImageUrl!)
                : null,
            child: _profile?.profileImageUrl == null
                ? Text(
                    _profile?.firstName.substring(0, 1).toUpperCase() ?? 'C',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${_profile?.firstName ?? 'Conducteur'} !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile?.isProfileComplete == true
                      ? 'Votre profil est complet'
                      : 'Complétez votre profil',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (_profile?.isProfileComplete != true)
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/conducteur/profile'),
              icon: const Icon(Icons.warning, color: Colors.orange),
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
          'Actions rapides',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Nouveau Constat',
                Icons.description,
                Colors.red,
                () => Navigator.pushNamed(context, '/constat/selection'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Ajouter un véhicule',
                Icons.directions_car,
                Colors.green,
                () => Navigator.pushNamed(context, '/conducteur/add-vehicle'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Mes documents',
                Icons.folder,
                Colors.orange,
                () => Navigator.pushNamed(context, '/conducteur/documents'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Mes constats',
                Icons.history,
                Colors.blue,
                () => Navigator.pushNamed(context, '/conducteur/constats'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesSection() {
    print('🔍 [DEBUG] _buildVehiclesSection appelée - vehicles: ${_vehicles.length}, isLoading: $_isLoading');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes véhicules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/conducteur/vehicles'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_vehicles.isEmpty)
          _buildEmptyState(
            'Aucun véhicule',
            'Ajoutez votre premier véhicule pour commencer',
            Icons.directions_car_outlined,
            () => Navigator.pushNamed(context, '/conducteur/add-vehicle'),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return _buildVehicleCard(vehicle);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleCard(ConducteurVehicleModel vehicle) {
    final hasValidInsurance = vehicle.hasValidInsurance;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValidInsurance ? Colors.green[300]! : Colors.orange[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasValidInsurance ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: hasValidInsurance ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      vehicle.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (hasValidInsurance) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'Assuré - ${vehicle.activeContract!.companyName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                'Assurance expirée ou manquante',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          Text(
            'Propriétaire: ${vehicle.ownerName}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Voir détails',
              onPressed: () => Navigator.pushNamed(
                context,
                '/conducteur/vehicle-details',
                arguments: vehicle.vehicleId,
              ),
              backgroundColor: Colors.grey[100],
              textColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContractsSection() {
    final activeContracts = _vehicles
        .expand((vehicle) => vehicle.activeContracts)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contrats actifs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (activeContracts.isEmpty)
          _buildEmptyState(
            'Aucun contrat actif',
            'Ajoutez vos contrats d\'assurance',
            Icons.security_outlined,
            () => Navigator.pushNamed(context, '/conducteur/add-vehicle'),
          )
        else
          Column(
            children: activeContracts.take(3).map((contract) {
              return _buildContractCard(contract);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildContractCard(VehicleContract contract) {
    final daysUntilExpiry = contract.daysUntilExpiry;
    final isExpiringSoon = daysUntilExpiry <= 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpiringSoon ? Colors.orange[300]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isExpiringSoon ? Colors.orange[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.security,
              color: isExpiringSoon ? Colors.orange[700] : Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Contrat: ${contract.contractNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Expire dans $daysUntilExpiry jours',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpiringSoon ? Colors.orange[700] : Colors.grey,
                    fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isExpiringSoon)
            Icon(Icons.warning, color: Colors.orange[700]),
        ],
      ),
    );
  }

  Widget _buildSinistresHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Historique des sinistres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/conducteur/sinistres'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_sinistres.isEmpty)
          _buildEmptyState(
            'Aucun sinistre déclaré',
            'Vos déclarations d\'accidents apparaîtront ici',
            Icons.event_note_outlined,
            null,
          )
        else
          Column(
            children: _sinistres.take(3).map((sinistre) {
              return _buildSinistreCard(sinistre);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSinistreCard(SinistreModel sinistre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(sinistre.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event_note,
              color: _getStatusColor(sinistre.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinistre du ${_formatDate(sinistre.dateAccident)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sinistre.location.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  sinistre.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(sinistre.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (onTap != null) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'Ajouter',
              onPressed: onTap,
              icon: Icons.add,
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(SinistreStatus status) {
    switch (status) {
      case SinistreStatus.draft:
        return Colors.grey;
      case SinistreStatus.open:
        return Colors.blue;
      case SinistreStatus.inProgress:
        return Colors.orange;
      case SinistreStatus.underExpertise:
        return Colors.purple;
      case SinistreStatus.closed:
        return Colors.green;
      case SinistreStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
