import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../vehicules/models/vehicule_assure_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/accident_form_widget.dart';
import '../widgets/photo_capture_widget.dart';
import '../widgets/ai_analysis_widget.dart';

/// 📋 Écran de déclaration d'accident
class AccidentDeclarationScreen extends StatefulWidget {
  final VehiculeAssureModel selectedVehicle;

  const AccidentDeclarationScreen({
    super.key,
    required this.selectedVehicle,
  });

  @override
  State<AccidentDeclarationScreen> createState() => _AccidentDeclarationScreenState();
}

class _AccidentDeclarationScreenState extends State<AccidentDeclarationScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  int _currentStep = 0;
  
  // Données du formulaire
  final Map<String, dynamic> _accidentData = {};
  final List<String> _photos = [];
  Map<String, dynamic>? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialiser avec les données du véhicule
    _accidentData['vehicule'] = widget.selectedVehicle.toMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📋 Déclaration d\'Accident'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Infos'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Photos'),
            Tab(icon: Icon(Icons.smart_toy), text: 'IA'),
            Tab(icon: Icon(Icons.send), text: 'Envoi'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Informations du véhicule sélectionné
          _buildVehicleHeader(),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccidentInfoTab(),
                _buildPhotosTab(),
                _buildAIAnalysisTab(),
                _buildSummaryTab(),
              ],
            ),
          ),
          
          // Barre de navigation
          _buildNavigationBar(),
        ],
      ),
    );
  }

  /// 🚗 En-tête avec informations du véhicule
  Widget _buildVehicleHeader() {
    final vehicule = widget.selectedVehicle;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicule.vehicule.marque} ${vehicule.vehicule.modele}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${vehicule.vehicule.immatriculation} • ${_getAssureurName(vehicule.assureurId)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 14),
                const SizedBox(width: 4),
                Text(
                  'Vérifié',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Onglet informations accident
  Widget _buildAccidentInfoTab() {
    return AccidentFormWidget(
      vehicule: widget.selectedVehicle,
      onDataChanged: (data) {
        setState(() {
          _accidentData.addAll(data);
        });
      },
    );
  }

  /// 📸 Onglet photos
  Widget _buildPhotosTab() {
    return PhotoCaptureWidget(
      onPhotosChanged: (photos) {
        setState(() {
          _photos.clear();
          _photos.addAll(photos);
        });
      },
    );
  }

  /// 🧠 Onglet analyse IA
  Widget _buildAIAnalysisTab() {
    return AIAnalysisWidget(
      photos: _photos,
      accidentData: _accidentData,
      onAnalysisComplete: (analysis) {
        setState(() {
          _aiAnalysis = analysis;
        });
      },
    );
  }

  /// 📋 Onglet résumé
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé de l'accident
          _buildSummarySection(
            'Informations de l\'Accident',
            [
              'Date: ${_accidentData['date'] ?? 'Non renseigné'}',
              'Heure: ${_accidentData['heure'] ?? 'Non renseigné'}',
              'Lieu: ${_accidentData['lieu'] ?? 'Non renseigné'}',
              'Description: ${_accidentData['description'] ?? 'Non renseigné'}',
            ],
            Icons.info,
          ),
          
          const SizedBox(height: 16),
          
          // Photos
          _buildSummarySection(
            'Photos de l\'Accident',
            [
              'Nombre de photos: ${_photos.length}',
              if (_photos.isEmpty) 'Aucune photo ajoutée',
            ],
            Icons.camera_alt,
          ),
          
          const SizedBox(height: 16),
          
          // Analyse IA
          if (_aiAnalysis != null)
            _buildSummarySection(
              'Analyse IA',
              [
                'Véhicules détectés: ${_aiAnalysis!['vehicules_detectes'] ?? 0}',
                'Gravité estimée: ${_aiAnalysis!['gravite'] ?? 'Non déterminée'}',
                'Confiance: ${(_aiAnalysis!['confiance'] ?? 0) * 100}%',
              ],
              Icons.smart_toy,
            ),
          
          const SizedBox(height: 24),
          
          // Bouton de soumission
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit() ? _submitAccidentReport : null,
              icon: const Icon(Icons.send),
              label: const Text('Soumettre la Déclaration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Section de résumé
  Widget _buildSummarySection(String title, List<String> items, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item', style: const TextStyle(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  /// 🧭 Barre de navigation
  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
            ),
          
          if (_tabController.index > 0) const SizedBox(width: 12),
          
          if (_tabController.index < 3)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(_tabController.index + 1);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Suivant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ Vérifier si on peut soumettre
  bool _canSubmit() {
    return _accidentData.isNotEmpty && 
           _photos.isNotEmpty;
  }

  /// 📤 Soumettre la déclaration
  void _submitAccidentReport() async {
    try {
      // TODO: Implémenter la soumission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Déclaration soumise avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retourner à l'écran précédent
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🏢 Nom de l'assureur
  String _getAssureurName(String assureurId) {
    switch (assureurId.toUpperCase()) {
      case 'STAR':
        return 'STAR Assurances';
      case 'MAGHREBIA':
        return 'Maghrebia Assurances';
      case 'GAT':
        return 'GAT Assurances';
      default:
        return assureurId;
    }
  }
}
