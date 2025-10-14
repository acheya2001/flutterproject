import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../services/cloudinary_pdf_service.dart';
import '../../../services/complete_elegant_pdf_service.dart';

/// 🚨 Écran des sinistres pour un contrat spécifique
class SinistresContratScreen extends StatefulWidget {
  final String contratId;
  final String numeroContrat;
  final String nomAssure;
  final String vehicule;

  const SinistresContratScreen({
    Key? key,
    required this.contratId,
    required this.numeroContrat,
    required this.nomAssure,
    required this.vehicule,
  }) : super(key: key);

  @override
  State<SinistresContratScreen> createState() => _SinistresContratScreenState();
}

class _SinistresContratScreenState extends State<SinistresContratScreen> {
  List<Map<String, dynamic>> _constats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConstatsContrat();
  }

  /// 📥 Charger les constats pour ce contrat
  Future<void> _loadConstatsContrat() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('[CONSTATS] 🔍 Recherche constats pour contrat: ${widget.numeroContrat}');
      debugPrint('[CONSTATS] 🚗 Véhicule: ${widget.vehicule}');

      // Recherche principale dans sessions_collaboratives
      List<QueryDocumentSnapshot> allDocs = [];

      final sessionsQuery = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .where('statut', isEqualTo: 'finalise')
          .get();
      debugPrint('[CONSTATS] 📊 Sessions finalisées trouvées: ${sessionsQuery.docs.length}');

      for (final sessionDoc in sessionsQuery.docs) {
        final sessionData = sessionDoc.data();

        // Debug: afficher la structure complète de la session
        debugPrint('[CONSTATS] 📋 Session ${sessionDoc.id} structure:');
        sessionData.forEach((key, value) {
          if (value is List) {
            debugPrint('[CONSTATS]   $key: List(${value.length})');
          } else if (value is Map) {
            debugPrint('[CONSTATS]   $key: Map(${value.length})');
          } else {
            debugPrint('[CONSTATS]   $key: $value');
          }
        });

        // Essayer différents noms de champs pour les véhicules
        final vehicules = sessionData['vehicules'] as List<dynamic>? ??
                         sessionData['vehicles'] as List<dynamic>? ??
                         sessionData['voitures'] as List<dynamic>? ??
                         [];

        debugPrint('[CONSTATS] 🚗 Session ${sessionDoc.id}: ${vehicules.length} véhicules');

        // Si pas de véhicules dans la liste, chercher dans participants
        if (vehicules.isEmpty) {
          final participants = sessionData['participants'] as List<dynamic>?;
          debugPrint('[CONSTATS] 👥 Participants trouvés: ${participants?.length ?? 0}');

          if (participants != null) {
            for (int i = 0; i < participants.length; i++) {
              final participantData = participants[i] as Map<String, dynamic>;

              debugPrint('[CONSTATS] 👤 Participant $i structure:');
              participantData.forEach((key, value) {
                if (value is Map) {
                  debugPrint('[CONSTATS]     $key: Map(${value.length})');
                  // Afficher le contenu des donneesFormulaire
                  if (key == 'donneesFormulaire') {
                    final formulaireMap = value as Map<String, dynamic>;
                    debugPrint('[CONSTATS]       === DONNEES FORMULAIRE ===');
                    formulaireMap.forEach((fKey, fValue) {
                      debugPrint('[CONSTATS]       $fKey: $fValue');
                    });
                  }
                } else if (value is List) {
                  debugPrint('[CONSTATS]     $key: List(${value.length})');
                } else {
                  debugPrint('[CONSTATS]     $key: $value');
                }
              });

              // Les données du véhicule sont dans donneesFormulaire['vehiculeSelectionne']
              final donneesFormulaire = participantData['donneesFormulaire'] as Map<String, dynamic>?;
              final vehiculeSelectionne = donneesFormulaire?['vehiculeSelectionne'] as Map<String, dynamic>?;

              String numeroContrat = '';
              String immatriculation = '';

              if (vehiculeSelectionne != null) {
                numeroContrat = vehiculeSelectionne['numeroContrat'] ??
                               vehiculeSelectionne['contrat'] ??
                               vehiculeSelectionne['numeroPolice'] ??
                               vehiculeSelectionne['numeroAssurance'] ??
                               vehiculeSelectionne['police'] ??
                               vehiculeSelectionne['assurance'] ??
                               vehiculeSelectionne['numeroPoliceAssurance'] ?? '';

                immatriculation = vehiculeSelectionne['immatriculation'] ??
                                 vehiculeSelectionne['numeroImmatriculation'] ??
                                 vehiculeSelectionne['plaque'] ??
                                 vehiculeSelectionne['matricule'] ??
                                 vehiculeSelectionne['plaqueImmatriculation'] ?? '';
              }

              debugPrint('[CONSTATS] 🔍 Participant $i: contrat=$numeroContrat, immat=$immatriculation');

              // Vérifier correspondance
              if (_checkVehicleMatch(numeroContrat, immatriculation)) {
                debugPrint('[CONSTATS] 🎯 Session correspondante trouvée: ${sessionDoc.id}');
                allDocs.add(sessionDoc);
                break;
              }
            }
          }
        } else {
          // Traiter la liste normale de véhicules
          for (final vehicule in vehicules) {
            final vehiculeData = vehicule as Map<String, dynamic>;
            final numeroContrat = vehiculeData['numeroContrat'] ??
                                 vehiculeData['contrat'] ??
                                 vehiculeData['numeroPolice'] ?? '';
            final immatriculation = vehiculeData['immatriculation'] ?? '';

            debugPrint('[CONSTATS] 🔍 Véhicule: contrat=$numeroContrat, immat=$immatriculation');

            if (_checkVehicleMatch(numeroContrat, immatriculation)) {
              debugPrint('[CONSTATS] 🎯 Session correspondante trouvée: ${sessionDoc.id}');
              allDocs.add(sessionDoc);
              break;
            }
          }
        }
      }

      final constats = <Map<String, dynamic>>[];

      for (final doc in allDocs) {
        final data = doc.data() as Map<String, dynamic>;
        String sessionId = '';
        String codeConstat = '';
        String pdfUrl = '';
        String typeAccident = '';
        int nombreVehicules = 2;
        Timestamp? dateCreation;

        // Traiter comme session collaborative (cas principal)
        sessionId = doc.id;
        codeConstat = data['codeConstat'] ?? 'CONSTAT-${doc.id.substring(0, 6)}';
        pdfUrl = data['pdfUrl'] ?? '';
        typeAccident = data['typeAccident'] ?? 'Collision';
        final vehicules = data['vehicules'] as List<dynamic>?;
        nombreVehicules = vehicules?.length ?? 2;
        dateCreation = data['createdAt'] ?? data['dateCreation'];

        // Récupérer le nom du conducteur depuis la session (nous avons déjà la session)
        String conducteurNom = 'Conducteur';
        try {
          final conducteurData = data['conducteur'] as Map<String, dynamic>?;
          if (conducteurData != null) {
            final prenom = conducteurData['prenom'] ?? '';
            final nom = conducteurData['nom'] ?? '';
            if (prenom.isNotEmpty || nom.isNotEmpty) {
              conducteurNom = '$prenom $nom'.trim();
            }
          }
        } catch (e) {
          debugPrint('[CONSTATS] ⚠️ Erreur récupération nom conducteur: $e');
        }

        constats.add({
          'id': doc.id,
          'sessionId': sessionId,
          'codeConstat': codeConstat,
          'conducteurNom': conducteurNom,
          'dateCreation': dateCreation,
          'pdfUrl': pdfUrl,
          'typeAccident': typeAccident,
          'nombreVehicules': nombreVehicules,
        });
      }

      setState(() => _constats = constats);
    } catch (e) {
      debugPrint('[CONSTATS] ❌ Erreur chargement constats contrat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sinistres du Contrat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.numeroContrat,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête avec informations du contrat
          _buildContratHeader(),
          
          // Liste des constats
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildConstatsList(),
          ),
        ],
      ),
    );
  }

  /// 📋 En-tête avec informations du contrat
  Widget _buildContratHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contrat ${widget.numeroContrat}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Assuré: ${widget.nomAssure}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_constats.length} sinistre(s)',
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
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.vehicule,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Chargement des sinistres...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des constats
  Widget _buildConstatsList() {
    if (_constats.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _constats.length,
      itemBuilder: (context, index) {
        final constat = _constats[index];
        return _buildConstatCard(constat);
      },
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun sinistre déclaré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce contrat n\'a pas encore de sinistres',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📄 Carte de constat
  Widget _buildConstatCard(Map<String, dynamic> constat) {
    final codeConstat = constat['codeConstat'] ?? 'N/A';
    final conducteurNom = constat['conducteurNom'] ?? 'Conducteur';
    final dateCreation = constat['dateCreation'] as Timestamp?;
    final pdfUrl = constat['pdfUrl'] as String?;
    final sessionId = constat['sessionId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Constat $codeConstat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Conducteur: $conducteurNom',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dateCreation != null)
                  Text(
                    _formatDate(dateCreation),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Type', constat['typeAccident'] ?? 'N/A'),
                    ),
                    Expanded(
                      child: _buildInfoItem('Véhicules', '${constat['nombreVehicules']} véhicule(s)'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action - Télécharger PDF
                if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadAndOpenPdf(pdfUrl),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Télécharger PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'PDF non disponible',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Item d'information
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 📅 Formater la date
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }



  /// 📥 Télécharger et ouvrir le PDF avec gestion intelligente (MÉTHODE QUI FONCTIONNE)
  Future<void> _downloadAndOpenPdf(String pdfUrl) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Ouverture du PDF...'),
          ],
        ),
      ),
    );

    try {
      debugPrint('[PDF] 📥 Début téléchargement PDF: $pdfUrl');
      Uint8List? pdfBytes;

      // Méthode 1: Vérifier si c'est un chemin de fichier local
      if (pdfUrl.startsWith('/data/') || pdfUrl.startsWith('file://')) {
        debugPrint('[PDF] 📁 Fichier local détecté, lecture directe...');
        final file = File(pdfUrl.replaceAll('file://', ''));
        if (await file.exists()) {
          pdfBytes = await file.readAsBytes();
          debugPrint('[PDF] ✅ PDF local lu directement (${pdfBytes.length} bytes)');
        } else {
          debugPrint('[PDF] ⚠️ Fichier local introuvable, extraction sessionId...');
          // Extraire sessionId du nom de fichier local
          final sessionId = _extractSessionIdFromLocalPath(pdfUrl);
          if (sessionId != null) {
            debugPrint('[PDF] 🔄 Régénération PDF pour session: $sessionId');
            final newPdfPath = await CompleteElegantPdfService.genererConstatCompletElegant(
              sessionId: sessionId,
            );
            debugPrint('[PDF] 🔗 Nouveau PDF généré: $newPdfPath');

            if (newPdfPath.startsWith('/data/') || newPdfPath.startsWith('file://')) {
              final newFile = File(newPdfPath.replaceAll('file://', ''));
              if (await newFile.exists()) {
                pdfBytes = await newFile.readAsBytes();
                debugPrint('[PDF] ✅ PDF régénéré lu (${pdfBytes.length} bytes)');
              }
            }
          }
        }
      }
      // Méthode 2: URL Cloudinary
      else if (pdfUrl.contains('cloudinary.com')) {
        debugPrint('[PDF] 🌐 Tentative téléchargement Cloudinary...');
        final publicId = CloudinaryPdfService.extractPublicIdFromUrl(pdfUrl);
        if (publicId != null) {
          try {
            pdfBytes = await CloudinaryPdfService.downloadPdfWithAuth(publicId);
            if (pdfBytes != null) {
              debugPrint('[PDF] ✅ PDF téléchargé via Cloudinary (${pdfBytes.length} bytes)');
            }
          } catch (e) {
            debugPrint('[PDF] ❌ Cloudinary échoué: $e');
            // Fallback: extraire sessionId et régénérer
            debugPrint('[PDF] 🔄 Début fallback Cloudinary...');
            final sessionId = _extractSessionIdFromUrl(pdfUrl);
            if (sessionId != null) {
              debugPrint('[PDF] 🔄 Cloudinary échoué, régénération pour session: $sessionId');
              try {
                final newPdfPath = await CompleteElegantPdfService.genererConstatCompletElegant(
                  sessionId: sessionId,
                );
                debugPrint('[PDF] 🔗 Nouveau PDF généré: $newPdfPath');

                if (newPdfPath.startsWith('/data/') || newPdfPath.startsWith('file://')) {
                  final file = File(newPdfPath.replaceAll('file://', ''));
                  if (await file.exists()) {
                    pdfBytes = await file.readAsBytes();
                    debugPrint('[PDF] ✅ PDF régénéré après échec Cloudinary (${pdfBytes.length} bytes)');
                  } else {
                    debugPrint('[PDF] ❌ Fichier régénéré introuvable: $newPdfPath');
                  }
                } else {
                  debugPrint('[PDF] ❌ Chemin PDF généré invalide: $newPdfPath');
                }
              } catch (genError) {
                debugPrint('[PDF] ❌ Erreur génération PDF: $genError');
              }
            } else {
              debugPrint('[PDF] ❌ Impossible d\'extraire sessionId pour fallback');
            }
          }
        }
      }

      // Méthode 3: URL HTTP standard
      else if (pdfUrl.startsWith('http')) {
        debugPrint('[PDF] 📡 Tentative téléchargement HTTP...');
        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode == 200) {
          pdfBytes = response.bodyBytes;
          debugPrint('[PDF] ✅ PDF téléchargé via HTTP (${pdfBytes.length} bytes)');
        } else {
          throw 'Erreur téléchargement HTTP: ${response.statusCode}';
        }
      }

      if (pdfBytes != null) {
        // Sauvegarder et ouvrir le fichier
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'constat_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(pdfBytes);
        debugPrint('[PDF] 💾 PDF sauvegardé: ${file.path}');

        // Fermer l'indicateur de chargement
        Navigator.pop(context);

        // Ouvrir le fichier
        final result = await OpenFile.open(file.path);

        if (result.type == ResultType.done) {
          debugPrint('[PDF] ✅ PDF ouvert avec succès');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PDF ouvert avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          debugPrint('[PDF] ⚠️ Ouverture PDF échouée: ${result.message}');
          _showPdfSavedDialog(file.path);
        }
      } else {
        throw 'Impossible de télécharger le PDF depuis toutes les sources';
      }

    } catch (e) {
      debugPrint('[PDF] ❌ Erreur téléchargement/ouverture: $e');

      // Fermer l'indicateur de chargement si ouvert
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Afficher la boîte de dialogue d'erreur
      _showPdfErrorDialog(pdfUrl);
    }
  }

  /// 🔍 Extraire sessionId depuis une URL Cloudinary
  String? _extractSessionIdFromUrl(String url) {
    try {
      debugPrint('[PDF] 🔍 Extraction sessionId depuis URL: $url');

      // Format: .../constats_complets/VOReABmLhZlIHKMtGdod_1759763800244.pdf
      final regex = RegExp(r'constats_complets/([^_]+)_\d+\.pdf');
      final match = regex.firstMatch(url);
      final sessionId = match?.group(1);

      debugPrint('[PDF] 🔍 SessionId extrait: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('[PDF] ⚠️ Impossible d\'extraire sessionId: $e');
      return null;
    }
  }

  /// 🔍 Extraire sessionId depuis un chemin de fichier local
  String? _extractSessionIdFromLocalPath(String filePath) {
    try {
      // Format: .../constat_complet_elegant_GM855wjm5kUBpxoKHGFG_20251001_012619.pdf
      final regex = RegExp(r'constat_complet_elegant_([^_]+)_\d+_\d+\.pdf');
      final match = regex.firstMatch(filePath);
      return match?.group(1);
    } catch (e) {
      debugPrint('[PDF] ⚠️ Impossible d\'extraire sessionId du chemin local: $e');
      return null;
    }
  }

  /// 💾 Afficher une boîte de dialogue simple quand le PDF est sauvegardé
  void _showPdfSavedDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('PDF Téléchargé'),
          ],
        ),
        content: const Text(
          'Le PDF a été téléchargé avec succès dans vos fichiers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🚨 Afficher une boîte de dialogue d'erreur simple
  void _showPdfErrorDialog(String pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur PDF'),
          ],
        ),
        content: const Text(
          'Impossible de télécharger ou d\'ouvrir le PDF. Veuillez réessayer plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 🔍 Vérifier si un véhicule correspond au contrat recherché
  bool _checkVehicleMatch(String numeroContrat, String immatriculation) {
    debugPrint('[CONSTATS] 🔍 Vérification correspondance:');
    debugPrint('[CONSTATS]   - Contrat recherché: ${widget.numeroContrat}');
    debugPrint('[CONSTATS]   - Véhicule recherché: ${widget.vehicule}');
    debugPrint('[CONSTATS]   - Contrat trouvé: $numeroContrat');
    debugPrint('[CONSTATS]   - Immat trouvée: $immatriculation');

    // Vérifier correspondance EXACTE par numéro de contrat (priorité absolue)
    if (numeroContrat.isNotEmpty && numeroContrat == widget.numeroContrat) {
      debugPrint('[CONSTATS] ✅ Correspondance EXACTE trouvée par contrat: $numeroContrat');
      return true;
    }

    // Si pas de correspondance exacte de contrat, rejeter
    if (numeroContrat.isNotEmpty && numeroContrat != widget.numeroContrat) {
      debugPrint('[CONSTATS] ❌ Contrat différent: $numeroContrat != ${widget.numeroContrat}');
      return false;
    }

    // Si pas de numéro de contrat, vérifier par immatriculation (cas de secours)
    if (numeroContrat.isEmpty && immatriculation.isNotEmpty) {
      // Nettoyer les immatriculations pour comparaison
      final immatClean = immatriculation.replaceAll(RegExp(r'[\s\-_]'), '').toLowerCase();
      final vehiculeClean = widget.vehicule.replaceAll(RegExp(r'[\s\-_\(\)]'), '').toLowerCase();

      if (vehiculeClean.contains(immatClean)) {
        debugPrint('[CONSTATS] ✅ Correspondance trouvée par immatriculation (secours): $immatriculation');
        return true;
      }
    }

    debugPrint('[CONSTATS] ❌ Aucune correspondance trouvée');
    return false;
  }
}
