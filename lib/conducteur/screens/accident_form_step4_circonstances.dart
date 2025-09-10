import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/accident_session_complete.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/collaborative_session_service.dart';
import 'accident_form_step6_signatures.dart';

/// 📝 Étape 4 : Circonstances de l'accident (selon constat papier)
class AccidentFormStep4Circonstances extends StatefulWidget {
  final dynamic session; // Peut être CollaborativeSession ou AccidentSessionComplete

  const AccidentFormStep4Circonstances({
    super.key,
    required this.session,
  });

  @override
  State<AccidentFormStep4Circonstances> createState() => _AccidentFormStep4CirconstancesState();
}

class _AccidentFormStep4CirconstancesState extends State<AccidentFormStep4Circonstances>with TickerProviderStateMixin  {
  late TabController _tabController;
  bool _isLoading = false;
  String? _monRoleVehicule;
  
  // Circonstances selon le constat papier officiel tunisien
  final List<Map<String, dynamic>> _circonstancesOfficielles = [
    {
      'id': 'stationnait',
      'texte': 'stationnait',
      'icone': '🅿️',
      'description': 'Le véhicule était à l\'arrêt/stationné',
    },
    {
      'id': 'quittait_stationnement',
      'texte': 'quittait un stationnement',
      'icone': '🚗➡️',
      'description': 'Sortait d\'une place de parking',
    },
    {
      'id': 'prenait_stationnement',
      'texte': 'prenait un stationnement',
      'icone': '➡️🅿️',
      'description': 'Entrait dans une place de parking',
    },
    {
      'id': 'sortait_parking',
      'texte': 'sortait d\'un parking, lieu privé, chemin de terre',
      'icone': '🏢➡️',
      'description': 'Sortait d\'un parking ou lieu privé',
    },
    {
      'id': 'entrait_parking',
      'texte': 'entrait dans un parking, lieu privé, chemin de terre',
      'icone': '➡️🏢',
      'description': 'Entrait dans un parking ou lieu privé',
    },
    {
      'id': 'entrait_file',
      'texte': 'entrait dans une file de circulation',
      'icone': '🔄',
      'description': 'S\'insérait dans la circulation',
    },
    {
      'id': 'roulait',
      'texte': 'roulait',
      'icone': '🚗',
      'description': 'Circulait normalement',
    },
    {
      'id': 'roulait_meme_sens',
      'texte': 'roulait dans le même sens et sur la même file',
      'icone': '🚗🚗',
      'description': 'Même direction, même voie',
    },
    {
      'id': 'changeait_file',
      'texte': 'changeait de file',
      'icone': '↔️',
      'description': 'Changeait de voie de circulation',
    },
    {
      'id': 'doublait',
      'texte': 'doublait',
      'icone': '🚗💨',
      'description': 'Dépassait un autre véhicule',
    },
    {
      'id': 'virait_droite',
      'texte': 'virait à droite',
      'icone': '↗️',
      'description': 'Tournait vers la droite',
    },
    {
      'id': 'virait_gauche',
      'texte': 'virait à gauche',
      'icone': '↖️',
      'description': 'Tournait vers la gauche',
    },
    {
      'id': 'reculait',
      'texte': 'reculait',
      'icone': '⬅️',
      'description': 'Effectuait une marche arrière',
    },
    {
      'id': 'empietait_file',
      'texte': 'empiétait sur une file réservée à la circulation venant en sens inverse',
      'icone': '⚠️',
      'description': 'Roulait sur la voie opposée',
    },
    {
      'id': 'venait_droite',
      'texte': 'venait de droite (dans un carrefour)',
      'icone': '➡️🔄',
      'description': 'Arrivait par la droite au carrefour',
    },
    {
      'id': 'non_priorite',
      'texte': 'n\'avait pas observé un signal de priorité ou une signalisation',
      'icone': '🛑',
      'description': 'N\'a pas respecté stop, feu, priorité',
    },
  ];

  // Circonstances sélectionnées par véhicule
  Map<String, List<String>> _circonstancesSelectionnees = {};

