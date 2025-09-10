import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/conducteur_data_service.dart';
import 'modern_single_accident_info_screen.dart';

/// 🔗 Écran pour rejoindre une session collaborative (conducteurs inscrits)
class JoinCollaborativeSessionScreen extends StatefulWidget {
  const JoinCollaborativeSessionScreen({super.key});

  @override
  State<JoinCollaborativeSessionScreen> createState() => _JoinCollaborativeSessionScreenState();
}

class _JoinCollaborativeSessionScreenState extends State<JoinCollaborativeSessionScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  CollaborativeSession? _sessionTrouvee;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une Session'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.group_add, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Rejoindre un Constat Collaboratif',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saisissez le code de session partagé par le conducteur principal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Champ code de session
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code de Session',
                  hintText: 'Ex: ABC123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Code de session requis';
                  }
                  if (value.length < 6) {
                    return 'Code trop court';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      _sessionTrouvee = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Bouton rechercher
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _rechercherSession,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Recherche...' : 'Rechercher Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Informations de la session trouvée
              if (_sessionTrouvee != null) _buildSessionInfo(),

              const Spacer(),

              // Bouton rejoindre
              if (_sessionTrouvee != null)
                ElevatedButton.icon(
                  onPressed: _rejoindreSession,
                  icon: const Icon(Icons.login),
                  label: const Text('Rejoindre la Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Session Trouvée !',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Type d\'accident', _sessionTrouvee!.typeAccident),
          _buildInfoRow('Nombre de véhicules', '${_sessionTrouvee!.nombreVehicules}'),
          _buildInfoRow('Participants', '${_sessionTrouvee!.participants.length}/${_sessionTrouvee!.nombreVehicules}'),
          _buildInfoRow('Statut', _getStatutText(_sessionTrouvee!.statut)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatutText(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return 'En création';
      case SessionStatus.attente_participants:
        return 'En attente';
      case SessionStatus.en_cours:
        return 'En cours';
      default:
        return 'Actif';
    }
  }

  Future<void> _rechercherSession() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _sessionTrouvee = null;
      });
    }

    try {
      // Rechercher la session par code
      final sessions = await CollaborativeSessionService.getSessionsByCode(_codeController.text.trim().toUpperCase());
      
      if (sessions.isNotEmpty) {
        if (mounted) {
          setState(() {
            _sessionTrouvee = sessions.first;
          });
        }
      } else {
        _showErrorDialog('Session non trouvée avec ce code');
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la recherche: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejoindreSession() async {
    if (_sessionTrouvee == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Obtenir les données du conducteur
      final donneesUtilisateur = await ConducteurDataService.recupererDonneesConducteur();
      
      // Rejoindre la session
      final sessionMiseAJour = await CollaborativeSessionService.rejoindreSession(
        codeSession: _sessionTrouvee!.codeSession,
        nom: donneesUtilisateur?['nom'] ?? '',
        prenom: donneesUtilisateur?['prenom'] ?? '',
        email: donneesUtilisateur?['email'] ?? user.email ?? '',
        telephone: donneesUtilisateur?['telephone'] ?? '',
        type: ParticipantType.inscrit,
      );

      if (mounted && sessionMiseAJour != null) {
        // Déterminer le rôle du véhicule
        final monParticipant = sessionMiseAJour.participants.firstWhere(
          (p) => p.userId == user.uid,
        );

        // Naviguer vers le formulaire avec le bon rôle
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModernSingleAccidentInfoScreen(
              typeAccident: sessionMiseAJour.typeAccident,
              session: sessionMiseAJour,
              isCollaborative: true,
              roleVehicule: monParticipant.roleVehicule,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la connexion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

