import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/conducteur_data_service.dart';
import 'session_dashboard_screen.dart';

/// 📋 Formulaire collaboratif pour conducteurs inscrits
class CollaborativeFormScreen extends StatefulWidget {
  final CollaborativeSession session;
  final bool isCreator;

  const CollaborativeFormScreen({
    super.key,
    required this.session,
    required this.isCreator,
  });

  @override
  State<CollaborativeFormScreen> createState() => _CollaborativeFormScreenState();
}

class _CollaborativeFormScreenState extends State<CollaborativeFormScreen>with TickerProviderStateMixin  {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Contrôleurs pour les champs
  final _observationsController = TextEditingController();
  final _remarquesController = TextEditingController();
  
  // Variables d'état
  List<String> _circonstancesSelectionnees = [];
  List<String> _pointsChocSelectionnes = [];
  List<String> _degatsSelectionnes = [];
  
  // Données du conducteur
  Map<String, dynamic>? _donneesConducteur;
  bool _donneesChargees = false;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _chargerDonneesConducteur();
    _animationController.forward();
    });
  }

  @override
  void dispose() {
    _observationsController.dispose();
    _remarquesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[600]!,
              Colors.blue[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContenu(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionDashboardScreen(session: widget.session),
                ),
              ),
              icon: const Icon(Icons.dashboard, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formulaire collaboratif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Session: ${widget.session.codeSession}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isCreator ? Colors.orange[600] : Colors.green[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.isCreator ? 'Créateur' : 'Participant',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    if (!_donneesChargees) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Informations auto-remplies
            _buildSectionInfosAuto(),
            
            const SizedBox(height: 24),
            
            // Circonstances
            _buildSectionCirconstances(),
            
            const SizedBox(height: 24),
            
            // Points de choc
            _buildSectionPointsChoc(),
            
            const SizedBox(height: 24),
            
            // Dégâts apparents
            _buildSectionDegats(),
            
            const SizedBox(height: 24),
            
            // Observations
            _buildSectionObservations(),
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            _buildBoutonsAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionInfosAuto() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle, color: Colors.green[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informations pré-remplies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_donneesConducteur != null) ...[
            _buildInfoRow('👤 Conducteur', '${_donneesConducteur!['prenom']} ${_donneesConducteur!['nom']}'),
            _buildInfoRow('📞 Téléphone', _donneesConducteur!['telephone'] ?? 'Non renseigné'),
            _buildInfoRow('🚗 Véhicule', '${_donneesConducteur!['marque']} ${_donneesConducteur!['modele']}'),
            _buildInfoRow('🔢 Immatriculation', _donneesConducteur!['immatriculation'] ?? 'Non renseigné'),
            _buildInfoRow('🏢 Assurance', _donneesConducteur!['compagnie'] ?? 'Non renseigné'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCirconstances() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.list_alt, color: Colors.blue[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Circonstances de l\'accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Liste des circonstances
          ..._obtenirCirconstances().map((circonstance) => CheckboxListTile(
            title: Text(
              circonstance,
              style: const TextStyle(fontSize: 14),
            ),
            value: _circonstancesSelectionnees.contains(circonstance),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _circonstancesSelectionnees.add(circonstance);
                } else {
                  _circonstancesSelectionnees.remove(circonstance);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          )),
        ],
      ),
    );
  }

  Widget _buildSectionPointsChoc() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.my_location, color: Colors.orange[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Points de choc initial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Grille des points de choc
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: _obtenirPointsChoc().map((point) {
              final isSelected = _pointsChocSelectionnes.contains(point);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _pointsChocSelectionnes.remove(point);
                    } else {
                      _pointsChocSelectionnes.add(point);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.orange[800] : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDegats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.build, color: Colors.red[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Dégâts apparents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Liste des dégâts
          ..._obtenirDegats().map((degat) => CheckboxListTile(
            title: Text(
              degat,
              style: const TextStyle(fontSize: 14),
            ),
            value: _degatsSelectionnes.contains(degat),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _degatsSelectionnes.add(degat);
                } else {
                  _degatsSelectionnes.remove(degat);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          )),
        ],
      ),
    );
  }

  Widget _buildSectionObservations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note_alt, color: Colors.purple[800]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Observations personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _observationsController,
            decoration: const InputDecoration(
              labelText: 'Vos observations sur l\'accident',
              hintText: 'Décrivez ce qui s\'est passé selon vous...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _remarquesController,
            decoration: const InputDecoration(
              labelText: 'Remarques supplémentaires',
              hintText: 'Autres informations importantes...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 300,
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonsAction() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SessionDashboardScreen(session: widget.session),
              ),
            ),
            icon: const Icon(Icons.dashboard),
            label: const Text('Dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _sauvegarderFormulaire,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Sauvegarde...' : 'Sauvegarder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chargerDonneesConducteur() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final donnees = await ConducteurDataService.recupererDonneesConducteur();
        if (mounted) setState(() {
          _donneesConducteur = donnees;
          _donneesChargees = true;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement données conducteur: $e');
      setState(() => _donneesChargees = true);
    }
  }

  Future<void> _sauvegarderFormulaire() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Préparer les données du formulaire
      final donneesFormulaire = {
        'circonstances': _circonstancesSelectionnees,
        'pointsChoc': _pointsChocSelectionnes,
        'degatsApparents': _degatsSelectionnes,
        'observations': _observationsController.text.trim(),
        'remarques': _remarquesController.text.trim(),
        'donneesPersonnelles': _donneesConducteur,
        'dateModification': DateTime.now().toIso8601String(),
      };

      // Sauvegarder via le service collaboratif
      await CollaborativeSessionService.sauvegarderDonneesFormulaire(
        sessionId: widget.session.id,
        userId: user.uid,
        donneesFormulaire: donneesFormulaire,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Formulaire sauvegardé avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner au dashboard avec rechargement de la session
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionDashboardScreen(session: widget.session),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _obtenirCirconstances() {
    return [
      'Stationnait',
      'Quittait un stationnement',
      'Prenait un stationnement',
      'Sortait d\'un parking',
      'Entrait dans un parking',
      'Circulait',
      'Changeait de file',
      'Doublait',
      'Virait à droite',
      'Virait à gauche',
      'Reculait',
      'Empiétait sur une file réservée',
      'Venait de droite',
      'N\'avait pas observé le signal d\'arrêt',
    ];
  }

  List<String> _obtenirPointsChoc() {
    return [
      'Avant', 'Avant droit', 'Avant gauche',
      'Côté droit', 'Côté gauche', 'Arrière',
      'Arrière droit', 'Arrière gauche', 'Toit',
    ];
  }

  List<String> _obtenirDegats() {
    return [
      'Rayures légères',
      'Bosses',
      'Éclats de peinture',
      'Phare cassé',
      'Pare-chocs endommagé',
      'Portière enfoncée',
      'Vitre brisée',
      'Rétroviseur cassé',
      'Pneu crevé',
      'Jante voilée',
    ];
  }
}