  @override
  void initState() {
    super.initState();
    _initialiserCirconstances();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initialiserCirconstances() {
    final user = FirebaseAuth.instance.currentUser;

    if (widget.session is CollaborativeSession) {
      // Pour les sessions collaboratives
      final session = widget.session as CollaborativeSession;
      if (user != null) {
        final participant = session.participants.firstWhere(
          (p) => p.userId == user.uid,
          orElse: () => session.participants.first,
        );
        _monRoleVehicule = participant.roleVehicule;
      }

      // Initialiser les circonstances pour chaque participant
      for (final participant in session.participants) {
        _circonstancesSelectionnees[participant.roleVehicule] = [];
      }

      _tabController = TabController(
        length: session.participants.length,
        vsync: this,
      );

      // Aller directement à l'onglet de l'utilisateur
      if (_monRoleVehicule != null) {
        final index = session.participants.indexWhere(
          (p) => p.roleVehicule == _monRoleVehicule,
        );
        if (index >= 0) {
          _tabController.index = index;
        }
      }
    } else {
      // Pour les sessions AccidentSessionComplete (ancien système)
      final session = widget.session as AccidentSessionComplete;
      if (user != null) {
        final conducteur = session.conducteurs.firstWhere(
          (c) => c.userId == user.uid,
          orElse: () => session.conducteurs.first,
        );
        _monRoleVehicule = conducteur.roleVehicule;
      }

      // Initialiser les circonstances pour chaque véhicule
      for (final conducteur in session.conducteurs) {
        _circonstancesSelectionnees[conducteur.roleVehicule] = [];
      }

      // Pré-remplir avec les données existantes
      final circonstancesExistantes = session.circonstances.circonstancesParVehicule;
      for (final entry in circonstancesExistantes.entries) {
        _circonstancesSelectionnees[entry.key] = List.from(entry.value);
      }

      _tabController = TabController(
        length: session.conducteurs.length,
        vsync: this,
      );

      // Aller directement à l'onglet de l'utilisateur
      if (_monRoleVehicule != null) {
        final index = session.conducteurs.indexWhere(
          (c) => c.roleVehicule == _monRoleVehicule,
        );
        if (index >= 0) {
          _tabController.index = index;
        }
      }
    }
  }

  /// 🔄 Obtenir la liste des participants selon le type de session
  List<dynamic> _getParticipants() {
    if (widget.session is CollaborativeSession) {
      // Convertir SessionParticipant vers ConducteurSession
      final collaborativeSession = widget.session as CollaborativeSession;
      return collaborativeSession.participants.map((participant) {
        return ConducteurSession(
          userId: participant.userId,
          nom: participant.nom,
          prenom: participant.prenom,
          email: participant.email,
          telephone: participant.telephone,
          roleVehicule: participant.roleVehicule,
          estCreateur: participant.estCreateur,
          aRejoint: participant.statut == ParticipantStatus.rejoint,
          estInscrit: participant.type == ParticipantType.inscrit,
          dateRejoint: participant.dateRejoint,
        );
      }).toList();
    } else {
      return (widget.session as AccidentSessionComplete).conducteurs;
    }
  }

  /// 🔄 Obtenir le code de session selon le type
  String _getSessionCode() {
    if (widget.session is CollaborativeSession) {
      return (widget.session as CollaborativeSession).codeSession;
    } else {
      return (widget.session as AccidentSessionComplete).codeSession;
    }
  }

  /// 🔄 Obtenir le nom du participant selon le type
  String _getParticipantName(dynamic participant) {
    if (participant.prenom != null && participant.nom != null) {
      return '${participant.prenom} ${participant.nom}';
    } else if (participant.email != null) {
      return participant.email;
    } else {
      return 'Participant ${participant.roleVehicule}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Circonstances',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: _getParticipants().map((participant) {
            final estMonVehicule = participant.roleVehicule == _monRoleVehicule;
            final nbCirconstances = _circonstancesSelectionnees[participant.roleVehicule]?.length ?? 0;
            
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: estMonVehicule ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Véhicule ${participant.roleVehicule}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        if (estMonVehicule) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, color: Colors.white, size: 14),
                        ],
                      ],
                    ),
                    if (nbCirconstances > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$nbCirconstances',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
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
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _getParticipants().map((participant) {
                return _buildCirconstancesForm(participant);
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
                'Étape 4 sur 6',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Session: ${_getSessionCode()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 4 / 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildCirconstancesForm(dynamic participant) {
    final roleVehicule = participant.roleVehicule;
    final estMonVehicule = roleVehicule == _monRoleVehicule;
    final peutModifier = estMonVehicule;
    final circonstancesVehicule = _circonstancesSelectionnees[roleVehicule] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du véhicule
          _buildVehiculeHeader(participant, estMonVehicule),

          const SizedBox(height: 24),

          // Instructions
          _buildInstructions(peutModifier),

          const SizedBox(height: 24),

          // Liste des circonstances
          _buildListeCirconstances(roleVehicule, peutModifier),
          
          const SizedBox(height: 24),
          
          // Résumé des circonstances sélectionnées
          if (circonstancesVehicule.isNotEmpty)
            _buildResumeCirconstances(circonstancesVehicule),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVehiculeHeader(dynamic participant, bool estMonVehicule) {
    final roleVehicule = participant.roleVehicule;
    final nbCirconstances = _circonstancesSelectionnees[roleVehicule]?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estMonVehicule 
              ? [Colors.orange[400]!, Colors.orange[600]!]
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
            child: Center(
              child: Text(
                roleVehicule,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Circonstances Véhicule ${roleVehicule}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getParticipantName(participant),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$nbCirconstances CIRCONSTANCE${nbCirconstances > 1 ? 'S' : ''}',
                    style: const TextStyle(
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

  Widget _buildInstructions(bool peutModifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: peutModifier ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: peutModifier ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                peutModifier ? Icons.edit : Icons.visibility,
                color: peutModifier ? Colors.blue[600] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                peutModifier ? 'Sélectionnez vos circonstances' : 'Circonstances (lecture seule)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: peutModifier ? Colors.blue[600] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            peutModifier 
                ? 'Cochez toutes les circonstances qui correspondent à votre situation au moment de l\'accident.'
                : 'Vous pouvez consulter les circonstances de ce véhicule mais pas les modifier.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeCirconstances(String roleVehicule, bool peutModifier) {
    final circonstancesVehicule = _circonstancesSelectionnees[roleVehicule] ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Circonstances de l\'accident',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selon le constat officiel tunisien',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des circonstances
            ..._circonstancesOfficielles.map((circonstance) {
              final isSelected = circonstancesVehicule.contains(circonstance['id']);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: peutModifier ? () => _toggleCirconstance(roleVehicule, circonstance['id']) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.orange[50]
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.orange[300]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange[600] : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? Colors.orange[600]! : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Icône
                          Text(
                            circonstance['icone'],
                            style: const TextStyle(fontSize: 20),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Texte
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  circonstance['texte'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.orange[700] : Colors.black87,
                                  ),
                                ),
                                Text(
                                  circonstance['description'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeCirconstances(List<String> circonstances) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Circonstances sélectionnées',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...circonstances.map((id) {
              final circonstance = _circonstancesOfficielles.firstWhere(
                (c) => c['id'] == id,
                orElse: () => {'texte': id, 'icone': '•'},
              );
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      circonstance['icone'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        circonstance['texte'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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

  void _toggleCirconstance(String roleVehicule, String circonstanceId) {
    setState(() {
      final circonstances = _circonstancesSelectionnees[roleVehicule] ?? [];
      if (circonstances.contains(circonstanceId)) {
        circonstances.remove(circonstanceId);
      } else {
        circonstances.add(circonstanceId);
      }
      _circonstancesSelectionnees[roleVehicule] = circonstances;
    });
  }

  Future<void> _sauvegarder() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Sauvegarder seulement les circonstances de l'utilisateur actuel
      if (_monRoleVehicule != null) {
        final circonstances = _circonstancesSelectionnees[_monRoleVehicule] ?? [];

        // Vérifier si c'est une session collaborative
        if (widget.session is CollaborativeSession) {
          await CollaborativeSessionService.mettreAJourCirconstances(
            sessionId: widget.session.id,
            userId: user.uid,
            roleVehicule: _monRoleVehicule!,
            circonstances: circonstances,
          );
        } else {
          await AccidentSessionCompleteService.mettreAJourCirconstances(
            widget.session.id,
            _monRoleVehicule!,
            circonstances,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Circonstances sauvegardées'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur mise à jour circonstances: $e');
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
          builder: (context) => AccidentFormStep6Signatures(
            session: widget.session,
          ),
        ),
      );
    }
  }
}

