import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../vehicule/models/vehicule_assure_model.dart';
import '../../vehicule/models/vehicule_conducteur_liaison_model.dart';
import '../../vehicule/services/vehicule_affectation_service.dart';
import '../../vehicule/services/vehicule_assure_service.dart';

/// 🔗 Écran d'affectation véhicule pour agents d'assurance
class VehiculeAffectationScreen extends ConsumerStatefulWidget {
  final VehiculeAssureModel? vehiculePreselectionne;

  const VehiculeAffectationScreen({
    super.key,
    this.vehiculePreselectionne,
  });

  @override
  ConsumerState<VehiculeAffectationScreen> createState() => _VehiculeAffectationScreenState();
}

class _VehiculeAffectationScreenState extends ConsumerState<VehiculeAffectationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _commentaireController = TextEditingController();

  VehiculeAssureModel? _vehiculeSelectionne;
  List<VehiculeAssureModel> _vehicules = [];
  List<String> _droitsSelectionnes = [];
  DateTime? _dateExpiration;
  bool _isLoading = false;
  bool _loadingVehicules = true;

  @override
  void initState() {
    super.initState();
    _vehiculeSelectionne = widget.vehiculePreselectionne;
    _droitsSelectionnes = List.from(ConducteurDroits.defaultDroits);
    _loadVehicules();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicules() async {
    try {
      setState(() => _loadingVehicules = true);
      
      final vehiculeService = VehiculeAssureService();
      final vehicules = await vehiculeService.getAllVehicles();
      
      setState(() {
        _vehicules = vehicules;
        _loadingVehicules = false;
      });
    } catch (e) {
      setState(() => _loadingVehicules = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _affecterVehicule() async {
    if (!_formKey.currentState!.validate() || _vehiculeSelectionne == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await VehiculeAffectationService.affecterVehicule(
        vehiculeId: _vehiculeSelectionne!.id,
        conducteurEmail: _emailController.text.trim(),
        agentAffecteur: 'current_agent_id', // TODO: Récupérer l'ID de l'agent connecté
        agenceId: 'current_agence_id', // TODO: Récupérer l'ID de l'agence
        compagnieId: _vehiculeSelectionne!.assureurId,
        droits: _droitsSelectionnes,
        dateExpiration: _dateExpiration,
        commentaire: _commentaireController.text.trim().isNotEmpty 
            ? _commentaireController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Véhicule affecté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Affecter Véhicule',
        backgroundColor: Colors.blue,
      ),
      body: _loadingVehicules
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    _buildHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Sélection véhicule
                    _buildVehiculeSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Email conducteur
                    _buildEmailField(),
                    
                    const SizedBox(height: 24),
                    
                    // Droits
                    _buildDroitsSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Date d'expiration
                    _buildDateExpiration(),
                    
                    const SizedBox(height: 24),
                    
                    // Commentaire
                    _buildCommentaireField(),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton d'affectation
                    _buildAffectationButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Affectation Véhicule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Donner accès à un conducteur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚗 Sélectionner le véhicule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: _vehiculeSelectionne != null
              ? _buildVehiculeCard(_vehiculeSelectionne!)
              : DropdownButtonFormField<VehiculeAssureModel>(
                  decoration: const InputDecoration(
                    labelText: 'Choisir un véhicule',
                    border: OutlineInputBorder(),
                  ),
                  value: _vehiculeSelectionne,
                  items: _vehicules.map((vehicule) {
                    return DropdownMenuItem(
                      value: vehicule,
                      child: Text(
                        '${vehicule.vehicule.marque} ${vehicule.vehicule.modele} - ${vehicule.vehicule.immatriculation}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (vehicule) {
                    setState(() {
                      _vehiculeSelectionne = vehicule;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Veuillez sélectionner un véhicule';
                    }
                    return null;
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVehiculeCard(VehiculeAssureModel vehicule) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.directions_car, color: Colors.blue[700], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vehicule.vehicule.marque} ${vehicule.vehicule.modele}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                vehicule.vehicule.immatriculation,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        if (widget.vehiculePreselectionne == null)
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () {
              setState(() {
                _vehiculeSelectionne = null;
              });
            },
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📧 Email du conducteur',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email du conducteur',
            hintText: 'exemple@email.com',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer l\'email du conducteur';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Format d\'email invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDroitsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔑 Droits accordés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: ConducteurDroits.allDroits.map((droit) {
              return CheckboxListTile(
                title: Text(ConducteurDroits.getDroitName(droit)),
                subtitle: Text('${ConducteurDroits.getDroitIcon(droit)} $droit'),
                value: _droitsSelectionnes.contains(droit),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _droitsSelectionnes.add(droit);
                    } else {
                      _droitsSelectionnes.remove(droit);
                    }
                  });
                },
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateExpiration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Date d\'expiration (optionnel)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateExpiration ?? DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (date != null) {
              setState(() {
                _dateExpiration = date;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF6B7280)),
                const SizedBox(width: 12),
                Text(
                  _dateExpiration != null
                      ? '${_dateExpiration!.day}/${_dateExpiration!.month}/${_dateExpiration!.year}'
                      : 'Aucune date d\'expiration',
                  style: TextStyle(
                    fontSize: 14,
                    color: _dateExpiration != null ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                if (_dateExpiration != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _dateExpiration = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentaireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💬 Commentaire (optionnel)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _commentaireController,
          decoration: const InputDecoration(
            labelText: 'Commentaire',
            hintText: 'Notes ou instructions particulières...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAffectationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _affecterVehicule,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.link),
        label: Text(_isLoading ? 'Affectation en cours...' : 'Affecter le véhicule'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
