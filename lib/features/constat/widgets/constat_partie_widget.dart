import 'package:flutter/material.dart';
import '../models/constat_officiel_model.dart';

/// 🚗 Widget pour une partie du constat (Véhicule A, B, C...)
class ConstatPartieWidget extends StatefulWidget {
  final ConstatPartieModel partie;
  final bool isEditable;
  final Function(ConstatPartieModel) onChanged;

  const ConstatPartieWidget({
    super.key,
    required this.partie,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<ConstatPartieWidget> createState() => _ConstatPartieWidgetState();
}

class _ConstatPartieWidgetState extends State<ConstatPartieWidget> {
  late TextEditingController _societeAssuranceController;
  late TextEditingController _numeroContratController;
  late TextEditingController _agenceController;
  late TextEditingController _nomConducteurController;
  late TextEditingController _prenomConducteurController;
  late TextEditingController _adresseConducteurController;
  late TextEditingController _telephoneConducteurController;
  late TextEditingController _permisNumeroController;
  late TextEditingController _permisDelivreLeController;
  late TextEditingController _permisValableJusquauController;
  late TextEditingController _categoriePermisController;
  late TextEditingController _marqueVehiculeController;
  late TextEditingController _typeVehiculeController;
  late TextEditingController _numeroImmatriculationController;
  late TextEditingController _paysImmatriculationController;
  late TextEditingController _venantDeController;
  late TextEditingController _allantAController;
  late TextEditingController _observationsController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _societeAssuranceController = TextEditingController(text: widget.partie.societeAssurance ?? '');
    _numeroContratController = TextEditingController(text: widget.partie.numeroContrat ?? '');
    _agenceController = TextEditingController(text: widget.partie.agence ?? '');
    _nomConducteurController = TextEditingController(text: widget.partie.nomConducteur ?? '');
    _prenomConducteurController = TextEditingController(text: widget.partie.prenomConducteur ?? '');
    _adresseConducteurController = TextEditingController(text: widget.partie.adresseConducteur ?? '');
    _telephoneConducteurController = TextEditingController(text: widget.partie.telephoneConducteur ?? '');
    _permisNumeroController = TextEditingController(text: widget.partie.permisNumero ?? '');
    _permisDelivreLeController = TextEditingController(text: widget.partie.permisDelivreLe ?? '');
    _permisValableJusquauController = TextEditingController(text: widget.partie.permisValableJusquau ?? '');
    _categoriePermisController = TextEditingController(text: widget.partie.categoriePermis ?? '');
    _marqueVehiculeController = TextEditingController(text: widget.partie.marqueVehicule ?? '');
    _typeVehiculeController = TextEditingController(text: widget.partie.typeVehicule ?? '');
    _numeroImmatriculationController = TextEditingController(text: widget.partie.numeroImmatriculation ?? '');
    _paysImmatriculationController = TextEditingController(text: widget.partie.paysImmatriculation ?? 'Tunisie');
    _venantDeController = TextEditingController(text: widget.partie.venantDe ?? '');
    _allantAController = TextEditingController(text: widget.partie.allantA ?? '');
    _observationsController = TextEditingController(text: widget.partie.observations ?? '');
  }

  @override
  void dispose() {
    _societeAssuranceController.dispose();
    _numeroContratController.dispose();
    _agenceController.dispose();
    _nomConducteurController.dispose();
    _prenomConducteurController.dispose();
    _adresseConducteurController.dispose();
    _telephoneConducteurController.dispose();
    _permisNumeroController.dispose();
    _permisDelivreLeController.dispose();
    _permisValableJusquauController.dispose();
    _categoriePermisController.dispose();
    _marqueVehiculeController.dispose();
    _typeVehiculeController.dispose();
    _numeroImmatriculationController.dispose();
    _paysImmatriculationController.dispose();
    _venantDeController.dispose();
    _allantAController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPartieColor(widget.partie.partieId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la partie
        _buildPartieHeader(color),
        
        const SizedBox(height: 16),
        
        // Société d'Assurance
        _buildAssuranceSection(),
        
        const SizedBox(height: 16),
        
        // Identité du Conducteur
        _buildConducteurSection(),
        
        const SizedBox(height: 16),
        
        // Identité du Véhicule
        _buildVehiculeSection(),
        
        const SizedBox(height: 16),
        
        // Dégâts apparents
        _buildDegatsSection(),
        
        const SizedBox(height: 16),
        
        // Observations
        _buildObservationsSection(),
      ],
    );
  }

