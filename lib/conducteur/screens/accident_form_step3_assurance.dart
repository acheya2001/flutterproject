import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/accident_session_complete.dart';
import '../../services/accident_session_complete_service.dart';
import 'accident_form_step4_circonstances.dart';

/// 🛡️ Étape 3 : Assurance et informations conducteur (selon constat papier)
class AccidentFormStep3Assurance extends StatefulWidget {
  final AccidentSessionComplete session;
  final Map<String, dynamic>? vehiculeSelectionne;

  const AccidentFormStep3Assurance({
    super.key,
    required this.session,
    this.vehiculeSelectionne,
  });

  @override
  State<AccidentFormStep3Assurance> createState() => _AccidentFormStep3AssuranceState();
}

class _AccidentFormStep3AssuranceState extends State<AccidentFormStep3Assurance>with TickerProviderStateMixin  {
  late TabController _tabController;
  bool _isLoading = false;
  String? _monRoleVehicule;
  
  // Données d'assurance et conducteur
  Map<String, AssuranceFormData> _assuranceData = {};

  // Compagnies d'assurance tunisiennes
  final List<String> _compagniesAssurance = [
    'STAR Assurances',
    'GAT Assurances',
    'BH Assurance',
    'CTAMA',
    'AMI Assurances',
    'MAGHREBIA',
    'LLOYD TUNISIEN',
    'CARTE',
    'ZITOUNA TAKAFUL',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _initialiserAssurance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final data in _assuranceData.values) {
      data.dispose();
    }
    super.dispose();
  }

  void _initialiserAssurance() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final conducteur = widget.session.conducteurs.firstWhere(
        (c) => c.userId == user.uid,
        orElse: () => widget.session.conducteurs.first,
      );
      _monRoleVehicule = conducteur.roleVehicule;
    }

    // Initialiser les données pour chaque véhicule
    for (final conducteur in widget.session.conducteurs) {
      _assuranceData[conducteur.roleVehicule] = AssuranceFormData();
    }

    // Pré-remplir avec les données existantes
    for (final vehicule in widget.session.vehicules) {
      if (_assuranceData.containsKey(vehicule.roleVehicule)) {
        _assuranceData[vehicule.roleVehicule]!.remplirDepuisVehicule(vehicule);
      }
    }

    _tabController = TabController(
      length: widget.session.conducteurs.length,
      vsync: this,
    );

    // Aller directement à l'onglet de l'utilisateur
    if (_monRoleVehicule != null) {
      final index = widget.session.conducteurs.indexWhere(
        (c) => c.roleVehicule == _monRoleVehicule,
      );
      if (index >= 0) {
        _tabController.index = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assurance & Conducteur',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.session.conducteurs.map((conducteur) {
            final estMonVehicule = conducteur.roleVehicule == _monRoleVehicule;
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: estMonVehicule ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Véhicule ${conducteur.roleVehicule}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (estMonVehicule) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, color: Colors.white, size: 16),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: _sauvegarder,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),

          // Informations d'assurance pré-remplies (si disponible)
          if (widget.vehiculeSelectionne != null) ...[
            _buildAssurancePreRemplie(),
          ],

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.session.conducteurs.map((conducteur) {
                return _buildAssuranceForm(conducteur);
              }).toList(),
            ),
          ),

          // Bouton suivant
          _buildBoutonSuivant(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Étape 3 sur 6',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Session: ${widget.session.codeSession}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 3 / 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildAssuranceForm(ConducteurSession conducteur) {
    final assuranceData = _assuranceData[conducteur.roleVehicule]!;
    final estMonVehicule = conducteur.roleVehicule == _monRoleVehicule;
    final peutModifier = estMonVehicule;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildVehiculeHeader(conducteur, estMonVehicule),
          
          const SizedBox(height: 24),
          
          // Informations d'assurance (simplifiées si pré-remplies)
          if (estMonVehicule && widget.vehiculeSelectionne != null) ...[
            _buildAssuranceSimplifiee(),
          ] else ...[
            _buildInfosAssurance(assuranceData, peutModifier),

            const SizedBox(height: 24),

            // Informations du conducteur (seulement si pas pré-remplies)
            _buildInfosConducteur(assuranceData, peutModifier),

            const SizedBox(height: 24),

            // Assuré (si différent du conducteur)
            _buildInfosAssure(assuranceData, peutModifier),
          ],
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVehiculeHeader(ConducteurSession conducteur, bool estMonVehicule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estMonVehicule 
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Icon(
                Icons.security,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assurance Véhicule ${conducteur.roleVehicule}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${conducteur.prenom} ${conducteur.nom}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                if (estMonVehicule)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'MON ASSURANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (!estMonVehicule)
            const Icon(
              Icons.lock,
              color: Colors.white,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildInfosAssurance(AssuranceFormData assuranceData, bool peutModifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations d\'assurance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Société d'assurance
            DropdownButtonFormField<String>(
              value: assuranceData.societeAssurance.isEmpty ? null : assuranceData.societeAssurance,
              decoration: const InputDecoration(
                labelText: 'Société d\'assurance *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _compagniesAssurance.map((compagnie) {
                return DropdownMenuItem(
                  value: compagnie,
                  child: Text(compagnie),
                );
              }).toList(),
              onChanged: peutModifier ? (value) {
                if (mounted) setState(() {
                  assuranceData.societeAssurance = value ?? '';
                });
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Numéro de contrat et agence
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.numeroContratController,
                    decoration: const InputDecoration(
                      labelText: 'N° de contrat *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    enabled: peutModifier,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.agenceController,
                    decoration: const InputDecoration(
                      labelText: 'Agence',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    enabled: peutModifier,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Validité de l'assurance
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.validiteDebutController,
                    decoration: const InputDecoration(
                      labelText: 'Valable du *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: peutModifier ? () => _selectionnerDateDebut(assuranceData) : null,
                    enabled: peutModifier,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.validiteFinController,
                    decoration: const InputDecoration(
                      labelText: 'Au *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: peutModifier ? () => _selectionnerDateFin(assuranceData) : null,
                    enabled: peutModifier,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosConducteur(AssuranceFormData assuranceData, bool peutModifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du conducteur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nom et prénom
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.nomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: peutModifier,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.prenomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      border: OutlineInputBorder(),
                    ),
                    enabled: peutModifier,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Adresse
            TextFormField(
              controller: assuranceData.adresseConducteurController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              enabled: peutModifier,
            ),
            
            const SizedBox(height: 16),
            
            // Permis de conduire
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.numeroPermisController,
                    decoration: const InputDecoration(
                      labelText: 'N° permis *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    enabled: peutModifier,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: assuranceData.categoriePermisController,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                      hintText: 'B, A, C...',
                    ),
                    enabled: peutModifier,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Date de délivrance du permis
            TextFormField(
              controller: assuranceData.dateDelivrancePermisController,
              decoration: const InputDecoration(
                labelText: 'Date de délivrance *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: peutModifier ? () => _selectionnerDatePermis(assuranceData) : null,
              enabled: peutModifier,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosAssure(AssuranceFormData assuranceData, bool peutModifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assuré (si différent du conducteur)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: assuranceData.assureDifferent,
                  onChanged: peutModifier ? (value) {
                    if (mounted) setState(() {
                      assuranceData.assureDifferent = value;
                    });
                  } : null,
                ),
              ],
            ),
            
            if (assuranceData.assureDifferent) ...[
              const SizedBox(height: 16),
              
              // Nom et prénom de l'assuré
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: assuranceData.nomAssureController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'assuré *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      enabled: peutModifier,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: assuranceData.prenomAssureController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom de l\'assuré *',
                        border: OutlineInputBorder(),
                      ),
                      enabled: peutModifier,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Adresse de l'assuré
              TextFormField(
                controller: assuranceData.adresseAssureController,
                decoration: const InputDecoration(
                  labelText: 'Adresse de l\'assuré *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLines: 2,
                enabled: peutModifier,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonSuivant() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _continuer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suivant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
        ),
      ),
    );
  }

  void _selectionnerDateDebut(AssuranceFormData data) async {
    final date = await showDatePicker(
      context: context,
      initialDate: data.validiteDebut,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        data.validiteDebut = date;
        data.validiteDebutController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  void _selectionnerDateFin(AssuranceFormData data) async {
    final date = await showDatePicker(
      context: context,
      initialDate: data.validiteFin,
      firstDate: data.validiteDebut,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        data.validiteFin = date;
        data.validiteFinController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  void _selectionnerDatePermis(AssuranceFormData data) async {
    final date = await showDatePicker(
      context: context,
      initialDate: data.dateDelivrancePermis,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        data.dateDelivrancePermis = date;
        data.dateDelivrancePermisController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  Future<void> _sauvegarder() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      // Sauvegarder seulement les données de l'utilisateur actuel
      if (_monRoleVehicule != null) {
        final assuranceData = _assuranceData[_monRoleVehicule]!;
        final vehicule = assuranceData.versVehiculeAccident(_monRoleVehicule!);
        
        await AccidentSessionCompleteService.mettreAJourVehicule(
          widget.session.id,
          vehicule,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informations d\'assurance sauvegardées'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  void _continuer() async {
    // Sauvegarder d'abord
    await _sauvegarder();

    if (mounted) {
      // Naviguer vers l'étape suivante
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentFormStep4Circonstances(
            session: widget.session,
          ),
        ),
      );
    }
  }

  Widget _buildAssurancePreRemplie() {
    if (widget.vehiculeSelectionne == null) return const SizedBox.shrink();

    final vehicule = widget.vehiculeSelectionne!['vehicule'];
    final estProprietaire = widget.vehiculeSelectionne!['estProprietaire'] as bool;
    final conducteur = widget.vehiculeSelectionne!['conducteur'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informations d\'assurance automatiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pré-rempli',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations d'assurance en grille
          Row(
            children: [
              Expanded(
                child: _buildInfoCardAssurance(
                  'Compagnie',
                  vehicule.compagnieAssurance ?? 'N/A',
                  Icons.business,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCardAssurance(
                  'N° Police',
                  vehicule.numeroPolice ?? 'N/A',
                  Icons.policy,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoCardAssurance(
                  'Agence',
                  vehicule.agenceNom ?? 'N/A',
                  Icons.location_city,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCardAssurance(
                  'Véhicule',
                  '${vehicule.marque} ${vehicule.modele}',
                  Icons.directions_car,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Note informative
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ces informations proviennent de votre véhicule sélectionné. L\'agence aura accès à toutes les données nécessaires.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardAssurance(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAssuranceSimplifiee() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informations d\'assurance confirmées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Toutes les informations nécessaires sont déjà disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  '• Informations d\'assurance : récupérées depuis votre véhicule\n'
                  '• Informations conducteur : disponibles dans votre profil\n'
                  '• Données véhicule : confirmées lors de la sélection\n'
                  '• L\'agence aura accès à toutes les données nécessaires',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green[600], size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Vous pouvez passer à l\'étape suivante',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 📝 Classe pour gérer les données du formulaire d'assurance
class AssuranceFormData {
  // Assurance
  String societeAssurance = '';
  final TextEditingController numeroContratController = TextEditingController();
  final TextEditingController agenceController = TextEditingController();
  final TextEditingController validiteDebutController = TextEditingController();
  final TextEditingController validiteFinController = TextEditingController();
  DateTime validiteDebut = DateTime.now();
  DateTime validiteFin = DateTime.now().add(const Duration(days: 365));

  // Conducteur
  final TextEditingController nomConducteurController = TextEditingController();
  final TextEditingController prenomConducteurController = TextEditingController();
  final TextEditingController adresseConducteurController = TextEditingController();
  final TextEditingController numeroPermisController = TextEditingController();
  final TextEditingController categoriePermisController = TextEditingController();
  final TextEditingController dateDelivrancePermisController = TextEditingController();
  DateTime dateDelivrancePermis = DateTime.now().subtract(const Duration(days: 365));

  // Assuré (si différent)
  bool assureDifferent = false;
  final TextEditingController nomAssureController = TextEditingController();
  final TextEditingController prenomAssureController = TextEditingController();
  final TextEditingController adresseAssureController = TextEditingController();

  void remplirDepuisVehicule(VehiculeAccident vehicule) {
    societeAssurance = vehicule.societeAssurance;
    numeroContratController.text = vehicule.numeroContrat;
    agenceController.text = vehicule.agence;
    validiteDebut = vehicule.validiteAssuranceDebut;
    validiteFin = vehicule.validiteAssuranceFin;
    validiteDebutController.text = '${validiteDebut.day}/${validiteDebut.month}/${validiteDebut.year}';
    validiteFinController.text = '${validiteFin.day}/${validiteFin.month}/${validiteFin.year}';
    
    nomConducteurController.text = vehicule.nomConducteur;
    prenomConducteurController.text = vehicule.prenomConducteur;
    adresseConducteurController.text = vehicule.adresseConducteur;
    numeroPermisController.text = vehicule.numeroPermis;
    categoriePermisController.text = vehicule.categoriePermis;
    dateDelivrancePermis = vehicule.dateDelivrancePermis;
    dateDelivrancePermisController.text = '${dateDelivrancePermis.day}/${dateDelivrancePermis.month}/${dateDelivrancePermis.year}';
    
    assureDifferent = vehicule.assureDifferent;
    nomAssureController.text = vehicule.nomAssure;
    prenomAssureController.text = vehicule.prenomAssure;
    adresseAssureController.text = vehicule.adresseAssure;
  }

  VehiculeAccident versVehiculeAccident(String roleVehicule) {
    final user = FirebaseAuth.instance.currentUser;
    
    return VehiculeAccident(
      roleVehicule: roleVehicule,
      conducteurId: user?.uid ?? '',
      
      // Infos véhicule (seront récupérées de l'étape précédente)
      marque: '',
      modele: '',
      immatriculation: '',
      sensCirculation: '',
      pointChocInitial: '',
      degatsApparents: [],
      
      // Infos assurance
      societeAssurance: societeAssurance,
      numeroContrat: numeroContratController.text.trim(),
      agence: agenceController.text.trim(),
      validiteAssuranceDebut: validiteDebut,
      validiteAssuranceFin: validiteFin,
      
      // Infos conducteur
      nomConducteur: nomConducteurController.text.trim(),
      prenomConducteur: prenomConducteurController.text.trim(),
      adresseConducteur: adresseConducteurController.text.trim(),
      numeroPermis: numeroPermisController.text.trim(),
      dateDelivrancePermis: dateDelivrancePermis,
      categoriePermis: categoriePermisController.text.trim(),
      
      // Infos assuré
      assureDifferent: assureDifferent,
      nomAssure: nomAssureController.text.trim(),
      prenomAssure: prenomAssureController.text.trim(),
      adresseAssure: adresseAssureController.text.trim(),
    );
  }

  void dispose() {
    numeroContratController.dispose();
    agenceController.dispose();
    validiteDebutController.dispose();
    validiteFinController.dispose();
    nomConducteurController.dispose();
    prenomConducteurController.dispose();
    adresseConducteurController.dispose();
    numeroPermisController.dispose();
    categoriePermisController.dispose();
    dateDelivrancePermisController.dispose();
    nomAssureController.dispose();
    prenomAssureController.dispose();
    adresseAssureController.dispose();
  }
}

