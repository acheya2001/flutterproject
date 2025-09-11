import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/collaborative_data_sync_service.dart';

/// 🎨 Écran de validation du croquis collaboratif
class CollaborativeSketchValidationScreen extends StatefulWidget {
  final CollaborativeSession session;

  const CollaborativeSketchValidationScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<CollaborativeSketchValidationScreen> createState() => _CollaborativeSketchValidationScreenState();
}

class _CollaborativeSketchValidationScreenState extends State<CollaborativeSketchValidationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _commentaireController = TextEditingController();
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Validation du Croquis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[600]!, Colors.purple[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: CollaborativeDataSyncService.streamCroquis(widget.session.id),
          builder: (context, croquisSnapshot) {
            return StreamBuilder<CollaborativeSession?>(
              stream: CollaborativeDataSyncService.streamSession(widget.session.id),
              builder: (context, sessionSnapshot) {
                if (croquisSnapshot.connectionState == ConnectionState.waiting ||
                    sessionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final croquis = croquisSnapshot.data;
                final session = sessionSnapshot.data;

                if (croquis == null) {
                  return _buildNoCroquisView();
                }

                if (session == null) {
                  return const Center(child: Text('Session non trouvée'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du croquis
                      _buildCroquisInfo(croquis),
                      
                      const SizedBox(height: 24),
                      
                      // Aperçu du croquis
                      _buildCroquisPreview(croquis),
                      
                      const SizedBox(height: 24),
                      
                      // Validations des participants
                      _buildValidationsParticipants(session),
                      
                      const SizedBox(height: 24),
                      
                      // Actions de validation
                      if (_currentUserId != null && !_aDejaValide(session))
                        _buildValidationActions(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 🚫 Vue quand aucun croquis n'existe
  Widget _buildNoCroquisView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.draw_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun croquis disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le créateur doit d\'abord dessiner le croquis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// ℹ️ Informations du croquis
  Widget _buildCroquisInfo(Map<String, dynamic> croquis) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.purple[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Informations du Croquis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoRow('Créé par', _getNomCreateur(croquis['creePar'])),
          _buildInfoRow('Date de création', _formatDate(croquis['dateModification'])),
          
          if (croquis['description'] != null && croquis['description'].isNotEmpty)
            _buildInfoRow('Description', croquis['description']),
        ],
      ),
    );
  }

  /// 🖼️ Aperçu du croquis
  Widget _buildCroquisPreview(Map<String, dynamic> croquis) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.draw,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Aperçu du Croquis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Zone d'aperçu du croquis
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aperçu du croquis',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intégration avec le système de dessin à venir',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Validations des participants
  Widget _buildValidationsParticipants(CollaborativeSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.how_to_vote,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Validations des Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...session.participants.map((participant) {
            return _buildParticipantValidation(participant);
          }).toList(),
        ],
      ),
    );
  }

  /// 👤 Validation d'un participant
  Widget _buildParticipantValidation(SessionParticipant participant) {
    // TODO: Récupérer le statut de validation depuis Firestore
    final aValide = false; // Placeholder
    final aAccepte = true; // Placeholder
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: aValide 
              ? (aAccepte ? Colors.green[300]! : Colors.red[300]!)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: aValide 
                  ? (aAccepte ? Colors.green[600] : Colors.red[600])
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                participant.roleVehicule,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${participant.prenom} ${participant.nom}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aValide 
                      ? (aAccepte ? 'Croquis accepté' : 'Croquis refusé')
                      : 'En attente de validation',
                  style: TextStyle(
                    fontSize: 14,
                    color: aValide 
                        ? (aAccepte ? Colors.green[600] : Colors.red[600])
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Icône de statut
          Icon(
            aValide 
                ? (aAccepte ? Icons.check_circle : Icons.cancel)
                : Icons.schedule,
            color: aValide 
                ? (aAccepte ? Colors.green[600] : Colors.red[600])
                : Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions de validation
  Widget _buildValidationActions() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre validation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Champ commentaire
          TextFormField(
            controller: _commentaireController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Commentaire (optionnel)',
              hintText: 'Ajoutez un commentaire sur le croquis...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Boutons de validation
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _validerCroquis(false),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Refuser',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _validerCroquis(true),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Accepter',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information
  Widget _buildInfoRow(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Obtenir le nom du créateur
  String _getNomCreateur(String? creePar) {
    if (creePar == null) return 'Inconnu';
    
    final createur = widget.session.participants.firstWhere(
      (p) => p.userId == creePar,
      orElse: () => SessionParticipant(
        userId: creePar,
        nom: 'Inconnu',
        prenom: '',
        email: '',
        telephone: '',
        roleVehicule: '?',
        type: ParticipantType.inscrit,
        statut: ParticipantStatus.en_attente,
        estCreateur: false,
      ),
    );
    
    return '${createur.prenom} ${createur.nom}';
  }

  /// 📅 Formater la date
  String _formatDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return date.toString();
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  /// ✅ Vérifier si l'utilisateur a déjà validé
  bool _aDejaValide(CollaborativeSession session) {
    // TODO: Implémenter la vérification depuis Firestore
    return false;
  }

  /// 🎯 Valider le croquis
  Future<void> _validerCroquis(bool accepte) async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await CollaborativeDataSyncService.validerCroquis(
        sessionId: widget.session.id,
        participantId: _currentUserId!,
        accepte: accepte,
        commentaire: _commentaireController.text.trim().isEmpty 
            ? null 
            : _commentaireController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepte ? 'Croquis accepté avec succès' : 'Croquis refusé',
            ),
            backgroundColor: accepte ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
      
    } catch (e) {
      print('❌ Erreur validation croquis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