  Widget _buildPartieHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'VÉHICULE ${widget.partie.partieId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Véhicule ${widget.partie.partieId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      widget.isEditable ? Icons.edit : Icons.visibility,
                      size: 16,
                      color: widget.isEditable ? color : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isEditable ? 'Modifiable' : 'Lecture seule',
                      style: TextStyle(
                        color: widget.isEditable ? color : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildAssuranceSection() {
    return _buildSection(
      title: '6. Société d\'Assurance',
      children: [
        _buildTextField(
          label: 'Nom de la société',
          controller: _societeAssuranceController,
          onChanged: _updatePartie,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'N° de contrat d\'assurance',
                controller: _numeroContratController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Agence',
                controller: _agenceController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Attestation d\'assurance valable',
          controller: TextEditingController(text: widget.partie.attestationValable ?? ''),
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildConducteurSection() {
    return _buildSection(
      title: '7. Identité du Conducteur',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Nom',
                controller: _nomConducteurController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Prénom',
                controller: _prenomConducteurController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Adresse',
          controller: _adresseConducteurController,
          onChanged: _updatePartie,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Téléphone',
          controller: _telephoneConducteurController,
          onChanged: _updatePartie,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'Permis de conduire N°',
                controller: _permisNumeroController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Catégorie',
                controller: _categoriePermisController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Délivré le',
                controller: _permisDelivreLeController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Valable jusqu\'au',
                controller: _permisValableJusquauController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehiculeSection() {
    return _buildSection(
      title: '8. Identité du Véhicule',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Marque, Type',
                controller: _marqueVehiculeController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Type',
                controller: _typeVehiculeController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'N° d\'immatriculation',
                controller: _numeroImmatriculationController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Pays',
                controller: _paysImmatriculationController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Venant de',
                controller: _venantDeController,
                onChanged: _updatePartie,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Allant à',
                controller: _allantAController,
                onChanged: _updatePartie,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDegatsSection() {
    return _buildSection(
      title: '11. Dégâts apparents',
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Zone de dessin pour les dégâts\n(À implémenter)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObservationsSection() {
    return _buildSection(
      title: '14. Observations',
      children: [
        _buildTextField(
          label: 'Observations',
          controller: _observationsController,
          onChanged: _updatePartie,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    VoidCallback? onChanged,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled && widget.isEditable,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: !enabled || !widget.isEditable,
            fillColor: !enabled || !widget.isEditable ? Colors.grey[100] : null,
          ),
          onChanged: onChanged != null ? (_) => onChanged() : null,
        ),
      ],
    );
  }

  Color _getPartieColor(String partieId) {
    switch (partieId) {
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.purple;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updatePartie() {
    final updatedPartie = widget.partie.copyWith(
      societeAssurance: _societeAssuranceController.text,
      numeroContrat: _numeroContratController.text,
      agence: _agenceController.text,
      nomConducteur: _nomConducteurController.text,
      prenomConducteur: _prenomConducteurController.text,
      adresseConducteur: _adresseConducteurController.text,
      telephoneConducteur: _telephoneConducteurController.text,
      permisNumero: _permisNumeroController.text,
      permisDelivreLe: _permisDelivreLeController.text,
      permisValableJusquau: _permisValableJusquauController.text,
      categoriePermis: _categoriePermisController.text,
      marqueVehicule: _marqueVehiculeController.text,
      typeVehicule: _typeVehiculeController.text,
      numeroImmatriculation: _numeroImmatriculationController.text,
      paysImmatriculation: _paysImmatriculationController.text,
      venantDe: _venantDeController.text,
      allantA: _allantAController.text,
      observations: _observationsController.text,
    );
    
    widget.onChanged(updatedPartie);
  }
}
