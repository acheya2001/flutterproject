import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../models/vehicule_model.dart';
import '../providers/vehicule_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'vehicule_form_screen.dart';
import 'vehicule_detail_screen.dart';

class VehiculesListScreen extends StatefulWidget {
  const VehiculesListScreen({Key? key}) : super(key: key);

  @override
  State<VehiculesListScreen> createState() => _VehiculesListScreenState();
}

class _VehiculesListScreenState extends State<VehiculesListScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicules();
  }

  Future<void> _loadVehicules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final vehiculeProvider = Provider.of<VehiculeProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        await vehiculeProvider.fetchVehiculesByProprietaireId(authProvider.currentUser!.id);
      } else {
        throw Exception('Utilisateur non authentifié');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes véhicules',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
              ),
            )
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _loadVehicules,
                )
              : _buildVehiculesList(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4299E1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4299E1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToAddVehicule(context),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehiculesList() {
    final vehiculeProvider = Provider.of<VehiculeProvider>(context);
    final vehicules = vehiculeProvider.vehicules;

    if (vehicules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 40,
                color: Color(0xFF4299E1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun véhicule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez votre premier véhicule\npour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVehicules,
      color: const Color(0xFF4299E1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicules.length,
        itemBuilder: (context, index) {
          final vehicule = vehicules[index];
          return _buildVehiculeCard(context, vehicule, index);
        },
      ),
    );
  }

  Widget _buildVehiculeCard(BuildContext context, VehiculeModel vehicule, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final isExpired = vehicule.dateFinValidite != null && vehicule.dateFinValidite!.isBefore(now);
    final expiresInDays = vehicule.dateFinValidite != null
        ? vehicule.dateFinValidite!.difference(now).inDays
        : 0;
    final isExpiringSoon = !isExpired && expiresInDays <= 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isExpired || isExpiringSoon
            ? Border.all(
                color: isExpired ? const Color(0xFFE53E3E) : const Color(0xFFD69E2E),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToVehiculeDetail(context, vehicule),
          child: Column(
            children: [
              // Status banner
              if (isExpired || isExpiringSoon)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isExpired 
                        ? const Color(0xFFFED7D7) 
                        : const Color(0xFFFEEBC8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpired ? Icons.error_outline : Icons.warning_amber_outlined,
                        size: 16,
                        color: isExpired ? const Color(0xFFE53E3E) : const Color(0xFFD69E2E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpired
                            ? 'Assurance expirée'
                            : 'Expire dans $expiresInDays jours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isExpired ? const Color(0xFFE53E3E) : const Color(0xFFD69E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Card content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.directions_car_outlined,
                            size: 20,
                            color: Color(0xFF4299E1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicule.immatriculation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicule.marque.isNotEmpty ? vehicule.marque : "Marque"} ${vehicule.modele.isNotEmpty ? vehicule.modele : "Modèle"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: const Color(0xFF718096),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Assurance',
                            vehicule.compagnieAssurance.isNotEmpty 
                                ? vehicule.compagnieAssurance 
                                : 'Non spécifié',
                            Icons.security_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem(
                            'Validité',
                            vehicule.dateFinValidite != null 
                                ? dateFormat.format(vehicule.dateFinValidite!) 
                                : 'Non spécifié',
                            Icons.calendar_today_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF718096)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF718096),
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
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddVehicule(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehiculeFormScreen(),
      ),
    );

    if (result == true) {
      _loadVehicules();
    }
  }

  Future<void> _navigateToVehiculeDetail(BuildContext context, VehiculeModel vehicule) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehiculeDetailScreen(vehicule: vehicule),
      ),
    );

    if (result == true) {
      _loadVehicules();
    }
  }
}
