import 'package:flutter/material.dart';
import '../../models/accident_session.dart';
import '../../models/vehicule_model.dart';

/// 📋 Écran de remplissage d'une section du constat
class ConstatSectionScreen extends StatefulWidget {
  final AccidentSession session;
  final String role;
  final VehiculeModel? vehicule;

  const ConstatSectionScreen({
    super.key,
    required this.session,
    required this.role,
    this.vehicule,
  });

  @override
  State<ConstatSectionScreen> createState() => _ConstatSectionScreenState();
}

class _ConstatSectionScreenState extends State<ConstatSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _donneesConstat = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Constat Véhicule ${widget.role}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Véhicule ${widget.role}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.vehicule != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${widget.vehicule!.marque} ${widget.vehicule!.modele}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Immatriculation: ${widget.vehicule!.numeroImmatriculation}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Informations du conducteur
              _buildSectionConducteur(),

              const SizedBox(height: 16),

              // Informations du véhicule
              _buildSectionVehicule(),

              const SizedBox(height: 16),

              // Circonstances
              _buildSectionCirconstances(),

              const SizedBox(height: 16),

              // Dégâts
              _buildSectionDegats(),

              const SizedBox(height: 32),

              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Sauvegarder ma partie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionConducteur() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du Conducteur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _donneesConstat['nom_conducteur'] = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro de permis',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _donneesConstat['numero_permis'] = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionVehicule() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du Véhicule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.vehicule != null) ...[
              Text('Marque: ${widget.vehicule!.marque}'),
              Text('Modèle: ${widget.vehicule!.modele}'),
              Text('Immatriculation: ${widget.vehicule!.numeroImmatriculation}'),
            ] else ...[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Marque',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _donneesConstat['marque'] = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Modèle',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _donneesConstat['modele'] = value,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCirconstances() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Circonstances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Cochez les cases qui correspondent à votre situation:'),
            const SizedBox(height: 12),
            // TODO: Ajouter les checkboxes des circonstances
            const Text('Circonstances à implémenter...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDegats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dégâts Apparents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description des dégâts',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (value) => _donneesConstat['degats'] = value,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _prendrePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Prendre une photo'),
            ),
          ],
        ),
      ),
    );
  }

  void _prendrePhoto() {
    // TODO: Implémenter prise de photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prise de photo à implémenter'),
      ),
    );
  }

  void _sauvegarder() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // TODO: Sauvegarder les données
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données sauvegardées avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }
}
