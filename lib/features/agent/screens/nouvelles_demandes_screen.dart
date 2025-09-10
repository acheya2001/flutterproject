import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/complete_insurance_workflow_service.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/models/contract_models.dart';

/// 👨‍💼 Écran pour que l'agent traite les nouvelles demandes d'assurance
class NouvellesDemandesScreen extends StatefulWidget {
  final String agenceId;
  
  const NouvellesDemandesScreen({
    Key? key,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<NouvellesDemandesScreen> createState() => _NouvellesDemandesScreenState();
}

class _NouvellesDemandesScreenState extends State<NouvellesDemandesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadDemandes();
    });
  }

  Future<void> _loadDemandes() async {
    try {
      if (mounted) setState(() {
        _isLoading = true;
        _error = null;
      });

      final demandes = await CompleteInsuranceWorkflowService.getAgencyRequests(widget.agenceId);
      
      if (mounted) setState(() {
        _demandes = demandes;
        _isLoading = false;
      });

      LoggingService.info('NouvellesDemandesScreen', '✅ ${demandes.length} demandes chargées pour agence ${widget.agenceId}');
    } catch (e) {
      LoggingService.error('NouvellesDemandesScreen', '❌ Erreur chargement demandes agence', e);
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nouvelles Demandes'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDemandes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des demandes...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDemandes,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final demandesPendantes = _demandes.where((d) => d['status'] == 'pending_agent_review').toList();

    if (demandesPendantes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 80, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune nouvelle demande',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Toutes les demandes ont été traitées',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDemandes,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDemandes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demandesPendantes.length,
        itemBuilder: (context, index) {
          final demande = demandesPendantes[index];
          return _buildDemandeCard(demande);
        },
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final vehicleData = demande['vehicleData'] as Map<String, dynamic>;
    final conducteurData = demande['conducteurData'] as Map<String, dynamic>;
    final createdAt = demande['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec info conducteur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade700],
              ),
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
                  child: const Icon(
                    Icons.person_add,
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
                        '${conducteurData['prenom']} ${conducteurData['nom']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        conducteurData['email'] ?? 'Email non fourni',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
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
                  child: const Text(
                    'NOUVEAU',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu de la demande
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations véhicule
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Véhicule à assurer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Marque/Modèle', '${vehicleData['marque']} ${vehicleData['modele']}'),
                      _buildInfoRow('Immatriculation', vehicleData['immatriculation'] ?? 'N/A'),
                      _buildInfoRow('Année', '${vehicleData['annee']}'),
                      _buildInfoRow('Type', vehicleData['typeVehicule'] ?? 'N/A'),
                      _buildInfoRow('Carburant', vehicleData['carburant'] ?? 'N/A'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Informations conducteur
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Informations conducteur',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Téléphone', conducteurData['telephone'] ?? 'N/A'),
                      _buildInfoRow('Adresse', conducteurData['adresse'] ?? 'N/A'),
                      _buildInfoRow('Permis', conducteurData['permisNumber'] ?? 'N/A'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Date de création
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Demande reçue le ${_formatDate(createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDemandeDetails(demande),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Voir détails'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                          side: BorderSide(color: Colors.blue.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _creerContrat(demande),
                        icon: const Icon(Icons.assignment, size: 16),
                        label: const Text('Créer contrat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime date;
    if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'N/A';
      }
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'N/A';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDemandeDetails(Map<String, dynamic> demande) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de la demande'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${demande['id']}'),
              const SizedBox(height: 8),
              const Text('Conducteur:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${demande['conducteurData']['prenom']} ${demande['conducteurData']['nom']}'),
              Text('Email: ${demande['conducteurData']['email']}'),
              Text('Téléphone: ${demande['conducteurData']['telephone']}'),
              const SizedBox(height: 8),
              const Text('Véhicule:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${demande['vehicleData']['marque']} ${demande['vehicleData']['modele']}'),
              Text('Immatriculation: ${demande['vehicleData']['immatriculation']}'),
              Text('Année: ${demande['vehicleData']['annee']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _creerContrat(demande);
            },
            child: const Text('Créer contrat'),
          ),
        ],
      ),
    );
  }

  void _creerContrat(Map<String, dynamic> demande) {
    showDialog(
      context: context,
      builder: (context) => _ContractCreationDialog(
        demande: demande,
        onContractCreated: () {
          _loadDemandes(); // Recharger la liste
        },
      ),
    );
  }
}

/// 📋 Dialog pour créer un contrat avec montant et fréquence
class _ContractCreationDialog extends StatefulWidget {
  final Map<String, dynamic> demande;
  final VoidCallback onContractCreated;

  const _ContractCreationDialog({
    required this.demande,
    required this.onContractCreated,
  });

  @override
  State<_ContractCreationDialog> createState() => _ContractCreationDialogState();
}

class _ContractCreationDialogState extends State<_ContractCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _primeController = TextEditingController();
  final _franchiseController = TextEditingController(text: '200');
  
  String _selectedFrequency = 'annuel';
  String _selectedType = 'responsabilite_civile';
  List<String> _selectedGaranties = ['responsabilite_civile'];
  bool _isCreating = false;

  final List<String> _frequencies = ['mensuel', 'trimestriel', 'annuel'];
  final List<String> _contractTypes = [
    'responsabilite_civile',
    'tiers_complet',
    'tous_risques',
  ];
  final List<String> _garantiesDisponibles = [
    'responsabilite_civile',
    'dommages_collision',
    'vol',
    'incendie',
    'bris_de_glace',
    'catastrophes_naturelles',
    'assistance_depannage',
  ];

  @override
  Widget build(BuildContext context) {
    final vehicleData = widget.demande['vehicleData'] as Map<String, dynamic>;
    final conducteurData = widget.demande['conducteurData'] as Map<String, dynamic>;

    return AlertDialog(
      title: const Text('Créer le contrat d\'assurance'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé de la demande
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pour: ${conducteurData['prenom']} ${conducteurData['nom']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Véhicule: ${vehicleData['marque']} ${vehicleData['modele']}'),
                      Text('Immatriculation: ${vehicleData['immatriculation']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Type de contrat
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de contrat',
                    border: OutlineInputBorder(),
                  ),
                  items: _contractTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getContractTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (mounted) setState(() {
                      _selectedType = value!;
                      _updateGarantiesForType(value);
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Prime et fréquence
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _primeController,
                        decoration: const InputDecoration(
                          labelText: 'Prime (DT)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Requis';
                          if (double.tryParse(value!) == null) return 'Nombre invalide';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Fréquence',
                          border: OutlineInputBorder(),
                        ),
                        items: _frequencies.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(_getFrequencyLabel(freq)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedFrequency = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Franchise
                TextFormField(
                  controller: _franchiseController,
                  decoration: const InputDecoration(
                    labelText: 'Franchise (DT)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Garanties
                const Text(
                  'Garanties incluses:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _garantiesDisponibles.map((garantie) {
                    final isSelected = _selectedGaranties.contains(garantie);
                    return FilterChip(
                      label: Text(_getGarantieLabel(garantie)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedGaranties.add(garantie);
                          } else {
                            _selectedGaranties.remove(garantie);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createContract,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Créer contrat'),
        ),
      ],
    );
  }

  void _updateGarantiesForType(String type) {
    switch (type) {
      case 'responsabilite_civile':
        _selectedGaranties = ['responsabilite_civile'];
        break;
      case 'tiers_complet':
        _selectedGaranties = ['responsabilite_civile', 'dommages_collision', 'vol', 'incendie'];
        break;
      case 'tous_risques':
        _selectedGaranties = _garantiesDisponibles;
        break;
    }
  }

  String _getContractTypeLabel(String type) {
    switch (type) {
      case 'responsabilite_civile':
        return 'Responsabilité Civile';
      case 'tiers_complet':
        return 'Tiers Complet';
      case 'tous_risques':
        return 'Tous Risques';
      default:
        return type;
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'mensuel':
        return 'Mensuel';
      case 'trimestriel':
        return 'Trimestriel';
      case 'annuel':
        return 'Annuel';
      default:
        return frequency;
    }
  }

  String _getGarantieLabel(String garantie) {
    switch (garantie) {
      case 'responsabilite_civile':
        return 'RC';
      case 'dommages_collision':
        return 'Collision';
      case 'vol':
        return 'Vol';
      case 'incendie':
        return 'Incendie';
      case 'bris_de_glace':
        return 'Bris de glace';
      case 'catastrophes_naturelles':
        return 'Catastrophes';
      case 'assistance_depannage':
        return 'Assistance';
      default:
        return garantie;
    }
  }

  Future<void> _createContract() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw const AuthException('Agent non connecté');

      final primeAmount = double.parse(_primeController.text);
      final franchise = double.parse(_franchiseController.text);

      final contractDetails = {
        'type': _selectedType,
        'primeAmount': primeAmount,
        'paymentFrequency': _selectedFrequency,
        'franchise': franchise,
        'garanties': _selectedGaranties,
        'createdByAgent': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final result = await CompleteInsuranceWorkflowService.createContractByAgent(
        requestId: widget.demande['id'],
        agentId: user.uid,
        contractDetails: contractDetails,
        primeAmount: primeAmount,
        paymentFrequency: _selectedFrequency,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Contrat créé! Référence: ${result['paymentReference']['reference']}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onContractCreated();
      }
    } catch (e) {
      LoggingService.error('NouvellesDemandesScreen', '❌ Erreur création contrat', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

