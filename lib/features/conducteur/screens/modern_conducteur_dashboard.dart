import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/widgets/modern_card.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../common/widgets/animated_counter.dart';
import '../models/conducteur_vehicle_model.dart';
import '../services/conducteur_auth_service.dart';

/// 🚗 Dashboard moderne pour conducteur avec gestion multi-véhicules
class ModernConducteurDashboard extends StatefulWidget {
  const ModernConducteurDashboard({Key? key}) : super(key: key);

  @override
  State<ModernConducteurDashboard> createState() => _ModernConducteurDashboardState();
}

class _ModernConducteurDashboardState extends State<ModernConducteurDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<ConducteurVehicleModel> _vehicles = [];
  ConducteurVehicleModel? _selectedVehicle;
  bool _isLoading = true;
  String? _conducteurUid;

  @override
  void initState() {
    super.initState();
    _conducteurUid = FirebaseAuth.instance.currentUser?.uid;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _loadVehicles();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    print('🔍 [MODERN DEBUG] === DÉBUT _loadVehicles ===');

    if (_conducteurUid == null) {
      print('🔍 [MODERN DEBUG] UID conducteur null');
      return;
    }

    print('🔍 [MODERN DEBUG] Chargement véhicules pour: $_conducteurUid');
    print('🔍 [MODERN DEBUG] État actuel - vehicles: ${_vehicles.length}, isLoading: $_isLoading');
    try {
      final vehicles = await ConducteurAuthService.getConducteurVehicles(_conducteurUid!);
      print('🔍 [MODERN DEBUG] Véhicules trouvés: ${vehicles.length}');

      for (int i = 0; i < vehicles.length; i++) {
        final vehicle = vehicles[i];
        print('🔍 [MODERN DEBUG] Véhicule $i: ${vehicle.brand} ${vehicle.model} (${vehicle.plate})');
      }

      setState(() {
        _vehicles = vehicles;

        // Mettre à jour le véhicule sélectionné
        if (_vehicles.isNotEmpty) {
          if (_selectedVehicle == null) {
            // Aucun véhicule sélectionné, prendre le premier
            _selectedVehicle = _vehicles.first;
            print('🔍 [MODERN DEBUG] Véhicule sélectionné (premier): ${_selectedVehicle!.brand} ${_selectedVehicle!.model}');
          } else {
            // Chercher le véhicule sélectionné dans la nouvelle liste par vehicleId
            final currentSelectedId = _selectedVehicle!.vehicleId;
            final foundVehicle = _vehicles.firstWhere(
              (v) => v.vehicleId == currentSelectedId,
              orElse: () => _vehicles.first,
            );
            _selectedVehicle = foundVehicle;
            print('🔍 [MODERN DEBUG] Véhicule sélectionné (mis à jour): ${_selectedVehicle!.brand} ${_selectedVehicle!.model}');
          }
        } else {
          _selectedVehicle = null;
        }

        _isLoading = false;
      });

      print('🔍 [MODERN DEBUG] État mis à jour - vehicles: ${_vehicles.length}, isLoading: $_isLoading');
    } catch (e) {
      print('❌ [MODERN DEBUG] Erreur chargement véhicules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          Colors.blue.shade50,
          Colors.indigo.shade50,
          Colors.white,
        ],
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildDashboardContent(),
                  ),
                ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDashboardContent() {
    return CustomScrollView(
      slivers: [
        _buildModernAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildWelcomeSection(),
              const SizedBox(height: 24),

              // Section véhicules (toujours affichée)
              _buildVehiclesSection(),
              const SizedBox(height: 24),

              // Actions rapides
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Section constats récents
              _buildConstatsSection(),
              const SizedBox(height: 24),

              // Sections conditionnelles selon les véhicules
              if (_vehicles.isNotEmpty) ...[
                _buildVehicleSelector(),
                const SizedBox(height: 24),
                if (_selectedVehicle != null) _buildSelectedVehicleCard(),
                const SizedBox(height: 24),
                _buildVehiclesList(),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Mes Véhicules',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade600,
                Colors.indigo.shade600,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () => _showNotifications(),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
            onPressed: () => _showProfile(),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.indigo.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? 'Conducteur',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_vehicles.length} véhicule${_vehicles.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
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

  Widget _buildNoVehiclesSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun véhicule enregistré',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez votre premier véhicule pour commencer à gérer vos assurances et déclarer des sinistres.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un véhicule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    if (_vehicles.length <= 1) return const SizedBox.shrink();

    // Vérifier que le véhicule sélectionné existe dans la liste actuelle
    ConducteurVehicleModel? validSelectedVehicle;
    if (_selectedVehicle != null) {
      // Chercher le véhicule par vehicleId pour éviter les problèmes de référence
      validSelectedVehicle = _vehicles.firstWhere(
        (v) => v.vehicleId == _selectedVehicle!.vehicleId,
        orElse: () => _vehicles.first,
      );
    } else {
      validSelectedVehicle = _vehicles.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Véhicule sélectionné',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ConducteurVehicleModel>(
              value: validSelectedVehicle,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue.shade600),
              items: _vehicles.map((vehicle) {
                return DropdownMenuItem<ConducteurVehicleModel>(
                  value: vehicle,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.indigo.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car,
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
                              '${vehicle.brand} ${vehicle.model}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              vehicle.plate,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (vehicle) {
                setState(() {
                  _selectedVehicle = vehicle;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _addVehicle,
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter véhicule'),
    );
  }

  Widget _buildSelectedVehicleCard() {
    if (_selectedVehicle == null) return const SizedBox.shrink();

    final vehicle = _selectedVehicle!;
    final hasValidInsurance = vehicle.hasValidInsurance;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasValidInsurance
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.orange.shade50, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasValidInsurance ? Colors.green.shade200 : Colors.orange.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasValidInsurance ? Colors.green : Colors.orange).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasValidInsurance
                        ? [Colors.green.shade600, Colors.green.shade800]
                        : [Colors.orange.shade600, Colors.orange.shade800],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Immatriculation: ${vehicle.plate}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Année: ${vehicle.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasValidInsurance ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasValidInsurance ? 'Assuré' : 'Non assuré',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (hasValidInsurance && vehicle.activeContract != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInsuranceInfo(vehicle.activeContract!),
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceInfo(VehicleContract contract) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations d\'assurance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Compagnie',
                contract.companyName,
                Icons.business,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Agence',
                contract.agencyName,
                Icons.location_city,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'N° Contrat',
                contract.contractNumber,
                Icons.description,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Validité',
                '${contract.endDate.day}/${contract.endDate.month}/${contract.endDate.year}',
                Icons.calendar_today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Déclarer Sinistre',
        'subtitle': 'Nouveau constat',
        'icon': Icons.warning,
        'gradient': [Colors.red.shade600, Colors.red.shade800],
        'onTap': () => _declareAccident(),
        'enabled': _selectedVehicle != null,
      },
      {
        'title': 'Mes Constats',
        'subtitle': 'Voir l\'historique',
        'icon': Icons.history,
        'gradient': [Colors.blue.shade600, Colors.blue.shade800],
        'onTap': () => _viewConstats(),
        'enabled': true,
      },
      {
        'title': 'Documents',
        'subtitle': 'Carte grise, permis',
        'icon': Icons.folder,
        'gradient': [Colors.green.shade600, Colors.green.shade800],
        'onTap': () => _viewDocuments(),
        'enabled': _selectedVehicle != null,
      },
      {
        'title': 'Mes Contrats',
        'subtitle': 'Contrats d\'assurance',
        'icon': Icons.description,
        'gradient': [Colors.purple.shade600, Colors.purple.shade800],
        'onTap': () => _showMesContrats(),
        'enabled': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action, index);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, int index) {
    final isEnabled = action['enabled'] as bool;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: isEnabled ? action['onTap'] : null,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isEnabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: action['gradient'],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey.shade400, Colors.grey.shade600],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isEnabled
                          ? (action['gradient'][0] as Color).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      action['icon'],
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        action['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        action['subtitle'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🚗 Section principale des véhicules (toujours affichée)
  Widget _buildVehiclesSection() {
    print('🔍 [VEHICLES SECTION] === CONSTRUCTION SECTION VÉHICULES ===');
    print('🔍 [VEHICLES SECTION] Nombre de véhicules: ${_vehicles.length}');
    print('🔍 [VEHICLES SECTION] isLoading: $_isLoading');
    print('🔍 [VEHICLES SECTION] conducteurUid: $_conducteurUid');

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes Véhicules',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/conducteur/vehicules'),
                icon: const Icon(Icons.list, size: 16),
                label: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_vehicles.isEmpty)
            _buildEmptyVehiclesState()
          else
            _buildVehiclesPreview(),
        ],
      ),
    );
  }

  Widget _buildVehiclesPreview() {
    return Column(
      children: [
        Text(
          '${_vehicles.length} véhicule${_vehicles.length > 1 ? 's' : ''} enregistré${_vehicles.length > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Afficher les 2 premiers véhicules
        ...(_vehicles.take(2).map((vehicle) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.directions_car,
                color: vehicle.hasValidInsurance ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      vehicle.plate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: vehicle.hasValidInsurance ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vehicle.hasValidInsurance ? 'Validé' : 'En attente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ))),

        if (_vehicles.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'et ${_vehicles.length - 2} autre${_vehicles.length - 2 > 1 ? 's' : ''}...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVehiclesList() {
    print('🔍 [VEHICLES LIST] Affichage liste - vehicles: ${_vehicles.length}');

    // Afficher la liste même s'il n'y a qu'un seul véhicule
    if (_vehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _vehicles.length == 1 ? 'Mon véhicule' : 'Tous mes véhicules',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/conducteur/vehicules'),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = _vehicles[index];
            final isSelected = vehicle.vehicleId == _selectedVehicle?.vehicleId;
            return _buildVehicleListItem(vehicle, isSelected, index);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyVehiclesState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule enregistré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier véhicule pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/conducteur/add-vehicle'),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter mon premier véhicule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleListItem(ConducteurVehicleModel vehicle, bool isSelected, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: vehicle.hasValidInsurance
                    ? [Colors.green.shade600, Colors.green.shade800]
                    : [Colors.orange.shade600, Colors.orange.shade800],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.directions_car,
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
                  '${vehicle.brand} ${vehicle.model}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.plate,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: vehicle.hasValidInsurance
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicle.hasValidInsurance ? 'Assuré' : 'Non assuré',
                    style: TextStyle(
                      color: vehicle.hasValidInsurance
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isSelected)
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedVehicle = vehicle;
                });
              },
              icon: Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
              ),
            )
          else
            Icon(
              Icons.radio_button_checked,
              color: Colors.blue.shade600,
            ),
        ],
      ),
    );
  }

  // Méthodes d'action
  void _addVehicle() async {
    print('🚗 [DASHBOARD] Navigation vers ajout de véhicule');

    final result = await Navigator.pushNamed(context, '/conducteur/add-vehicle');

    // Si un véhicule a été ajouté avec succès, recharger la liste
    if (result == true) {
      print('🚗 [DASHBOARD] Véhicule ajouté, rechargement de la liste');
      await _loadVehicles();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Véhicule ajouté avec succès !'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // Scroll vers la section véhicules si nécessaire
              },
            ),
          ),
        );
      }
    }
  }

  void _declareAccident() {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un véhicule'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Naviguer vers l'écran de sélection de constat
    Navigator.pushNamed(context, '/constat/selection');
  }

  void _viewConstats() {
    // Naviguer vers l'écran des accidents/constats
    Navigator.pushNamed(context, '/conducteur/accidents');
  }

  Widget _buildConstatsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Mes Constats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/conducteur/accidents'),
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenu des constats
            _buildConstatsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildConstatsContent() {
    // Pour l'instant, affichage d'un état vide
    // TODO: Intégrer avec le service de constats pour récupérer les données réelles
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun constat déclaré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos déclarations d\'accidents apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _declareAccident(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Déclarer un accident'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocuments() {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un véhicule'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Documents pour ${_selectedVehicle!.plate} - À implémenter'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _getAssistance() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Assistance et support - À implémenter'),
        backgroundColor: Colors.purple.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifications - À implémenter'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil - À implémenter'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// 📋 Afficher la liste des contrats du conducteur
  void _showMesContrats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes Contrats',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Mes contrats d\'assurance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Liste des contrats
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadConducteurContrats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text('Erreur: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final contrats = snapshot.data ?? [];

                    if (contrats.isEmpty) {
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
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: contrats.length,
                      itemBuilder: (context, index) {
                        final contrat = contrats[index];
                        return _buildConducteurContratCard(contrat);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Charger les contrats du conducteur
  Future<List<Map<String, dynamic>>> _loadConducteurContrats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final contratsQuery = await FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurInfo.conducteurId', isEqualTo: user.uid)
          .get();

      final contrats = <Map<String, dynamic>>[];

      for (final doc in contratsQuery.docs) {
        final contractData = doc.data();
        contractData['id'] = doc.id;

        // Récupérer les noms de compagnie et agence depuis l'agent
        print('🔍 [CONDUCTEUR] Contrat ${contractData['numeroContrat']} - agentId: ${contractData['agentId']}');
        print('🔍 [CONDUCTEUR] agentNom déjà présent: ${contractData['agentNom']}');

        if (contractData['agentId'] != null) {
          try {
            final agentDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(contractData['agentId'])
                .get();
            if (agentDoc.exists) {
              final agentData = agentDoc.data();
              contractData['compagnieNom'] = agentData?['compagnieNom'] ?? 'Compagnie inconnue';
              contractData['agenceNom'] = agentData?['agenceNom'] ?? 'Agence inconnue';
              print('✅ [CONDUCTEUR] Données récupérées depuis agent: ${contractData['compagnieNom']} / ${contractData['agenceNom']}');
            } else {
              print('❌ [CONDUCTEUR] Agent non trouvé dans users collection');
              // Utiliser des valeurs par défaut
              contractData['compagnieNom'] = 'Compagnie d\'Assurance';
              contractData['agenceNom'] = 'Agence d\'Assurance';
            }
          } catch (e) {
            print('❌ [CONDUCTEUR] Erreur récupération données agent: $e');
            // Utiliser des valeurs par défaut
            contractData['compagnieNom'] = 'Compagnie d\'Assurance';
            contractData['agenceNom'] = 'Agence d\'Assurance';
          }
        }

        contrats.add(contractData);
      }

      // Trier par date de création (plus récent en premier)
      contrats.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return contrats;
    } catch (e) {
      print('❌ Erreur chargement contrats conducteur: $e');
      return [];
    }
  }

  /// 📄 Carte de contrat pour conducteur
  Widget _buildConducteurContratCard(Map<String, dynamic> contrat) {
    final dateCreation = (contrat['createdAt'] as Timestamp?)?.toDate();
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
                // Informations principales
                _buildConducteurContratInfoRow(
                  'Véhicule',
                  '${contrat['vehiculeInfo']?['marque'] ?? 'N/A'} ${contrat['vehiculeInfo']?['modele'] ?? 'N/A'}',
                  Icons.directions_car,
                ),
                _buildConducteurContratInfoRow(
                  'Immatriculation',
                  contrat['vehiculeInfo']?['immatriculation'] ?? 'N/A',
                  Icons.confirmation_number,
                ),
                _buildConducteurContratInfoRow(
                  'Prime',
                  '${contrat['primeAnnuelle'] ?? 0} DT',
                  Icons.payments,
                ),
                _buildConducteurContratInfoRow(
                  'Compagnie',
                  contrat['compagnieNom'] ?? 'N/A',
                  Icons.business,
                ),
                _buildConducteurContratInfoRow(
                  'Agence',
                  contrat['agenceNom'] ?? 'N/A',
                  Icons.location_city,
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showConducteurContratDetails(contrat),
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
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadCarteVerte(contrat),
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

  /// 📝 Ligne d'information du contrat conducteur
  Widget _buildConducteurContratInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.purple.shade700),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👁️ Afficher les détails du contrat conducteur
  void _showConducteurContratDetails(Map<String, dynamic> contrat) {
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
              Text('Prime: ${contrat['primeAnnuelle']} DT'),
              Text('Franchise: ${contrat['franchise']} DT'),
              Text('Statut: ${contrat['statutContrat']}'),
              Text('Compagnie: ${contrat['compagnieNom'] ?? 'N/A'}'),
              Text('Agence: ${contrat['agenceNom'] ?? 'N/A'}'),
              Text('Agent: ${contrat['agentNom'] ?? 'N/A'}'),
              if (contrat['observations'] != null && contrat['observations'].isNotEmpty)
                Text('Observations: ${contrat['observations']}'),
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

  /// 🛡️ Afficher/Télécharger la carte verte
  void _downloadCarteVerte(Map<String, dynamic> contrat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.credit_card, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Carte Verte d\'Assurance'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARTE VERTE D\'ASSURANCE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCarteVerteRow('Police N°:', contrat['numeroContrat']),
                    _buildCarteVerteRow('Compagnie:', contrat['compagnieNom'] ?? 'N/A'),
                    _buildCarteVerteRow('Agence:', contrat['agenceNom'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    Text(
                      'VÉHICULE ASSURÉ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCarteVerteRow('Marque:', contrat['vehiculeInfo']?['marque'] ?? 'N/A'),
                    _buildCarteVerteRow('Modèle:', contrat['vehiculeInfo']?['modele'] ?? 'N/A'),
                    _buildCarteVerteRow('Immatriculation:', contrat['vehiculeInfo']?['immatriculation'] ?? 'N/A'),
                    _buildCarteVerteRow('Année:', contrat['vehiculeInfo']?['annee']?.toString() ?? 'N/A'),
                    const SizedBox(height: 8),
                    Text(
                      'VALIDITÉ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCarteVerteRow('Du:', _formatCarteVerteDate(contrat['dateDebut'])),
                    _buildCarteVerteRow('Au:', _formatCarteVerteDate(contrat['dateFin'])),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📄 Téléchargement PDF carte verte ${contrat['numeroContrat']} à implémenter'),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Télécharger PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information carte verte
  Widget _buildCarteVerteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater date pour carte verte
  String _formatCarteVerteDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
    return 'N/A';
  }
}
