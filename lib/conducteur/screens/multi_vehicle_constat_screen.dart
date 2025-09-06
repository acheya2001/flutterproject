import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicule_model.dart';
import '../../models/accident_session.dart';
import '../../services/accident_session_service.dart';
import 'constat_section_screen.dart';
import 'invitation_management_screen.dart';

/// 🚗 Écran principal de constat multi-véhicules avec permissions strictes
class MultiVehicleConstatScreen extends StatefulWidget {
  final String sessionId;
  final String monRole; // 'A', 'B', 'C', etc.
  final VehiculeModel monVehicule;
  final int nombreVehicules;

  const MultiVehicleConstatScreen({
    super.key,
    required this.sessionId,
    required this.monRole,
    required this.monVehicule,
    required this.nombreVehicules,
  });

  @override
  State<MultiVehicleConstatScreen> createState() => _MultiVehicleConstatScreenState();
}

class _MultiVehicleConstatScreenState extends State<MultiVehicleConstatScreen> {
  AccidentSession? _session;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _chargerSession();
  }

  Future<void> _chargerSession() async {
    try {
      final session = await AccidentSessionService.obtenirSessionParId(widget.sessionId);
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Session introuvable'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Constat ${_session!.codePublic}'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          if (_estCreateur())
            IconButton(
              onPressed: _gererInvitations,
              icon: const Icon(Icons.group_add),
              tooltip: 'Gérer les invitations',
            ),
          IconButton(
            onPressed: _voirStatutGlobal,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Statut global',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec informations de session
          _buildSessionHeader(),
          
          // Liste des véhicules avec permissions
          Expanded(
            child: _buildVehiculesList(),
          ),
          
          // Actions en bas
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.car_crash, color: Colors.red[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${_session!.codePublic}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_session!.nombreParticipants} véhicules impliqués',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatutColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatutText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barre de progression
          LinearProgressIndicator(
            value: _calculerProgression(),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${(_calculerProgression() * 100).round()}% complété',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _session!.nombreParticipants,
      itemBuilder: (context, index) {
        final role = String.fromCharCode(65 + index); // A, B, C, D, E
        return _buildVehiculeCard(role);
      },
    );
  }

  Widget _buildVehiculeCard(String role) {
    final estMonVehicule = role == widget.monRole;
    final peutModifier = estMonVehicule;
    final estComplete = _estVehiculeComplete(role);
    final identite = _session!.identitesVehicules[role];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: estMonVehicule ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: estMonVehicule 
                ? Colors.red[600]! 
                : estComplete 
                    ? Colors.green[600]!
                    : Colors.grey[300]!,
            width: estMonVehicule ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => _ouvrirVehicule(role, peutModifier),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Badge du rôle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: estMonVehicule 
                            ? Colors.red[600] 
                            : estComplete 
                                ? Colors.green[600]
                                : Colors.grey[400],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          role,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Informations du véhicule
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estMonVehicule 
                                ? 'Véhicule $role (Vous)'
                                : 'Véhicule $role',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          if (identite != null)
                            Text(
                              '${identite.marque} ${identite.type}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            )
                          else
                            Text(
                              estMonVehicule 
                                  ? 'À compléter'
                                  : 'En attente du conducteur',
                              style: TextStyle(
                                fontSize: 14,
                                color: estMonVehicule ? Colors.orange[700] : Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Icônes de statut
                    Column(
                      children: [
                        if (estComplete)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 24,
                          )
                        else if (estMonVehicule)
                          Icon(
                            Icons.edit,
                            color: Colors.orange[600],
                            size: 24,
                          )
                        else
                          Icon(
                            Icons.hourglass_empty,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                        
                        const SizedBox(height: 4),
                        
                        if (peutModifier)
                          const Text(
                            'Modifier',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                            ),
                          )
                        else
                          const Text(
                            'Consulter',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                // Permissions et restrictions
                if (!estMonVehicule)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.orange[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Consultation uniquement - Modification interdite',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
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
      child: Row(
        children: [
          if (_estCreateur())
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _gererInvitations,
                icon: const Icon(Icons.group_add),
                label: const Text('Invitations'),
              ),
            ),
          
          if (_estCreateur()) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _peutFinaliser() ? _finaliserConstat : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Finaliser le Constat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  bool _estCreateur() {
    return _session?.createurUserId == _currentUserId;
  }

  bool _estVehiculeComplete(String role) {
    final identite = _session?.identitesVehicules[role];
    final signature = _session?.signatures[role];
    return identite != null && signature != null;
  }

  double _calculerProgression() {
    if (_session == null) return 0.0;

    int vehiculesCompletes = 0;
    for (int i = 0; i < _session!.nombreParticipants; i++) {
      final role = String.fromCharCode(65 + i);
      if (_estVehiculeComplete(role)) {
        vehiculesCompletes++;
      }
    }

    return vehiculesCompletes / _session!.nombreParticipants;
  }

  Color _getStatutColor() {
    switch (_session?.statut) {
      case AccidentSession.STATUT_BROUILLON:
        return Colors.orange[600]!;
      case 'en_cours':
        return Colors.blue[600]!;
      case AccidentSession.STATUT_SIGNE_VALIDE:
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStatutText() {
    switch (_session?.statut) {
      case AccidentSession.STATUT_BROUILLON:
        return 'Brouillon';
      case 'en_cours':
        return 'En cours';
      case AccidentSession.STATUT_SIGNE_VALIDE:
        return 'Finalisé';
      default:
        return 'Inconnu';
    }
  }

  bool _peutFinaliser() {
    if (_session == null) return false;
    return _calculerProgression() == 1.0 && _estCreateur();
  }

  // Actions
  void _ouvrirVehicule(String role, bool peutModifier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConstatSectionScreen(
          session: _session!,
          role: role,
          vehicule: role == widget.monRole ? widget.monVehicule : null,
        ),
      ),
    ).then((_) => _chargerSession()); // Recharger après modification
  }

  void _gererInvitations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvitationManagementScreen(
          session: _session!,
        ),
      ),
    );
  }

  void _voirStatutGlobal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statut Global du Constat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${_session!.codePublic}'),
            Text('Créé le: ${_session!.dateCreation.day}/${_session!.dateCreation.month}/${_session!.dateCreation.year}'),
            Text('Statut: ${_getStatutText()}'),
            Text('Progression: ${(_calculerProgression() * 100).round()}%'),
            const SizedBox(height: 16),
            const Text(
              'Véhicules:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...List.generate(_session!.nombreParticipants, (index) {
              final role = String.fromCharCode(65 + index);
              final complete = _estVehiculeComplete(role);
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Icon(
                      complete ? Icons.check_circle : Icons.hourglass_empty,
                      color: complete ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text('Véhicule $role: ${complete ? "Complété" : "En attente"}'),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _finaliserConstat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finaliser le Constat'),
        content: const Text(
          'Êtes-vous sûr de vouloir finaliser ce constat ?\n\n'
          'Une fois finalisé, aucune modification ne sera possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await AccidentSessionService.finaliserSession(widget.sessionId);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Constat finalisé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );

                _chargerSession();

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la finalisation: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Finaliser'),
          ),
        ],
      ),
    );
  }
}
