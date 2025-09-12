import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/collaborative_session_model.dart';
import '../../widgets/modern_sketch_widget.dart';
import '../../services/collaborative_data_sync_service.dart';

/// 🎨 Écran de croquis collaboratif moderne
class ModernCollaborativeSketchScreen extends StatefulWidget {
  final CollaborativeSession session;
  final bool readOnly; // 🔒 Mode lecture seule pour les invités

  const ModernCollaborativeSketchScreen({
    super.key,
    required this.session,
    this.readOnly = false, // Par défaut, mode édition
  });

  @override
  State<ModernCollaborativeSketchScreen> createState() => _ModernCollaborativeSketchScreenState();
}

class _ModernCollaborativeSketchScreenState extends State<ModernCollaborativeSketchScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<SketchElement> _elementsCharges = [];
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialiser les animations immédiatement
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationsInitialized = true;

    // Démarrer les animations et charger les données après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _chargerCroquisExistant();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[600]!,
              Colors.red[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: _animationsInitialized
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Header moderne
                        _buildHeader(),

                        // Contenu principal
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: _buildContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header moderne
                    _buildHeader(),

                    // Contenu principal
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 🎨 Header avec informations de session
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Bouton retour et titre
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Croquis Collaboratif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Session: ${widget.session.codeSession}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge collaboratif
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_work, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Collaboratif',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Informations rapides
          Row(
            children: [
              _buildQuickInfo(
                Icons.people,
                '${widget.session.participants.length}',
                'Participants',
              ),
              const SizedBox(width: 20),
              _buildQuickInfo(
                Icons.palette,
                'Temps réel',
                'Synchronisation',
              ),
              const SizedBox(width: 20),
              _buildQuickInfo(
                Icons.touch_app,
                'Multi-outils',
                'Dessin avancé',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Contenu principal avec widget collaboratif
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Dessinez ensemble le croquis de l\'accident. Chaque conducteur a sa couleur.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Widget de croquis collaboratif
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Builder(
                  builder: (context) {
                    print('🎨 Construction ModernSketchWidget avec ${_elementsCharges.length} éléments');
                    return ModernSketchWidget(
                      key: ValueKey('sketch_${_elementsCharges.length}_${DateTime.now().millisecondsSinceEpoch}'),
                      width: double.infinity,
                      height: double.infinity,
                      onSketchChanged: widget.readOnly ? null : _onSketchChanged, // 🔒 Désactiver modification si readOnly
                      initialElements: _elementsCharges,
                      isReadOnly: widget.readOnly, // 🔒 Utiliser le paramètre readOnly
                    );
                  },
                ),
              ),
            ),
          ),

          // Boutons de validation pour les invités
          if (widget.readOnly) ...[
            const SizedBox(height: 20),
            _buildBoutonsValidation(),
          ],
        ],
      ),
    );
  }

  void _onSketchChanged(List<SketchElement> elements) {
    // Callback quand le croquis est modifié
    print('🎨 Croquis modifié: ${elements.length} éléments');

    // Sauvegarder automatiquement dans Firebase
    _sauvegarderCroquisDansFirebase(elements);
  }

  /// 🎨 Boutons de validation pour les invités
  Widget _buildBoutonsValidation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'Validez-vous ce croquis ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _validerCroquis(true),
                  icon: const Icon(Icons.check),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _validerCroquis(false),
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 Valider le croquis (accepter/refuser)
  Future<void> _validerCroquis(bool accepte) async {
    String? raison;

    // Si refusé, demander la raison
    if (!accepte) {
      raison = await _demanderRaison();
      if (raison == null) return; // Annulé
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await CollaborativeDataSyncService.validerCroquis(
        sessionId: widget.session.id,
        participantId: currentUser.uid,
        accepte: accepte,
        commentaire: raison,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accepte ? '✅ Croquis accepté' : '❌ Croquis refusé'),
            backgroundColor: accepte ? Colors.green : Colors.orange,
          ),
        );

        // Retourner au dashboard
        Navigator.pop(context);
      }

    } catch (e) {
      print('❌ Erreur validation croquis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la validation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📝 Demander la raison du refus
  Future<String?> _demanderRaison() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison du refus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pourquoi refusez-vous ce croquis ?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Expliquez la raison...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  /// 📥 Charger le croquis existant depuis Firebase
  Future<void> _chargerCroquisExistant() async {
    try {
      // Déterminer la collection selon le type de session
      String collection;
      if (widget.session is CollaborativeSession) {
        collection = 'sessions_collaboratives';
      } else {
        collection = 'accident_sessions';
      }

      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.session.id)
          .get();

      if (doc.exists && doc.data()?['croquis_data'] != null) {
        final croquisData = List<Map<String, dynamic>>.from(doc.data()!['croquis_data']);
        print('📥 Croquis chargé depuis Firebase ($collection): ${croquisData.length} éléments');

        // Convertir les données en SketchElement
        final elements = croquisData.map((data) => SketchElement.fromMap(data)).toList();

        // Appliquer les éléments au widget de dessin
        if (mounted) setState(() {
          _elementsCharges = elements;
        });

        // Forcer un redraw après un délai
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            if (mounted) setState(() {});
          }
        });

        if (croquisData.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📥 Croquis chargé (${croquisData.length} éléments)'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur chargement croquis: $e');
    }
  }

  /// 💾 Sauvegarder le croquis dans Firebase
  Future<void> _sauvegarderCroquisDansFirebase(List<SketchElement> elements) async {
    try {
      // Convertir les éléments du croquis en format JSON avec la nouvelle méthode
      final croquisData = elements.map((element) => element.toMap()).toList();

      // Déterminer la collection selon le type de session
      String collection;
      if (widget.session is CollaborativeSession) {
        collection = 'sessions_collaboratives';
      } else {
        collection = 'accident_sessions';
      }

      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.session.id)
          .update({
        'croquis_data': croquisData,
        'croquis_derniere_modification': DateTime.now().toIso8601String(),
        'croquis_modifie_par': FirebaseAuth.instance.currentUser?.uid,
      });

      print('✅ Croquis sauvegardé dans Firebase ($collection): ${elements.length} éléments');

      // Afficher confirmation à l'utilisateur (seulement si pas trop fréquent)
      if (elements.length % 5 == 0) { // Afficher confirmation tous les 5 éléments
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Croquis sauvegardé (${elements.length} éléments)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur sauvegarde croquis: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur sauvegarde: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

