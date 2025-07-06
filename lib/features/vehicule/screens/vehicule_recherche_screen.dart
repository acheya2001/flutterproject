import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../models/vehicule_recherche_model.dart';
import '../models/vehicule_assure_model.dart';
import '../services/vehicule_recherche_service.dart';
import '../widgets/vehicule_card.dart';

/// 🔍 Écran de recherche véhicule tiers
class VehiculeRechercheScreen extends ConsumerStatefulWidget {
  final ContexteRecherche contexte;
  final String? sessionId;

  const VehiculeRechercheScreen({
    super.key,
    this.contexte = ContexteRecherche.declarationAccident,
    this.sessionId,
  });

  @override
  ConsumerState<VehiculeRechercheScreen> createState() => _VehiculeRechercheScreenState();
}

class _VehiculeRechercheScreenState extends ConsumerState<VehiculeRechercheScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de champs
  final _assuranceController = TextEditingController();
  final _numeroContratController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _proprietaireNomController = TextEditingController();
  final _proprietairePrenomController = TextEditingController();
  final _proprietaireCinController = TextEditingController();

  // État
  bool _isSearching = false;
  List<VehiculeAssureModel> _resultats = [];
  bool _hasSearched = false;

  // Assurances disponibles
  final List<String> _assurances = [
    'STAR',
    'MAGHREBIA',
    'LLOYD',
    'GAT',
    'AST',
  ];

  @override
  void dispose() {
    _assuranceController.dispose();
    _numeroContratController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _proprietaireNomController.dispose();
    _proprietairePrenomController.dispose();
    _proprietaireCinController.dispose();
    super.dispose();
  }

  Future<void> _rechercherVehicule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier qu'au moins un critère est renseigné
    final criteres = CriteresRecherche(
      assurance: _assuranceController.text.trim().isNotEmpty ? _assuranceController.text.trim() : null,
      numeroContrat: _numeroContratController.text.trim().isNotEmpty ? _numeroContratController.text.trim() : null,
      immatriculation: _immatriculationController.text.trim().isNotEmpty ? _immatriculationController.text.trim() : null,
      marque: _marqueController.text.trim().isNotEmpty ? _marqueController.text.trim() : null,
      modele: _modeleController.text.trim().isNotEmpty ? _modeleController.text.trim() : null,
      proprietaireNom: _proprietaireNomController.text.trim().isNotEmpty ? _proprietaireNomController.text.trim() : null,
      proprietairePrenom: _proprietairePrenomController.text.trim().isNotEmpty ? _proprietairePrenomController.text.trim() : null,
      proprietaireCin: _proprietaireCinController.text.trim().isNotEmpty ? _proprietaireCinController.text.trim() : null,
    );

    if (!criteres.hasAnyCriteria) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner au moins un critère de recherche'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _resultats = [];
    });

    try {
      final resultats = await VehiculeRechercheService.rechercherVehicule(
        conducteurRechercheur: 'current_user_id', // TODO: Récupérer l'ID de l'utilisateur connecté
        criteres: criteres,
        contexte: widget.contexte,
        sessionId: widget.sessionId,
      );

      setState(() {
        _resultats = resultats;
        _hasSearched = true;
      });

      if (resultats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun véhicule trouvé avec ces critères'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${resultats.length} véhicule(s) trouvé(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _viderFormulaire() {
    _assuranceController.clear();
    _numeroContratController.clear();
    _immatriculationController.clear();
    _marqueController.clear();
    _modeleController.clear();
    _proprietaireNomController.clear();
    _proprietairePrenomController.clear();
    _proprietaireCinController.clear();
    
    setState(() {
      _resultats = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Rechercher Véhicule',
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Formulaire de recherche
            _buildSearchForm(),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            _buildActionButtons(),
            
            const SizedBox(height: 24),
            
            // Résultats
            if (_hasSearched) _buildResults(),
          ],
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
          colors: [Colors.purple[50]!, Colors.purple[100]!],
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
                  color: Colors.purple[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identifier Véhicule Tiers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contexte: ${widget.contexte.name}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple[700],
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

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Critères de recherche',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          
          // Assurance
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Compagnie d\'assurance',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('-- Sélectionner --')),
              ..._assurances.map((assurance) {
                return DropdownMenuItem(
                  value: assurance,
                  child: Text(assurance),
                );
              }),
            ],
            onChanged: (value) {
              _assuranceController.text = value ?? '';
            },
          ),
          
          const SizedBox(height: 16),
          
          // Numéro de contrat et immatriculation
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numeroContratController,
                  decoration: const InputDecoration(
                    labelText: 'N° Contrat',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _immatriculationController,
                  decoration: const InputDecoration(
                    labelText: 'Immatriculation',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Marque et modèle
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _marqueController,
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    prefixIcon: Icon(Icons.directions_car),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _modeleController,
                  decoration: const InputDecoration(
                    labelText: 'Modèle',
                    prefixIcon: Icon(Icons.car_rental),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Propriétaire
          ExpansionTile(
            title: const Text('Informations propriétaire (optionnel)'),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proprietaireNomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom propriétaire',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _proprietairePrenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom propriétaire',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proprietaireCinController,
                decoration: const InputDecoration(
                  labelText: 'CIN propriétaire',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSearching ? null : _rechercherVehicule,
            icon: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isSearching ? 'Recherche...' : 'Chercher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _viderFormulaire,
            icon: const Icon(Icons.clear),
            label: const Text('Vider'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Résultats (${_resultats.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        
        if (_resultats.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text(
                  'Aucun véhicule trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Essayez avec d\'autres critères',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resultats.length,
            itemBuilder: (context, index) {
              final vehicule = _resultats[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VehicleCard(
                  vehicule: vehicule,
                  onTap: () => _selectionnerVehicule(vehicule),
                  showOwnerInfo: true,
                ),
              );
            },
          ),
      ],
    );
  }

  void _selectionnerVehicule(VehiculeAssureModel vehicule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la sélection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Véhicule: ${vehicule.vehicule.marque} ${vehicule.vehicule.modele}'),
            Text('Immatriculation: ${vehicule.vehicule.immatriculation}'),
            Text('Propriétaire: ${vehicule.proprietaire.prenom} ${vehicule.proprietaire.nom}'),
            const SizedBox(height: 16),
            const Text('Voulez-vous sélectionner ce véhicule ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, vehicule);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
