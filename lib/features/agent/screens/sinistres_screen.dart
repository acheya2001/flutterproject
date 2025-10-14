import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../services/agent_service.dart';
import '../../../services/sinistre_expert_assignment_service.dart';
import '../../../services/cloudinary_pdf_service.dart';
import '../../../services/complete_elegant_pdf_service.dart';
import '../../../services/conducteur_notification_service.dart';

/// 🚨 Écran de gestion des sinistres
class SinistresScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final Map<String, dynamic> userData;

  const SinistresScreen({
    Key? key,
    required this.agentData,
    required this.userData,
  }) : super(key: key);

  @override
  State<SinistresScreen> createState() => _SinistresScreenState();
}

class _SinistresScreenState extends State<SinistresScreen> {
  List<Map<String, dynamic>> _constatsFinalises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Plus besoin de TabController car on affiche directement les constats

    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConstatsFinalises();
    });
  }

  @override
  void dispose() {
    // Plus de TabController à disposer
    super.dispose();
  }



  /// 📄 Charger les constats finalisés pour cet agent
  Future<void> _loadConstatsFinalises() async {
    setState(() => _isLoading = true);

    try {
      final agentId = widget.agentData['id'];
      debugPrint('[CONSTATS] 🔍 Chargement constats pour agent: $agentId');

      // ✅ Utiliser la collection agent_constats qui contient les vraies données
      // Essayer d'abord sans orderBy pour éviter les problèmes d'index
      final constatsQuery = await FirebaseFirestore.instance
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentId)
          .get();

      debugPrint('[CONSTATS] 📊 ${constatsQuery.docs.length} documents trouvés dans agent_constats');

      final constats = <Map<String, dynamic>>[];

      for (final doc in constatsQuery.docs) {
        final constat = doc.data();
        final sessionId = constat['sessionId'] ?? '';
        debugPrint('[CONSTATS] 📄 Document trouvé: ${doc.id}, sessionId: $sessionId');

        // Vérifier que le PDF URL existe et est valide
        final pdfUrl = constat['pdfUrl'] as String?;
        debugPrint('[CONSTATS] 🔗 PDF URL: $pdfUrl');

        // Récupérer le vrai nom du conducteur depuis la session collaborative
        String conducteurNom = 'Conducteur';
        if (sessionId.isNotEmpty && sessionId != 'N/A') {
          try {
            final sessionDoc = await FirebaseFirestore.instance
                .collection('sessions_collaboratives')
                .doc(sessionId)
                .get();

            if (sessionDoc.exists) {
              final sessionData = sessionDoc.data() as Map<String, dynamic>;
              final conducteurData = sessionData['conducteur'] as Map<String, dynamic>?;
              if (conducteurData != null) {
                final prenom = conducteurData['prenom'] ?? '';
                final nom = conducteurData['nom'] ?? '';
                if (prenom.isNotEmpty || nom.isNotEmpty) {
                  conducteurNom = '$prenom $nom'.trim();
                }
              }
            }
          } catch (e) {
            debugPrint('[CONSTATS] ⚠️ Erreur récupération nom conducteur pour session $sessionId: $e');
          }
        }

        constats.add({
          'id': doc.id,
          'sessionId': sessionId,
          'codeConstat': constat['codeConstat'] ?? 'N/A',
          'clientNom': conducteurNom,
          'clientRole': 'Conducteur',
          'dateCreation': constat['createdAt'],
          'statut': constat['statutTraitement'] ?? 'nouveau',
          'pdfUrl': pdfUrl,
          'titre': 'Constat ${constat['codeConstat']}',
          'message': 'Conducteur: $conducteurNom',
          'lu': constat['dateVu'] != null,
          'agenceNom': constat['agenceNom'],
          'compagnieNom': constat['compagnieNom'],
          'nombreVehicules': constat['nombreVehicules'],
          'typeAccident': constat['typeAccident'],
        });
      }

      setState(() {
        _constatsFinalises = constats;
        _isLoading = false;
      });
      debugPrint('[CONSTATS] ✅ ${constats.length} constats chargés depuis agent_constats');

    } catch (e) {
      debugPrint('[CONSTATS] ❌ Erreur chargement constats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Constats Reçus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_constatsFinalises.length} constat(s) reçu(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFEF4444)),
          SizedBox(height: 20),
          Text(
            'Chargement des sinistres...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal - Constats reçus directement
  Widget _buildMainContent() {
    return _buildConstatsTab();
  }



  /// 📄 Onglet des constats finalisés reçus
  Widget _buildConstatsTab() {
    if (_constatsFinalises.isEmpty) {
      return _buildEmptyConstatsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _constatsFinalises.length,
      itemBuilder: (context, index) {
        return _buildConstatCard(_constatsFinalises[index]);
      },
    );
  }





  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return 'Non défini';

    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = date.toDate();
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Format invalide';
    }
  }

  /// 🔧 Créer un sinistre à partir d'un constat
  Future<Map<String, dynamic>?> _createSinistreFromConstat(
    Map<String, dynamic> constat,
    String compagnieId,
    String agenceId
  ) async {
    try {
      debugPrint('[SINISTRES] 🔧 Création sinistre à partir du constat: ${constat['codeConstat']}');

      // Vérifier si un sinistre existe déjà pour ce constat
      final existingSinistres = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('codeConstat', isEqualTo: constat['codeConstat'])
          .get();

      if (existingSinistres.docs.isNotEmpty) {
        // Sinistre déjà existant
        final existingSinistre = existingSinistres.docs.first;
        debugPrint('[SINISTRES] ✅ Sinistre existant trouvé: ${existingSinistre.id}');
        final data = existingSinistre.data();
        data['id'] = existingSinistre.id;
        return data;
      }

      // Créer un nouveau sinistre
      final sinistreRef = FirebaseFirestore.instance.collection('sinistres').doc();
      final sinistreData = {
        'id': sinistreRef.id,
        'codeConstat': constat['codeConstat'],
        'sessionId': constat['sessionId'],
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        'agentId': widget.agentData['uid'],
        'conducteurNom': constat['conducteurNom'] ?? '',
        'conducteurPrenom': constat['conducteurPrenom'] ?? '',
        'numeroContrat': constat['numeroContrat'] ?? '',
        'numeroPolice': constat['numeroPolice'] ?? '',
        'dateAccident': constat['dateCreation'],
        'lieuAccident': constat['lieuAccident'] ?? 'Non spécifié',
        'typeAccident': constat['typeAccident'] ?? 'Non spécifié',
        'degatsEstimes': constat['degatsEstimes'] ?? 0,
        'statut': 'en_attente_expertise',
        'expertAssigne': null,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateModification': FieldValue.serverTimestamp(),
        'createdBy': widget.agentData['uid'],
        'isActive': true,
      };

      await sinistreRef.set(sinistreData);

      debugPrint('[SINISTRES] ✅ Sinistre créé avec succès: ${sinistreRef.id}');
      sinistreData['dateCreation'] = Timestamp.now(); // Pour l'affichage immédiat
      sinistreData['dateModification'] = Timestamp.now();

      return sinistreData;

    } catch (e) {
      debugPrint('[SINISTRES] ❌ Erreur création sinistre: $e');
      return null;
    }
  }

  /// 📄 État vide pour les constats
  Widget _buildEmptyConstatsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 60,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun constat reçu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les constats finalisés pour vos contrats\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Carte de constat finalisé
  Widget _buildConstatCard(Map<String, dynamic> constat) {
    // Nouvelles données de notification
    final codeConstat = constat['codeConstat'] ?? 'N/A';
    final clientNom = constat['clientNom'] ?? 'Client inconnu';
    final clientRole = constat['clientRole'] ?? 'N/A';
    final sessionId = constat['sessionId'] ?? '';
    final titre = constat['titre'] ?? 'Nouveau constat';
    final message = constat['message'] ?? '';
    final lu = constat['lu'] ?? false;

    final statut = constat['statut'] ?? 'recu';
    Color statutColor;
    String statutText;

    switch (statut) {
      case 'recu':
        statutColor = lu ? Colors.green : Colors.orange;
        statutText = lu ? 'Vu' : 'Nouveau';
        break;
      case 'envoye':
        statutColor = Colors.green;
        statutText = 'Traité';
        break;
      case 'erreur':
        statutColor = Colors.red;
        statutText = 'Erreur';
        break;
      default:
        statutColor = Colors.grey;
        statutText = 'Inconnu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statutText,
                    style: TextStyle(
                      color: statutColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(constat['dateCreation']),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations du constat
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Constat: $codeConstat',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Session ID
            Row(
              children: [
                Icon(Icons.link, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Session: ${sessionId.substring(0, 8)}...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Client
            Row(
              children: [
                Icon(Icons.person, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conducteur: $clientNom',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Message
            if (message.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Actions - Seulement le bouton Télécharger PDF
            if (constat['pdfUrl'] != null && constat['pdfUrl'].toString().isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        debugPrint('[CONSTAT] 📥 Téléchargement direct pour: ${constat['codeConstat']}');
                        _downloadAndOpenPdf(constat['pdfUrl']);
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Télécharger PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignExpertToConstat(constat),
                      icon: const Icon(Icons.engineering, size: 16),
                      label: const Text('Assigner Expert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Pas de PDF disponible
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'PDF non disponible',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📄 Ouvrir le PDF du constat
  void _ouvrirPDF(String? pdfUrl) async {
    try {
      debugPrint('[PDF] 🔍 Tentative d\'ouverture PDF: $pdfUrl');

      if (pdfUrl == null || pdfUrl.isEmpty) {
        throw 'URL du PDF non disponible';
      }

      // Vérifier si c'est une URL Cloudinary et optimiser l'URL
      String finalUrl = pdfUrl;
      if (pdfUrl.contains('cloudinary.com')) {
        debugPrint('[PDF] 🔗 URL Cloudinary détectée, optimisation URL...');

        // Extraire le public ID depuis l'URL
        final publicId = CloudinaryPdfService.extractPublicIdFromUrl(pdfUrl);
        if (publicId != null) {
          finalUrl = CloudinaryPdfService.getBestAccessUrl(publicId);
          debugPrint('[PDF] ✅ URL optimisée générée: $finalUrl');
        } else {
          debugPrint('[PDF] ⚠️ Impossible d\'extraire le public ID, utilisation URL originale');
        }
      }

      // Vérifier si c'est une URL web valide
      if (finalUrl.startsWith('https://')) {
        debugPrint('[PDF] ✅ URL HTTPS détectée, tentative d\'ouverture...');

        final uri = Uri.parse(finalUrl);

        // Essayer plusieurs modes de lancement
        try {
          // 1. Essayer d'abord avec le navigateur intégré
          debugPrint('[PDF] 🌐 Tentative ouverture avec navigateur intégré...');
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          debugPrint('[PDF] ✅ PDF ouvert avec navigateur intégré');
          return;
        } catch (e) {
          debugPrint('[PDF] ⚠️ Navigateur intégré échoué: $e');
        }

        try {
          // 2. Essayer avec le navigateur externe
          debugPrint('[PDF] 🌐 Tentative ouverture avec navigateur externe...');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('[PDF] ✅ PDF ouvert avec navigateur externe');
          return;
        } catch (e) {
          debugPrint('[PDF] ⚠️ Navigateur externe échoué: $e');
        }

        try {
          // 3. Essayer avec le mode plateforme par défaut
          debugPrint('[PDF] 📱 Tentative ouverture avec mode plateforme...');
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          debugPrint('[PDF] ✅ PDF ouvert avec mode plateforme');
          return;
        } catch (e) {
          debugPrint('[PDF] ⚠️ Mode plateforme échoué: $e');
        }

        // Si tout échoue, essayer de télécharger et ouvrir localement
        debugPrint('[PDF] ❌ Tous les modes d\'ouverture ont échoué, tentative de téléchargement...');
        await _downloadAndOpenPdf(finalUrl);
        return;

      } else {
        debugPrint('[PDF] ❌ URL non HTTPS détectée: $pdfUrl');
        throw 'PDF local non accessible. Veuillez demander une nouvelle génération.';
      }
    } catch (e) {
      debugPrint('[PDF] ❌ Erreur ouverture PDF: $e');
      _showPdfErrorDialog(pdfUrl ?? 'URL non disponible');
    }
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

  /// 📥 Télécharger et ouvrir le PDF avec gestion intelligente
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

      // Vérifier si c'est un chemin de fichier local
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
            final sessionId = _extractSessionIdFromUrl(pdfUrl);
            if (sessionId != null) {
              debugPrint('[PDF] 🔄 Cloudinary échoué, régénération pour session: $sessionId');
              final newPdfPath = await CompleteElegantPdfService.genererConstatCompletElegant(
                sessionId: sessionId,
              );
              if (newPdfPath.startsWith('/data/') || newPdfPath.startsWith('file://')) {
                final file = File(newPdfPath.replaceAll('file://', ''));
                if (await file.exists()) {
                  pdfBytes = await file.readAsBytes();
                  debugPrint('[PDF] ✅ PDF régénéré après échec Cloudinary (${pdfBytes.length} bytes)');
                }
              }
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
        throw 'Impossible de lire ou télécharger le PDF';
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
      // Format: .../constats_complets/VOReABmLhZlIHKMtGdod_1759763800244.pdf
      final regex = RegExp(r'constats_complets/([^_]+)_\d+\.pdf');
      final match = regex.firstMatch(url);
      return match?.group(1);
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

  /// 👁️ Voir les détails du constat
  void _voirDetailsConstat(Map<String, dynamic> constat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du Constat'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Session: ${constat['sessionId']}'),
              const SizedBox(height: 8),
              Text('Contrat: ${constat['contratId']}'),
              const SizedBox(height: 8),
              Text('Statut: ${constat['statut']}'),
              const SizedBox(height: 8),
              Text('Date: ${_formatDate(constat['dateCreation'])}'),
              if (constat['pdfUrl'] != null) ...[
                const SizedBox(height: 8),
                Text('PDF disponible: Oui'),
              ],
            ],
          ),
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

  /// 🔧 Assigner un expert à un constat
  Future<void> _assignExpertToConstat(Map<String, dynamic> constat) async {
    try {
      debugPrint('[SINISTRES] 🔧 Assignation expert pour constat: ${constat['codeConstat']}');

      // Vérifier les données de l'agent avec gestion des valeurs nulles
      final compagnieId = widget.agentData['compagnieId'] as String?;
      final agenceId = widget.agentData['agenceId'] as String?;

      debugPrint('[SINISTRES] 🔍 Agent data: compagnieId=$compagnieId, agenceId=$agenceId');
      debugPrint('[SINISTRES] 🔍 Agent data complet: ${widget.agentData}');

      if (compagnieId == null || compagnieId.isEmpty || agenceId == null || agenceId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Données agent incomplètes:\n- Compagnie: ${compagnieId ?? "manquante"}\n- Agence: ${agenceId ?? "manquante"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Charger les experts disponibles de l'agence
      final experts = await SinistreExpertAssignmentService.findAvailableExperts(
        compagnieId: compagnieId,
        agenceId: agenceId,
        onlyAvailable: true,
      );

      if (experts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucun expert disponible dans votre agence'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Créer un sinistre à partir du constat
      final sinistreData = await _createSinistreFromConstat(constat, compagnieId, agenceId);
      if (sinistreData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la création du sinistre'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Afficher le dialogue d'assignation
      showDialog(
        context: context,
        builder: (context) => _ExpertAssignmentDialog(
          sinistre: sinistreData,
          experts: experts,
          agentId: widget.agentData['uid'] ?? widget.agentData['id'] ?? '',
          onExpertAssigned: () {
            // Rafraîchir la liste des constats
            _loadConstatsFinalises();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Expert assigné avec succès au constat'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      );

    } catch (e) {
      debugPrint('[SINISTRES] ❌ Erreur assignation expert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de l\'assignation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗺️ Extraire le gouvernorat du lieu (simple extraction)
  String? _extractGouvernorat(String? lieu) {
    if (lieu == null) return null;

    final gouvernorats = [
      'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
      'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
      'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine',
      'Sidi Bouzid', 'Gabès', 'Médenine', 'Tataouine', 'Gafsa',
      'Tozeur', 'Kébili'
    ];

    for (final gouvernorat in gouvernorats) {
      if (lieu.toLowerCase().contains(gouvernorat.toLowerCase())) {
        return gouvernorat;
      }
    }
    return null;
  }
}

/// 🔧 Dialogue d'affectation d'expert
class _ExpertAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic> sinistre;
  final List<Map<String, dynamic>> experts;
  final String agentId;
  final VoidCallback onExpertAssigned;

  const _ExpertAssignmentDialog({
    required this.sinistre,
    required this.experts,
    required this.agentId,
    required this.onExpertAssigned,
  });

  @override
  State<_ExpertAssignmentDialog> createState() => _ExpertAssignmentDialogState();
}

class _ExpertAssignmentDialogState extends State<_ExpertAssignmentDialog> {
  String? _selectedExpertId;
  final _commentaireController = TextEditingController();
  int _delaiIntervention = 24; // 24h par défaut
  bool _isLoading = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Affecter un Expert'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du sinistre
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sinistre: ${widget.sinistre['numeroSinistre'] ?? widget.sinistre['id']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('Lieu: ${widget.sinistre['lieuAccident'] ?? widget.sinistre['lieu'] ?? 'Non spécifié'}'),
                  Text('Date: ${_formatDateSimple(widget.sinistre['dateAccident'])}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sélection de l'expert
            const Text(
              'Sélectionner un expert:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: widget.experts.length,
                itemBuilder: (context, index) {
                  final expert = widget.experts[index];
                  final isSelected = _selectedExpertId == expert['id'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
                      child: Text(
                        '${expert['prenom']?[0] ?? ''}${expert['nom']?[0] ?? ''}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text('${expert['prenom'] ?? ''} ${expert['nom'] ?? ''}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code: ${expert['codeExpert'] ?? 'N/A'}'),
                        Text('Source: ${expert['source'] ?? 'N/A'}'),
                        if (expert['specialites'] != null && expert['specialites'] is List)
                          Text('Spécialités: ${(expert['specialites'] as List).map((e) => e.toString()).join(', ')}'),
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedExpertId = expert['id'];
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Délai d'intervention
            Text(
              'Délai d\'intervention (heures):',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _delaiIntervention,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 12, child: Text('12 heures')),
                DropdownMenuItem(value: 24, child: Text('24 heures')),
                DropdownMenuItem(value: 48, child: Text('48 heures')),
                DropdownMenuItem(value: 72, child: Text('72 heures')),
              ],
              onChanged: (value) {
                setState(() {
                  _delaiIntervention = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Commentaire
            TextField(
              controller: _commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedExpertId == null ? null : _assignExpert,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Affecter'),
        ),
      ],
    );
  }



  /// 📅 Formater la date (version simple)
  String _formatDateSimple(dynamic date) {
    if (date == null) return 'Non spécifiée';

    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.tryParse(date) ?? DateTime.now();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Non spécifiée';
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Format invalide';
    }
  }

  /// ✅ Affecter l'expert
  Future<void> _assignExpert() async {
    if (_selectedExpertId == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await SinistreExpertAssignmentService.assignExpertToSinistre(
        sinistreId: widget.sinistre['id'],
        expertId: _selectedExpertId!,
        agentId: widget.agentId,
        commentaire: _commentaireController.text.trim().isNotEmpty
            ? _commentaireController.text.trim()
            : null,
        delaiIntervention: _delaiIntervention,
      );

      if (result['success']) {
        // Mettre à jour le statut du constat
        await _updateConstatStatus();

        Navigator.pop(context);
        widget.onExpertAssigned();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expert ${result['expertNom']} affecté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de l\'affectation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📝 Mettre à jour le statut du constat
  Future<void> _updateConstatStatus() async {
    try {
      debugPrint('[SINISTRES] 📝 Mise à jour statut constat: ${widget.sinistre['codeConstat']}');

      // Récupérer les données de l'expert assigné
      final expertDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedExpertId!)
          .get();

      final expertData = expertDoc.data();
      final expertNom = '${expertData?['prenom'] ?? ''} ${expertData?['nom'] ?? ''}';

      // Mettre à jour ou créer le constat dans la collection constats_finalises
      final sessionId = widget.sinistre['sessionId'];

      // Récupérer les données de la session pour créer le document si nécessaire
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      Map<String, dynamic> constatData = {
        'statut': 'expert_assigne',
        'expertAssigne': {
          'id': _selectedExpertId,
          'nom': expertNom,
          'prenom': expertData?['prenom'] ?? '',
          'codeExpert': expertData?['codeExpert'] ?? '',
          'telephone': expertData?['telephone'] ?? '',
          'email': expertData?['email'] ?? '',
        },
        'dateAssignationExpert': FieldValue.serverTimestamp(),
        'commentaireAssignation': _commentaireController.text.trim(),
        'delaiInterventionHeures': _delaiIntervention,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si la session existe, ajouter les données de base
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        constatData.addAll({
          'sessionId': sessionId,
          'codeConstat': sessionData['codeSession'] ?? '',
          'conducteurId': sessionData['conducteurCreateur'],
          'nombreVehicules': sessionData['nombreVehicules'] ?? 2,
          'typeAccident': sessionData['typeAccident'] ?? 'collision',
          'createdAt': sessionData['dateCreation'] ?? FieldValue.serverTimestamp(),
        });
      }

      // Utiliser set avec merge pour créer ou mettre à jour
      await FirebaseFirestore.instance
          .collection('constats_finalises')
          .doc(sessionId)
          .set(constatData, SetOptions(merge: true));

      debugPrint('[SINISTRES] ✅ Statut constat mis à jour: expert_assigne');

      // Envoyer une notification au conducteur
      await _envoyerNotificationConducteur();

    } catch (e) {
      debugPrint('[SINISTRES] ❌ Erreur mise à jour statut constat: $e');
    }
  }

  /// 📧 Envoyer une notification au conducteur
  Future<void> _envoyerNotificationConducteur() async {
    try {
      debugPrint('[SINISTRES] 📧 Envoi notification au conducteur');

      // Récupérer l'ID du conducteur depuis le constat
      final constatDoc = await FirebaseFirestore.instance
          .collection('constats_finalises')
          .doc(widget.sinistre['sessionId'])
          .get();

      if (!constatDoc.exists) {
        debugPrint('[SINISTRES] ❌ Constat non trouvé pour notification');
        return;
      }

      final constatData = constatDoc.data()!;
      final conducteurId = constatData['conducteurId'];

      if (conducteurId == null || conducteurId.isEmpty) {
        debugPrint('[SINISTRES] ❌ ID conducteur manquant pour notification');
        return;
      }

      // Récupérer les données de l'expert
      final expertDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedExpertId!)
          .get();

      if (!expertDoc.exists) {
        debugPrint('[SINISTRES] ❌ Expert non trouvé pour notification');
        return;
      }

      final expertData = expertDoc.data()!;
      expertData['id'] = _selectedExpertId;
      expertData['nom'] = '${expertData['prenom'] ?? ''} ${expertData['nom'] ?? ''}';

      // Envoyer la notification
      final result = await ConducteurNotificationService.notifierExpertAssigne(
        conducteurId: conducteurId,
        codeConstat: widget.sinistre['codeConstat'] ?? 'N/A',
        sessionId: widget.sinistre['sessionId'] ?? '',
        expertData: expertData,
        agentId: widget.agentId,
        commentaire: _commentaireController.text.trim(),
        delaiInterventionHeures: _delaiIntervention,
      );

      if (result['success'] == true) {
        debugPrint('[SINISTRES] ✅ Notification envoyée avec succès');
      } else {
        debugPrint('[SINISTRES] ❌ Erreur envoi notification: ${result['error']}');
      }

    } catch (e) {
      debugPrint('[SINISTRES] ❌ Erreur envoi notification conducteur: $e');
    }
  }
}

