import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../vehicule/models/vehicule_assure_model.dart';
import '../../vehicule/services/vehicule_affectation_service.dart';
import '../../vehicule/widgets/vehicule_card.dart';
// import '../../insurance/screens/vehicule_verification_screen.dart'; // Supprimé
import '../../constat/screens/conducteur_declaration_screen.dart';

class ConducteurVehiculesScreen extends ConsumerStatefulWidget {
  final String conducteurPosition;
  final String? sessionId;
  final bool isCollaborative;

  const ConducteurVehiculesScreen({
    Key? key,
    required this.conducteurPosition,
    this.sessionId,
    this.isCollaborative = false,
  }) : super(key: key);

  @override
  ConsumerState<ConducteurVehiculesScreen> createState() => _ConducteurVehiculesScreenState();
}

class _ConducteurVehiculesScreenState extends ConsumerState<ConducteurVehiculesScreen> {
  List<VehiculeAssureModel> _vehiculesAffectes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehiculesAffectes();
  }

  Future<void> _loadVehiculesAffectes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authState = ref.read(authProvider);
      final user = authState.currentUser;

      if (user?.email != null) {
        final vehicules = await VehiculeAffectationService.getVehiculesConducteur(user!.email);
        setState(() {
          _vehiculesAffectes = vehicules;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onVehiculeSelected(VehiculeAssureModel vehicule) {
    // TODO: Adapter pour utiliser VehiculeAssureModel au lieu de VehiculeModel
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConducteurDeclarationScreen(
          conducteurPosition: widget.conducteurPosition,
          sessionId: widget.sessionId,
          isCollaborative: widget.isCollaborative,
          selectedVehicule: null, // TODO: Convertir VehiculeAssureModel vers VehiculeModel
        ),
      ),
    );
  }

  Future<void> _refreshVehicules() async {
    await _loadVehiculesAffectes();
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = widget.conducteurPosition == 'A' ? Colors.blueAccent : Colors.greenAccent;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mes Véhicules',
        backgroundColor: appBarColor,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshVehicules,
        child: _buildBody(appBarColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Ajouter Véhicule')),
                body: const Center(
                  child: Text('🚧 Ajout de véhicule à implémenter'),
                ),
              ),
            ),
          );
        },
        label: const Text(
          'Vérifier mon véhicule',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        icon: const Icon(Icons.verified_user, size: 20),
        backgroundColor: appBarColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildBody(Color cardAccentColor) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Réessayer',
              onPressed: _refreshVehicules,
              color: cardAccentColor,
            ),
          ],
        ),
      );
    }

    if (_vehiculesAffectes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardAccentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: cardAccentColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aucun véhicule affecté',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vérifiez votre véhicule avec votre assurance et numéro de contrat pour déclarer un accident.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Vérifier mon véhicule',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Vérification Véhicule')),
                      body: const Center(
                        child: Text('🚧 Écran de vérification à implémenter'),
                      ),
                    ),
                    ),
                  );
                },
                color: cardAccentColor,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _vehiculesAffectes.length,
      itemBuilder: (context, index) {
        final vehicule = _vehiculesAffectes[index];
        return VehicleCard(
          vehicule: vehicule,
          onTap: () => _onVehiculeSelected(vehicule),
          accentColor: cardAccentColor,
          showContractInfo: true,
        );
      },
    );
  }
}