import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicule_assure_model.dart';
import '../services/vehicule_assure_service.dart';
import '../../auth/providers/auth_provider.dart';

/// 🔍 Dialog pour vérifier un contrat d'assurance
class ContractVerificationDialog extends StatefulWidget {
  const ContractVerificationDialog({super.key});

  @override
  State<ContractVerificationDialog> createState() => _ContractVerificationDialogState();
}

class _ContractVerificationDialogState extends State<ContractVerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroContratController = TextEditingController();
  final _immatriculationController = TextEditingController();
  
  final VehiculeAssureService _vehiculeService = VehiculeAssureService();
  
  bool _isLoading = false;
  VehiculeAssureModel? _vehiculeFound;
  String? _errorMessage;

  @override
  void dispose() {
    _numeroContratController.dispose();
    _immatriculationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // Formulaire ou résultat
            Expanded(
              child: _vehiculeFound != null 
                  ? _buildVerificationResult()
                  : _buildVerificationForm(),
            ),
            
            const SizedBox(height: 20),
            
            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête du dialog
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _vehiculeFound != null ? Icons.check_circle : Icons.search,
            color: _vehiculeFound != null ? Colors.green : Colors.purple,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _vehiculeFound != null 
                    ? 'Véhicule Trouvé !' 
                    : 'Vérification Contrat',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _vehiculeFound != null 
                    ? 'Contrat d\'assurance vérifié'
                    : 'Saisissez les informations de votre véhicule',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  /// 📝 Formulaire de vérification
  Widget _buildVerificationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message d'erreur
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Numéro de contrat
          TextFormField(
            controller: _numeroContratController,
            decoration: InputDecoration(
              labelText: 'Numéro de contrat',
              hintText: 'Ex: STAR-2024-001234',
              prefixIcon: const Icon(Icons.assignment),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir le numéro de contrat';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Immatriculation
          TextFormField(
            controller: _immatriculationController,
            decoration: InputDecoration(
              labelText: 'Immatriculation',
              hintText: 'Ex: 123 TUN 456',
              prefixIcon: const Icon(Icons.directions_car),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir l\'immatriculation';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _verifyContract(),
          ),

          const SizedBox(height: 20),

          // Informations
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Assurez-vous que votre contrat est actif\n'
                  '• Les informations doivent correspondre exactement\n'
                  '• Contactez votre assureur en cas de problème',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Résultat de la vérification
  Widget _buildVerificationResult() {
    final vehicule = _vehiculeFound!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut du contrat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vehicule.isContratActif ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: vehicule.isContratActif ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  vehicule.isContratActif ? Icons.check_circle : Icons.error,
                  color: vehicule.isContratActif ? Colors.green[700] : Colors.red[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicule.isContratActif ? 'Contrat Actif' : 'Contrat Expiré',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: vehicule.isContratActif ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      Text(
                        vehicule.isContratActif 
                            ? 'Votre véhicule est bien assuré'
                            : 'Veuillez renouveler votre contrat',
                        style: TextStyle(
                          fontSize: 12,
                          color: vehicule.isContratActif ? Colors.green[600] : Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Informations du véhicule
          _buildInfoSection(
            'Véhicule',
            [
              '${vehicule.vehicule.marque} ${vehicule.vehicule.modele}',
              'Année: ${vehicule.vehicule.annee}',
              'Couleur: ${vehicule.vehicule.couleur}',
              'Immatriculation: ${vehicule.vehicule.immatriculation}',
            ],
            Icons.directions_car,
          ),

          const SizedBox(height: 12),

          // Informations du contrat
          _buildInfoSection(
            'Contrat d\'Assurance',
            [
              'Assureur: ${_getAssureurName(vehicule.assureurId)}',
              'N° Contrat: ${vehicule.numeroContrat}',
              'Type: ${vehicule.contrat.typeCouverture}',
              'Expire le: ${_formatDate(vehicule.contrat.dateFin)}',
            ],
            Icons.shield,
          ),

          const SizedBox(height: 12),

          // Informations du propriétaire
          _buildInfoSection(
            'Propriétaire',
            [
              '${vehicule.proprietaire.prenom} ${vehicule.proprietaire.nom}',
              'CIN: ${vehicule.proprietaire.cin}',
              'Téléphone: ${vehicule.proprietaire.telephone}',
            ],
            Icons.person,
          ),
        ],
      ),
    );
  }

  /// 📊 Section d'informations
  Widget _buildInfoSection(String title, List<String> items, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.purple, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '• $item',
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  /// 🎬 Actions du dialog
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_vehiculeFound != null ? _useVehicle : _verifyContract),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vehiculeFound != null ? Colors.green : Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_vehiculeFound != null ? 'Utiliser' : 'Vérifier'),
          ),
        ),
      ],
    );
  }

  /// 🔍 Vérifier le contrat
  void _verifyContract() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Erreur: Utilisateur non connecté';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicule = await _vehiculeService.verifyContract(
        userId: userId,
        numeroContrat: _numeroContratController.text.trim(),
        immatriculation: _immatriculationController.text.trim(),
      );

      setState(() {
        if (vehicule != null) {
          _vehiculeFound = vehicule;
        } else {
          _errorMessage = 'Aucun véhicule trouvé avec ces informations.\n'
                        'Vérifiez le numéro de contrat et l\'immatriculation.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la vérification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Utiliser le véhicule trouvé
  void _useVehicle() {
    Navigator.of(context).pop(_vehiculeFound);
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

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}
