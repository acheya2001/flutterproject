import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../models/accident_session_complete.dart';
import '../../models/collaborative_session_model.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/signature_debug_service.dart';

/// ✍️ Étape 6 : Signatures et finalisation (selon constat papier)
class AccidentFormStep6Signatures extends StatefulWidget {
  final dynamic session; // Peut être CollaborativeSession ou AccidentSessionComplete

  const AccidentFormStep6Signatures({
    super.key,
    required this.session,
  });

  @override
  State<AccidentFormStep6Signatures> createState() => _AccidentFormStep6SignaturesState();
}

class _AccidentFormStep6SignaturesState extends State<AccidentFormStep6Signatures>with TickerProviderStateMixin  {
  late TabController _tabController;
  bool _isLoading = false;
  String? _monRoleVehicule;
  
  // Contrôleurs de signature pour chaque véhicule
  Map<String, SignatureController> _signaturesControllers = {};
  Map<String, bool> _signaturesValidees = {};

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _initialiserSignatures();
    _chargerSignaturesExistantes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _signaturesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initialiserSignatures() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final participants = _getParticipants();
      final conducteur = participants.firstWhere(
        (c) => c.userId == user.uid,
        orElse: () => participants.first,
      );
      _monRoleVehicule = conducteur.roleVehicule;
    }

    // Initialiser les contrôleurs de signature
    for (final conducteur in _getParticipants()) {
      _signaturesControllers[conducteur.roleVehicule] = SignatureController(
        penStrokeWidth: 3,
        penColor: Colors.blue[800]!,
        exportBackgroundColor: Colors.white,
      );

      // Vérifier si la signature existe déjà
      if (widget.session is AccidentSessionComplete) {
        _signaturesValidees[conducteur.roleVehicule] =
            (widget.session as AccidentSessionComplete).signatures.containsKey(conducteur.roleVehicule);
      } else {
        _signaturesValidees[conducteur.roleVehicule] = false;
      }
    }

    _tabController = TabController(
      length: _getParticipants().length,
      vsync: this,
    );

    // Aller directement à l'onglet de l'utilisateur
    if (_monRoleVehicule != null) {
      final index = _getParticipants().indexWhere(
        (c) => c.roleVehicule == _monRoleVehicule,
      );
      if (index >= 0) {
        _tabController.index = index;
      }
    }
  }

  List<ConducteurSession> _getParticipants() {
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

  /// 📅 Obtenir la date d'accident selon le type de session
  DateTime _getDateAccident() {
    if (widget.session is AccidentSessionComplete) {
      return (widget.session as AccidentSessionComplete).infosGenerales.dateAccident;
    } else if (widget.session is CollaborativeSession) {
      // Pour les sessions collaboratives, utiliser une date par défaut ou récupérer depuis Firestore
      return DateTime.now(); // TODO: Récupérer depuis donneesCommunes
    }
    return DateTime.now();
  }

  /// 📍 Obtenir le lieu d'accident selon le type de session
  String _getLieuAccident() {
    if (widget.session is AccidentSessionComplete) {
      return (widget.session as AccidentSessionComplete).infosGenerales.lieuAccident;
    } else if (widget.session is CollaborativeSession) {
      // Pour les sessions collaboratives, utiliser une valeur par défaut ou récupérer depuis Firestore
      return 'Lieu non spécifié'; // TODO: Récupérer depuis donneesCommunes
    }
    return 'Lieu non spécifié';
  }

  /// 🚑 Obtenir l'information sur les blessés selon le type de session
  bool _getBlesses() {
    if (widget.session is AccidentSessionComplete) {
      return (widget.session as AccidentSessionComplete).infosGenerales.blesses;
    } else if (widget.session is CollaborativeSession) {
      // Pour les sessions collaboratives, utiliser une valeur par défaut ou récupérer depuis Firestore
      return false; // TODO: Récupérer depuis donneesCommunes
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Signatures',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        actions: [
          // Bouton de débogage temporaire
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              await SignatureDebugService.debugSignatures(widget.session.id);
              await SignatureDebugService.testAjoutSignature(widget.session.id);
            },
            tooltip: 'Debug Signatures',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _getParticipants().map((conducteur) {
            final estMonVehicule = conducteur.roleVehicule == _monRoleVehicule;
            final estSigne = _signaturesValidees[conducteur.roleVehicule] ?? false;
            
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      estSigne ? Icons.check_circle : Icons.pending,
                      color: estSigne ? Colors.green[200] : Colors.orange[200],
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _getParticipants().map((conducteur) {
                return _buildSignatureForm(conducteur);
              }).toList(),
            ),
          ),
          
          // Bouton finaliser
          _buildBoutonFinaliser(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final nbSignatures = _signaturesValidees.values.where((v) => v).length;
    final totalSignatures = _getParticipants().length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.green[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Étape 6 sur 6 - Finalisation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Signatures: $nbSignatures/$totalSignatures',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: nbSignatures / totalSignatures,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureForm(ConducteurSession conducteur) {
    final estMonVehicule = conducteur.roleVehicule == _monRoleVehicule;
    final peutSigner = estMonVehicule;
    final estSigne = _signaturesValidees[conducteur.roleVehicule] ?? false;
    final controller = _signaturesControllers[conducteur.roleVehicule]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du véhicule
          _buildVehiculeHeader(conducteur, estMonVehicule, estSigne),
          
          const SizedBox(height: 24),
          
          // Résumé du constat
          _buildResumeConstat(),
          
          const SizedBox(height: 24),
          
          // Zone de signature
          _buildZoneSignature(conducteur, controller, peutSigner, estSigne),
          
          const SizedBox(height: 24),
          
          // Déclaration de conformité
          if (peutSigner && !estSigne)
            _buildDeclarationConformite(conducteur),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVehiculeHeader(ConducteurSession conducteur, bool estMonVehicule, bool estSigne) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estSigne
              ? [Colors.green[400]!, Colors.green[600]!]
              : estMonVehicule 
                  ? [Colors.blue[400]!, Colors.blue[600]!]
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
              child: Icon(
                estSigne ? Icons.check_circle : Icons.edit,
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
                  'Signature Véhicule ${conducteur.roleVehicule}',
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
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    estSigne ? 'SIGNÉ' : estMonVehicule ? 'À SIGNER' : 'EN ATTENTE',
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
        ],
      ),
    );
  }

  Widget _buildResumeConstat() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé du constat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildResumeRow('Type d\'accident', widget.session.typeAccident),
            _buildResumeRow('Nombre de véhicules', '${widget.session.nombreVehicules}'),
            _buildResumeRow('Date', _formatDate(_getDateAccident())),
            _buildResumeRow('Lieu', _getLieuAccident()),
            _buildResumeRow('Blessés', _getBlesses() ? 'Oui' : 'Non'),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Vérifiez attentivement toutes les informations avant de signer.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSignature(ConducteurSession conducteur, SignatureController controller, bool peutSigner, bool estSigne) {
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
                    'Signature numérique',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (peutSigner && !estSigne)
                  TextButton.icon(
                    onPressed: () => controller.clear(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Effacer'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: estSigne ? Colors.grey[100] : Colors.white,
              ),
              child: estSigne
                  ? _buildSignatureExistante(conducteur.roleVehicule)
                  : peutSigner
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Signature(
                            controller: controller,
                            backgroundColor: Colors.white,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.grey,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'En attente de signature',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            
            if (peutSigner && !estSigne) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _validerSignature(conducteur.roleVehicule, controller),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider ma signature'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeclarationConformite(ConducteurSession conducteur) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Déclaration de conformité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'En signant ce constat, je déclare que :\n'
              '• Les informations fournies sont exactes et complètes\n'
              '• J\'ai pris connaissance de toutes les circonstances déclarées\n'
              '• Le croquis représente fidèlement la situation de l\'accident\n'
              '• Je m\'engage à respecter les suites données à ce constat',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonFinaliser() {
    final toutesSignaturesValidees = _signaturesValidees.values.every((v) => v);
    
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
      child: Column(
        children: [
          if (!toutesSignaturesValidees)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'En attente de toutes les signatures pour finaliser le constat.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: toutesSignaturesValidees && !_isLoading ? _finaliserConstat : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: toutesSignaturesValidees ? Colors.green[600] : Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle),
                        const SizedBox(width: 8),
                        Text(
                          toutesSignaturesValidees 
                              ? 'Finaliser le constat'
                              : 'En attente des signatures...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// 📥 Charger les signatures existantes depuis Firebase
  Future<void> _chargerSignaturesExistantes() async {
    try {
      if (widget.session is CollaborativeSession) {
        // Charger depuis la session collaborative
        final signatures = await CollaborativeSessionService.obtenirToutesLesSignatures(widget.session.id);

        for (final signatureData in signatures) {
          final roleVehicule = signatureData['roleVehicule'] as String?;
          final signatureBase64 = signatureData['signatureBase64'] as String?;

          if (roleVehicule != null && signatureBase64 != null) {
            // Marquer comme validée
            if (mounted) setState(() {
              _signaturesValidees[roleVehicule] = true;
            });

            // Charger l'image de signature dans le contrôleur
            try {
              final signatureBytes = base64Decode(signatureBase64);
              final controller = _signaturesControllers[roleVehicule];
              if (controller != null) {
                // Note: SignatureController ne permet pas de charger une image existante
                // On marque juste comme validée pour l'instant
                print('✅ Signature chargée pour $roleVehicule');
              }
            } catch (e) {
              print('❌ Erreur chargement signature $roleVehicule: $e');
            }
          }
        }
      } else if (widget.session is AccidentSessionComplete) {
        // Charger depuis la session complète
        final session = widget.session as AccidentSessionComplete;
        for (final entry in session.signatures.entries) {
          if (mounted) setState(() {
            _signaturesValidees[entry.key] = true;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur chargement signatures: $e');
    }
  }

  /// 🖼️ Construire l'affichage d'une signature existante
  Widget _buildSignatureExistante(String roleVehicule) {
    return FutureBuilder<String?>(
      future: _obtenirSignatureBase64(roleVehicule),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          try {
            final signatureBytes = base64Decode(snapshot.data!);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green[50],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      signatureBytes,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Signature validée',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: () => _modifierSignature(roleVehicule),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            );
          } catch (e) {
            print('❌ Erreur décodage signature: $e');
          }
        }

        // Fallback si pas de signature ou erreur
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 8),
              Text(
                'Signature validée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📥 Obtenir la signature en base64 depuis Firebase
  Future<String?> _obtenirSignatureBase64(String roleVehicule) async {
    try {
      if (widget.session is CollaborativeSession) {
        final signatures = await CollaborativeSessionService.obtenirToutesLesSignatures(widget.session.id);
        final signature = signatures.firstWhere(
          (s) => s['roleVehicule'] == roleVehicule,
          orElse: () => <String, dynamic>{},
        );
        return signature['signatureBase64'] as String?;
      } else if (widget.session is AccidentSessionComplete) {
        final session = widget.session as AccidentSessionComplete;
        return session.signatures[roleVehicule];
      }
    } catch (e) {
      print('❌ Erreur obtention signature: $e');
    }
    return null;
  }

  /// ✏️ Modifier une signature existante
  void _modifierSignature(String roleVehicule) {
    if (mounted) setState(() {
      _signaturesValidees[roleVehicule] = false;
    });

    // Effacer le contrôleur de signature
    final controller = _signaturesControllers[roleVehicule];
    if (controller != null) {
      controller.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vous pouvez maintenant modifier votre signature'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _validerSignature(String roleVehicule, SignatureController controller) async {
    if (controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de valider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      print('🔄 [UI] Début validation signature pour rôle: $roleVehicule');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      print('✅ [UI] Utilisateur connecté: ${user.uid}');

      // Convertir la signature en base64
      final signature = await controller.toPngBytes();
      if (signature == null) throw Exception('Impossible de convertir la signature');

      final signatureBase64 = base64Encode(signature);
      print('✅ [UI] Signature convertie en base64 (${signatureBase64.length} caractères)');

      // Sauvegarder la signature selon le type de session
      print('🔄 [UI] Type de session: ${widget.session.runtimeType}');
      print('🔄 [UI] Session ID: ${widget.session.id}');

      if (widget.session is CollaborativeSession) {
        print('🔄 [UI] Appel CollaborativeSessionService.ajouterSignature...');
        await CollaborativeSessionService.ajouterSignature(
          sessionId: widget.session.id,
          userId: user.uid,
          signatureBase64: signatureBase64,
          roleVehicule: roleVehicule,
        );
        print('✅ [UI] CollaborativeSessionService.ajouterSignature terminé');
      } else {
        print('🔄 [UI] Appel AccidentSessionCompleteService.ajouterSignature...');
        await AccidentSessionCompleteService.ajouterSignature(
          widget.session.id,
          roleVehicule,
          signatureBase64,
        );
        print('✅ [UI] AccidentSessionCompleteService.ajouterSignature terminé');
      }

      if (mounted) setState(() {
        _signaturesValidees[roleVehicule] = true;
      });

      print('✅ [UI] Signature validée avec succès pour $roleVehicule');

      // Déboguer les signatures après ajout
      await SignatureDebugService.debugSignatures(widget.session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature validée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [UI] Erreur validation signature: $e');
      print('❌ [UI] Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _finaliserConstat() async {
    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      // Le constat est automatiquement finalisé quand toutes les signatures sont ajoutées
      // Afficher un message de succès et naviguer vers l'écran de confirmation
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                const SizedBox(width: 12),
                const Text('Constat finalisé !'),
              ],
            ),
            content: const Text(
              'Le constat d\'accident a été finalisé avec succès. '
              'Toutes les parties ont signé et le document a été transmis aux assureurs.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Retourner à l'étape précédente avec un résultat positif
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: $e'),
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
}

