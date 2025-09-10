import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/user_profile_service.dart';
import '../../models/accident_session_complete.dart';
import 'modern_single_accident_info_screen.dart';

/// 🚗 Écran pour conducteur inscrit rejoignant une session
class RegisteredJoinSessionScreen extends StatefulWidget {
  final String sessionCode;

  const RegisteredJoinSessionScreen({
    super.key,
    required this.sessionCode,
  });

  @override
  State<RegisteredJoinSessionScreen> createState() => _RegisteredJoinSessionScreenState();
}

class _RegisteredJoinSessionScreenState extends State<RegisteredJoinSessionScreen> {
  bool _isLoading = false;
  AccidentSessionComplete? _session;
  Map<String, dynamic>? _userProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadSessionAndProfile();
    });
  }

  /// 📋 Charger la session et le profil utilisateur
  Future<void> _loadSessionAndProfile() async {
    if (mounted) setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger le profil utilisateur
      _userProfile = await UserProfileService.getCurrentUserProfile();
      if (_userProfile == null) {
        throw Exception('Impossible de récupérer votre profil utilisateur');
      }

      // Chercher la session
      final querySnapshot = await FirebaseFirestore.instance
          .collection('accident_sessions_complete')
          .where('codeSession', isEqualTo: widget.sessionCode)
          .where('statut', whereIn: ['creation', 'en_attente', 'en_cours'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Session non trouvée ou expirée');
      }

      final doc = querySnapshot.docs.first;
      _session = AccidentSessionComplete.fromMap(doc.data(), doc.id);

      if (mounted) setState(() {
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 🔍 Vérifier si l'utilisateur a déjà rejoint la session
  bool _utilisateurDejaRejoint() {
    if (_session == null) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    return _session!.conducteurs.any((c) => c.userId == user.uid);
  }

  /// 🔗 Rejoindre la session
  Future<void> _rejoindreSession() async {
    if (_session == null || _userProfile == null) return;

    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      final updatedSession = await AccidentSessionCompleteService.rejoindreSession(
        codeSession: widget.sessionCode,
        nomConducteur: _userProfile!['nom'] ?? '',
        prenomConducteur: _userProfile!['prenom'] ?? '',
        emailConducteur: _userProfile!['email'] ?? '',
        telephoneConducteur: _userProfile!['telephone'] ?? '',
      );

      if (mounted) {
        // Naviguer vers le formulaire de constat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModernSingleAccidentInfoScreen(
              typeAccident: 'Collision entre deux véhicules',
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rejoindre une session'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _session != null
                  ? _buildSessionInfo()
                  : const Center(child: Text('Chargement...')),
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Informations de la session
  Widget _buildSessionInfo() {
    final createur = _session!.conducteurs.firstWhere(
      (c) => c.estCreateur,
      orElse: () => _session!.conducteurs.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de session
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue[600], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session ${widget.sessionCode}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _session!.typeAccident,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informations de la session
                  _buildInfoRow(Icons.person, 'Créé par', '${createur.prenom} ${createur.nom}'),
                  _buildInfoRow(Icons.directions_car, 'Véhicules', '${_session!.nombreVehicules}'),
                  _buildInfoRow(Icons.people, 'Participants', '${_session!.conducteurs.length}/${_session!.nombreVehicules}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Informations utilisateur
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle, color: Colors.green[600], size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Vos informations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(Icons.person, 'Nom', '${_userProfile!['prenom']} ${_userProfile!['nom']}'),
                  _buildInfoRow(Icons.email, 'Email', _userProfile!['email'] ?? ''),
                  _buildInfoRow(Icons.phone, 'Téléphone', _userProfile!['telephone'] ?? ''),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Message si déjà rejoint
          if (_utilisateurDejaRejoint())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vous avez déjà rejoint cette session',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          'Vous pouvez continuer à remplir le constat',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Bouton de connexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _rejoindreSession,
              icon: Icon(_utilisateurDejaRejoint() ? Icons.play_arrow : Icons.login),
              label: Text(_utilisateurDejaRejoint() ? 'Continuer la session' : 'Rejoindre la session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _utilisateurDejaRejoint() ? Colors.green[600] : Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Note informative
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'En tant que conducteur inscrit, vos informations personnelles et véhicules sont automatiquement récupérés. Vous pourrez consulter les informations communes de l\'accident et collaborer sur le croquis.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

