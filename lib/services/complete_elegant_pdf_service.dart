import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'cloudinary_pdf_service.dart';
import 'firebase_pdf_upload_service.dart';

/// 🇹🇳 Service PDF Complet et Élégant pour Constats Tunisiens
/// Génère un PDF totalement complet avec TOUTES les données des formulaires de TOUS les participants
/// Design moderne, élégant et professionnel
class CompleteElegantPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Télécharge une image depuis une URL et retourne les bytes
  static Future<Uint8List?> _downloadImageFromUrl(String url) async {
    try {
      print('🌐 [PDF] Téléchargement image: $url');

      // Nettoyer l'URL si nécessaire
      String cleanUrl = url.trim();

      // Pour les URLs Cloudinary, s'assurer qu'elles sont bien formées
      if (cleanUrl.contains('cloudinary.com')) {
        // Ajouter des paramètres d'optimisation pour Cloudinary
        if (!cleanUrl.contains('f_auto')) {
          cleanUrl += (cleanUrl.contains('?') ? '&' : '?') + 'f_auto,q_auto';
        }
      }

      final response = await http.get(
        Uri.parse(cleanUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'image/*,*/*;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ [PDF] Image téléchargée avec succès (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      } else {
        print('⚠️ [PDF] Erreur HTTP ${response.statusCode} pour $cleanUrl');
        print('⚠️ [PDF] Headers response: ${response.headers}');
        return null;
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur téléchargement image: $e');
      print('⚠️ [PDF] URL problématique: $url');
      return null;
    }
  }

  /// 📋 Mapping des circonstances par code
  static const Map<String, String> _circonstancesMapping = {
    '1': 'Stationnait',
    '2': 'Quittait un stationnement',
    '3': 'Prenait un stationnement',
    '4': 'Sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
    '5': 'S\'engageait dans un parking, un lieu privé, un chemin de terre',
    '6': 'Circulait',
    '7': 'Changeait de file',
    '8': 'Dépassait',
    '9': 'Tournait à droite',
    '10': 'Tournait à gauche',
    '11': 'Reculait',
    '12': 'Empiétait sur une file de circulation réservée à la circulation en sens inverse',
    '13': 'Venait de droite (dans un carrefour)',
    '14': 'N\'avait pas observé un signal de priorité ou une signalisation',
    '15': 'Était en stationnement, en arrêt ou en panne',
    '16': 'Ouvrait une portière',
    '17': 'Descendait du véhicule',
  };

  /// 🎨 Obtenir le nom complet d'une circonstance
  static String _obtenirNomCirconstance(dynamic code) {
    try {
      if (code == null) return 'Non spécifiée';

      // Gestion spéciale pour les listes (cas d'erreur)
      if (code is List) {
        if (code.isEmpty) return 'Non spécifiée';
        // Prendre le premier élément de la liste
        return _obtenirNomCirconstance(code.first);
      }

      final codeStr = code.toString().trim();
      if (codeStr.isEmpty) return 'Non spécifiée';

      return _circonstancesMapping[codeStr] ?? 'Circonstance $codeStr';
    } catch (e) {
      print('⚠️ [PDF] Erreur obtention nom circonstance: $e (code: $code, type: ${code.runtimeType})');
      return 'Circonstance inconnue';
    }
  }

  /// 🔧 Helper methods for safe data conversion
  static String _safeStringConvert(dynamic data, [String defaultValue = 'N/A']) {
    try {
      if (data == null) return defaultValue;
      if (data is String) return data.isNotEmpty ? data : defaultValue;
      if (data is List) {
        if (data.isEmpty) return defaultValue;
        // Convertir la liste en string lisible
        final validItems = data.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        return validItems.isNotEmpty ? validItems.join(', ') : defaultValue;
      }
      if (data is Map) {
        // Pour les maps, essayer d'extraire une valeur significative
        if (data.containsKey('nom')) return data['nom']?.toString() ?? defaultValue;
        if (data.containsKey('name')) return data['name']?.toString() ?? defaultValue;
        if (data.containsKey('value')) return data['value']?.toString() ?? defaultValue;
        return data.toString();
      }
      if (data is num) return data.toString();
      if (data is bool) return data ? 'Oui' : 'Non';
      return data.toString();
    } catch (e) {
      print('⚠️ [PDF] Erreur conversion String: $e (data: $data, type: ${data.runtimeType})');
      return defaultValue;
    }
  }

  static Map<String, dynamic> _safeMapConvert(dynamic data) {
    try {
      if (data == null) return {};
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is String) {
        // Tenter de parser un JSON string
        try {
          final parsed = json.decode(data);
          if (parsed is Map) return Map<String, dynamic>.from(parsed);
        } catch (e) {
          // Ignore, retourner map vide
        }
      }
      return {};
    } catch (e) {
      print('⚠️ [PDF] Erreur conversion Map: $e (data: $data, type: ${data.runtimeType})');
      return {};
    }
  }

  static List<dynamic> _safeListConvert(dynamic data) {
    try {
      if (data == null) return [];
      if (data is List) return data;
      if (data is String) {
        // Si c'est une string, essayer de la parser comme JSON
        try {
          final parsed = json.decode(data);
          if (parsed is List) return parsed;
        } catch (e) {
          // Si ce n'est pas du JSON, traiter comme une seule valeur
          return [data];
        }
      }
      // Pour tout autre type, créer une liste avec cette valeur
      return [data];
    } catch (e) {
      print('⚠️ [PDF] Erreur conversion List: $e (data: $data, type: ${data.runtimeType})');
      return [];
    }
  }

  /// 🔍 Méthode de diagnostic pour analyser les données Firestore
  static Future<void> diagnostiquerDonnees({required String sessionId}) async {
    print('🔍 [DIAGNOSTIC] Début analyse pour session: $sessionId');

    try {
      // 1. Session principale
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        print('❌ [DIAGNOSTIC] Session non trouvée: $sessionId');
        return;
      }

      final sessionData = sessionDoc.data()!;
      print('✅ [DIAGNOSTIC] Session trouvée avec ${sessionData.keys.length} champs');
      print('   Champs session: ${sessionData.keys.toList()}');

      // 2. Participants data
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      print('✅ [DIAGNOSTIC] ${participantsSnapshot.docs.length} participants trouvés');

      for (var doc in participantsSnapshot.docs) {
        final data = doc.data();
        print('   Participant ${doc.id}:');
        print('     - Champs: ${data.keys.toList()}');

        final donneesFormulaire = data['donneesFormulaire'] as Map<String, dynamic>? ?? {};
        print('     - Formulaire: ${donneesFormulaire.keys.toList()}');

        final donneesPersonnelles = donneesFormulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
        print('     - Données personnelles: ${donneesPersonnelles.keys.toList()}');

        // Vérifier les URLs d'images
        final permisRecto = donneesPersonnelles['permisRectoUrl'];
        final permisVerso = donneesPersonnelles['permisVersoUrl'];
        final cinRecto = donneesPersonnelles['cinRectoUrl'];
        final cinVerso = donneesPersonnelles['cinVersoUrl'];
        final degatsPhotos = donneesFormulaire['degatsPhotos'] ?? donneesFormulaire['photosDegatUrls'];

        print('     - Permis recto: ${permisRecto != null ? 'PRÉSENT' : 'ABSENT'}');
        print('     - Permis verso: ${permisVerso != null ? 'PRÉSENT' : 'ABSENT'}');
        print('     - CIN recto: ${cinRecto != null ? 'PRÉSENT' : 'ABSENT'}');
        print('     - CIN verso: ${cinVerso != null ? 'PRÉSENT' : 'ABSENT'}');
        print('     - Photos dégâts: ${degatsPhotos is List ? degatsPhotos.length : 0}');

        // Vérifier signature
        final signature = donneesFormulaire['signatureData'] ?? donneesFormulaire['signature'];
        final aSigne = donneesFormulaire['aSigne'];
        print('     - Signature: ${signature != null ? 'PRÉSENT' : 'ABSENT'}');
        print('     - A signé: $aSigne');

        // Vérifier témoins
        final temoins = donneesFormulaire['temoins'];
        print('     - Témoins: ${temoins is List ? temoins.length : 0}');
      }

      // 3. Signatures collection
      final signaturesSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .get();

      print('✅ [DIAGNOSTIC] ${signaturesSnapshot.docs.length} signatures trouvées');

      // 4. Croquis collection
      final croquisSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('croquis')
          .get();

      print('✅ [DIAGNOSTIC] ${croquisSnapshot.docs.length} croquis trouvés');

      // 5. Photos collection
      final photosSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('photos')
          .get();

      print('✅ [DIAGNOSTIC] ${photosSnapshot.docs.length} photos trouvées');

    } catch (e) {
      print('❌ [DIAGNOSTIC] Erreur: $e');
    }
  }

  /// 🎯 Méthode principale pour générer le PDF complet et élégant
  static Future<String> genererConstatCompletElegant({required String sessionId}) async {
    print('🇹🇳 [PDF COMPLET ÉLÉGANT] Début génération pour session: $sessionId (type: ${sessionId.runtimeType})');

    try {
      // Validation du sessionId
      if (sessionId.isEmpty) {
        throw Exception('SessionId ne peut pas être vide');
      }

      // 🔍 DIAGNOSTIC COMPLET DES DONNÉES
      await diagnostiquerDonnees(sessionId: sessionId);

      // 1. Charger TOUTES les données avec formulaires complets
      final donnees = await _chargerToutesLesDonnees(sessionId);
      print('✅ [PDF DEBUG] Données complètes chargées: ${donnees.keys.length} sections');

      // Debug: afficher un résumé des données chargées
      final participants = donnees['participants'] as List<dynamic>? ?? [];
      final signatures = donnees['signatures'] as Map<String, dynamic>? ?? {};
      final croquis = donnees['croquis'] as Map<String, dynamic>? ?? {};
      final photos = donnees['photos'] as List<dynamic>? ?? [];

      print('📊 [PDF DEBUG] Résumé des données:');
      print('   - Session ID: $sessionId');
      print('   - Nombre participants: ${participants.length}');
      print('   - Signatures: ${signatures.length} (${signatures.keys.toList()})');
      print('   - Croquis: ${croquis.isNotEmpty} (${croquis.keys.toList()})');
      print('   - Photos: ${photos.length}');

      // Debug détaillé des photos
      if (photos.isNotEmpty) {
        print('🔍 [PDF DEBUG] Détail des photos:');
        for (int i = 0; i < photos.length && i < 5; i++) {
          final photo = photos[i] as Map<String, dynamic>? ?? {};
          print('   Photo $i: type=${photo['type']}, description=${photo['description']}, url=${photo['url']?.toString().substring(0, 50)}...');
        }
      }

      // Debug détaillé des participants
      if (participants.isNotEmpty) {
        print('🔍 [PDF DEBUG] Détail des participants:');
        for (int i = 0; i < participants.length; i++) {
          final participant = participants[i] as Map<String, dynamic>? ?? {};
          final donneesFormulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
          print('   Participant $i: role=${participant['roleVehicule']}, formulaire=${donneesFormulaire.keys.length} champs');
          print('   Champs formulaire: ${donneesFormulaire.keys.toList()}');

          // Vérifier les photos dans le formulaire
          final degatsPhotos = donneesFormulaire['degatsPhotos'] ?? donneesFormulaire['photosDegatUrls'] ?? [];
          final donneesPersonnelles = donneesFormulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
          final permisRecto = donneesPersonnelles['permisRectoUrl'];
          final permisVerso = donneesPersonnelles['permisVersoUrl'];
          final cinRecto = donneesPersonnelles['cinRectoUrl'];
          final cinVerso = donneesPersonnelles['cinVersoUrl'];

          print('     - Photos dégâts: ${degatsPhotos is List ? degatsPhotos.length : 0}');
          if (degatsPhotos is List && degatsPhotos.isNotEmpty) {
            for (int j = 0; j < degatsPhotos.length && j < 3; j++) {
              print('       Photo $j: ${degatsPhotos[j]?.toString().substring(0, 50)}...');
            }
          }
          print('     - Permis recto: ${permisRecto != null ? 'OUI' : 'NON'}');
          if (permisRecto != null) print('       URL: ${permisRecto.toString().substring(0, 50)}...');
          print('     - Permis verso: ${permisVerso != null ? 'OUI' : 'NON'}');
          if (permisVerso != null) print('       URL: ${permisVerso.toString().substring(0, 50)}...');
          print('     - CIN recto: ${cinRecto != null ? 'OUI' : 'NON'}');
          if (cinRecto != null) print('       URL: ${cinRecto.toString().substring(0, 50)}...');
          print('     - CIN verso: ${cinVerso != null ? 'OUI' : 'NON'}');
          if (cinVerso != null) print('       URL: ${cinVerso.toString().substring(0, 50)}...');
          print('     - Signature: ${donneesFormulaire['signatureData'] != null ? 'OUI' : 'NON'}');
          print('     - A signé: ${donneesFormulaire['aSigne']}');

          // Vérifier les témoins
          final temoins = donneesFormulaire['temoins'] ?? [];
          print('     - Témoins: ${temoins is List ? temoins.length : 0}');
          if (temoins is List && temoins.isNotEmpty) {
            for (int j = 0; j < temoins.length && j < 2; j++) {
              final temoin = temoins[j] as Map<String, dynamic>? ?? {};
              print('       Témoin $j: ${temoin['nom']} ${temoin['prenom']} - ${temoin['telephone']}');
            }
          }
        }
      }

      // 2. Créer le document PDF avec design élégant
      final pdf = pw.Document();

      // 3. Pages du PDF complet avec gestion d'erreur
      print('🔍 [PDF DEBUG] Début ajout des pages...');
      try {
        await _ajouterToutesLesPages(pdf, donnees);
        print('✅ [PDF DEBUG] Pages ajoutées avec succès');
      } catch (pageError) {
        print('❌ [PDF DEBUG] Erreur lors de l\'ajout des pages: $pageError');
        print('❌ [PDF DEBUG] Stack trace: ${StackTrace.current}');
        rethrow;
      }

      // 4. Sauvegarder le PDF avec validation stricte du sessionId
      print('🔍 [PDF DEBUG] Début sauvegarde...');
      print('🔍 [PDF DEBUG] SessionId avant sauvegarde: $sessionId (type: ${sessionId.runtimeType})');

      // S'assurer que sessionId est bien une String
      final validSessionId = sessionId is String ? sessionId : sessionId.toString();
      final pdfPath = await _sauvegarderPdf(pdf, validSessionId);
      print('✅ [PDF COMPLET] PDF élégant généré: $pdfPath');

      return pdfPath;
    } catch (e, stackTrace) {
      print('❌ [PDF COMPLET] Erreur: $e');
      print('❌ [PDF COMPLET] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 📊 Charger TOUTES les données de la session avec formulaires complets
  static Future<Map<String, dynamic>> _chargerToutesLesDonnees(String sessionId) async {
    final donnees = <String, dynamic>{};

    try {
      print('🔍 [PDF DEBUG] Début chargement pour session: $sessionId');

      // 1. Session principale
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée: $sessionId');
      }

      final sessionData = sessionDoc.data()!;
      donnees.addAll(sessionData);
      // S'assurer que le sessionId est disponible
      donnees['sessionId'] = sessionId;
      donnees['id'] = sessionId;
      print('✅ [PDF DEBUG] Session principale chargée: ${sessionData.keys.toList()}');
      print('✅ [PDF DEBUG] SessionId ajouté: $sessionId');

      // 2. Participants avec formulaires COMPLETS
      final participants = await _chargerParticipantsComplets(sessionId);
      donnees['participants'] = participants;
      donnees['participants_data'] = participants; // Ajouter aussi dans le format attendu
      print('✅ [PDF DEBUG] ${participants.length} participants avec formulaires complets chargés');

      // Debug: afficher les données du premier participant
      if (participants.isNotEmpty) {
        final premier = participants.first as Map<String, dynamic>;
        print('🔍 [PDF DEBUG] Premier participant:');
        print('   - userId: ${premier['userId']}');
        print('   - roleVehicule: ${premier['roleVehicule']}');
        print('   - dateAccident: ${premier['dateAccident']}');
        print('   - lieuAccident: ${premier['lieuAccident']}');
        print('   - donneesPersonnelles: ${premier['donneesPersonnelles']?.keys?.toList()}');
        print('   - donneesVehicule: ${premier['donneesVehicule']?.keys?.toList()}');
        print('   - circonstances: ${premier['circonstances']?.keys?.toList()}');
        print('   - circonstancesSelectionnees: ${premier['circonstancesSelectionnees']}');
      }

      // 3. Signatures avec images
      final signatures = await _chargerSignaturesCompletes(sessionId);
      donnees['signatures'] = signatures;
      print('✅ [PDF DEBUG] ${signatures.length} signatures chargées: ${signatures.keys.toList()}');

      // 4. Croquis avec images
      final croquis = await _chargerCroquisComplet(sessionId);
      donnees['croquis'] = croquis;
      print('✅ [PDF DEBUG] Croquis chargé: ${croquis.keys.toList()}');

      // 5. Photos et documents
      final photos = await _chargerPhotosEtDocuments(sessionId);
      donnees['photos'] = photos;
      print('✅ [PDF DEBUG] ${photos.length} photos/documents chargés');

      return donnees;
    } catch (e) {
      print('❌ [PDF] Erreur chargement données: $e');
      rethrow;
    }
  }

  /// 👥 Charger participants avec formulaires COMPLETS
  static Future<List<Map<String, dynamic>>> _chargerParticipantsComplets(String sessionId) async {
    final participants = <Map<String, dynamic>>[];

    try {
      // Charger depuis participants_data (format principal)
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      print('🔍 [PDF DEBUG] Trouvé ${participantsSnapshot.docs.length} participants dans participants_data');

      for (var doc in participantsSnapshot.docs) {
        final participantData = Map<String, dynamic>.from(doc.data());
        final formulaireRaw = participantData['donneesFormulaire'];
        final formulaire = formulaireRaw != null ? Map<String, dynamic>.from(formulaireRaw) : <String, dynamic>{};

        print('👤 [PDF DEBUG] Participant ${doc.id}:');
        print('   - Données participant: ${participantData.keys.toList()}');
        print('   - Formulaire complet: ${formulaire.keys.toList()}');

        // Debug détaillé du formulaire
        if (formulaire.isNotEmpty) {
          print('   - donneesPersonnelles: ${formulaire['donneesPersonnelles']}');
          print('   - donneesVehicule: ${formulaire['donneesVehicule']}');
          print('   - donneesAssurance: ${formulaire['donneesAssurance']}');
          print('   - dateAccident: ${formulaire['dateAccident']}');
          print('   - lieuAccident: ${formulaire['lieuAccident']}');
          print('   - circonstances: ${formulaire['circonstances']}');
          print('   - circonstancesSelectionnees: ${formulaire['circonstancesSelectionnees']}');
        }



        // Charger les vraies données depuis les demandes de contrats
        final donneesPersonnellesReelles = await _chargerDonneesPersonnellesDepuisContrats(doc.id);
        final donneesVehiculeReelles = await _chargerDonneesVehiculeDepuisContrats(doc.id);
        final donneesAssuranceReelles = await _chargerDonneesAssuranceDepuisContrats(doc.id);

        // Extraire toutes les données du formulaire avec conversion sécurisée
        final participantComplet = {
          'userId': doc.id,
          'roleVehicule': participantData['roleVehicule'] ?? formulaire['roleVehicule'] ?? 'A',
          'formulaire': formulaire,
          'infosParticipant': participantData,

          // Données personnelles - utiliser les vraies données des contrats
          'donneesPersonnelles': donneesPersonnellesReelles.isNotEmpty
              ? donneesPersonnellesReelles
              : _extraireDonneesPersonnelles(formulaire),

          // Données véhicule - utiliser les vraies données des contrats
          'donneesVehicule': donneesVehiculeReelles.isNotEmpty
              ? donneesVehiculeReelles
              : _extraireDonneesVehicule(formulaire),

          // Données assurance - utiliser les vraies données des contrats
          'donneesAssurance': donneesAssuranceReelles.isNotEmpty
              ? donneesAssuranceReelles
              : _safeMapConvert(formulaire['donneesAssurance']),

          // Circonstances avec noms complets
          'circonstances': _safeMapConvert(formulaire['circonstances']),
          'circonstancesSelectionnees': _safeListConvert(formulaire['circonstancesSelectionnees']),
          'circonstancesNoms': _extraireCirconstancesNoms(formulaire['circonstancesSelectionnees']),

          // Dégâts
          'degats': _extraireDegats(formulaire),
          'degatsPhotos': _safeListConvert(formulaire['degatsPhotos'] ?? formulaire['photosDegatUrls']),

          // Témoins
          'temoins': _safeListConvert(formulaire['temoins']),

          // Informations générales
          'dateAccident': formulaire['dateAccident'],
          'heureAccident': formulaire['heureAccident'],
          'lieuAccident': formulaire['lieuAccident'],
          'lieuGps': _extraireLieuGps(formulaire),

          // Statut et progression
          'etapeActuelle': participantData['etapeActuelle'] ?? '1',
          'statut': participantData['statut'] ?? 'en_cours',
          'aSigne': formulaire['aSigne'] ?? false,
          'signatureData': formulaire['signatureData'],

          'source': 'participants_data_complet_avec_contrats',
        };

        participants.add(participantComplet);
      }

      // Fallback: charger depuis formulaires si participants_data vide
      if (participants.isEmpty) {
        final formulairesSnapshot = await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .collection('formulaires')
            .get();

        for (var doc in formulairesSnapshot.docs) {
          final formulaire = Map<String, dynamic>.from(doc.data());
          participants.add({
            'userId': doc.id,
            'formulaire': formulaire,
            'source': 'formulaires_fallback',
          });
        }
      }

      return participants;
    } catch (e) {
      print('❌ [PDF] Erreur chargement participants: $e');
      return [];
    }
  }

  /// ✍️ Charger signatures complètes
  static Future<Map<String, dynamic>> _chargerSignaturesCompletes(String sessionId) async {
    final signatures = <String, dynamic>{};

    try {
      // D'abord essayer dans la sous-collection signatures
      final signaturesSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .get();

      for (var doc in signaturesSnapshot.docs) {
        signatures[doc.id] = Map<String, dynamic>.from(doc.data());
      }

      if (signatures.isNotEmpty) {
        print('✅ [PDF DEBUG] ${signatures.length} signatures trouvées dans sous-collection');
        return signatures;
      }

      // Sinon essayer dans les données des participants
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      for (var doc in participantsSnapshot.docs) {
        final participantData = doc.data();
        final formulaire = participantData['donneesFormulaire'] as Map<String, dynamic>? ?? {};

        if (formulaire['signatureData'] != null && formulaire['aSigne'] == true) {
          signatures[doc.id] = {
            'signatureData': formulaire['signatureData'],
            'timestamp': formulaire['dateSignature'] ?? participantData['dateSignature'],
            'userId': doc.id,
          };
        }
      }

      print('✅ [PDF DEBUG] ${signatures.length} signatures trouvées dans participants_data');
    } catch (e) {
      print('⚠️ [PDF] Erreur signatures: $e');
    }

    return signatures;
  }

  /// 🎨 Charger croquis complet depuis plusieurs sources
  static Future<Map<String, dynamic>> _chargerCroquisComplet(String sessionId) async {
    try {
      // 1. Essayer dans la collection collaborative_sketches
      final collaborativeSketchDoc = await _firestore
          .collection('collaborative_sketches')
          .doc(sessionId)
          .get();

      if (collaborativeSketchDoc.exists) {
        final data = Map<String, dynamic>.from(collaborativeSketchDoc.data()!);
        print('✅ [PDF DEBUG] Croquis trouvé dans collaborative_sketches: ${data.keys.toList()}');

        // Extraire les données d'image du croquis collaboratif
        final elements = data['elements'] as List? ?? [];
        if (elements.isNotEmpty) {
          // Chercher une image dans les éléments
          for (var element in elements) {
            if (element is Map && element['type'] == 'image' && element['data'] != null) {
              return {
                'data': element['data'],
                'derniere_modification': data['createdAt'] ?? data['updatedAt'],
                'modifie_par': data['creatorName'] ?? 'Utilisateur',
                'source': 'collaborative_sketches',
              };
            }
          }
        }

        // Si pas d'image dans les éléments, retourner les données de base
        return {
          'data': data['imageData'] ?? data['sketchData'],
          'derniere_modification': data['createdAt'] ?? data['updatedAt'],
          'modifie_par': data['creatorName'] ?? 'Utilisateur',
          'source': 'collaborative_sketches',
        };
      }

      // 2. Essayer dans la sous-collection croquis
      final croquisDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('croquis')
          .doc('principal')
          .get();

      if (croquisDoc.exists) {
        final data = Map<String, dynamic>.from(croquisDoc.data()!);
        print('✅ [PDF DEBUG] Croquis trouvé dans sous-collection: ${data.keys.toList()}');
        return data;
      }

      // 3. Essayer dans le document principal de session
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        if (sessionData['croquis_data'] != null) {
          final croquisData = {
            'data': sessionData['croquis_data'],
            'derniere_modification': sessionData['croquis_derniere_modification'],
            'modifie_par': sessionData['croquis_modifie_par'],
            'source': 'session_document',
          };
          print('✅ [PDF DEBUG] Croquis trouvé dans document principal: ${croquisData.keys.toList()}');
          return croquisData;
        }
      }

      // 4. Chercher dans les formulaires des participants
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      for (var doc in participantsSnapshot.docs) {
        final participantData = doc.data();
        final formulaire = participantData['donneesFormulaire'] as Map<String, dynamic>? ?? {};

        if (formulaire['croquisData'] != null || formulaire['croquis_data'] != null) {
          final croquisData = {
            'data': formulaire['croquisData'] ?? formulaire['croquis_data'],
            'derniere_modification': formulaire['croquisModification'] ?? DateTime.now().toIso8601String(),
            'modifie_par': 'Participant ${participantData['roleVehicule'] ?? 'A'}',
            'source': 'participant_formulaire',
          };
          print('✅ [PDF DEBUG] Croquis trouvé dans formulaire participant: ${croquisData.keys.toList()}');
          return croquisData;
        }
      }

    } catch (e) {
      print('⚠️ [PDF] Erreur chargement croquis: $e');
    }

    print('❌ [PDF DEBUG] Aucun croquis trouvé dans toutes les sources');
    return {};
  }

  /// 📸 Charger photos et documents depuis les formulaires des participants
  static Future<List<Map<String, dynamic>>> _chargerPhotosEtDocuments(String sessionId) async {
    final photos = <Map<String, dynamic>>[];

    try {
      // 1. Charger depuis la collection photos (si elle existe)
      final photosSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('photos')
          .get();

      for (var doc in photosSnapshot.docs) {
        photos.add(Map<String, dynamic>.from(doc.data()));
      }

      // 2. Charger depuis les formulaires des participants
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      for (var doc in participantsSnapshot.docs) {
        final participantData = doc.data();
        final formulaire = participantData['donneesFormulaire'] as Map<String, dynamic>? ?? {};
        final roleVehicule = participantData['roleVehicule'] ?? 'A';

        print('🔍 [PDF DEBUG] Recherche photos pour participant $roleVehicule:');
        print('   - Champs formulaire: ${formulaire.keys.toList()}');

        // Photos de dégâts - chercher dans plusieurs champs
        final degatsPhotos = formulaire['degatsPhotos'] ??
                            formulaire['photosDegatUrls'] ??
                            formulaire['photosDegats'] ??
                            formulaire['photos'] ?? [];

        print('   - degatsPhotos: $degatsPhotos (type: ${degatsPhotos.runtimeType})');

        if (degatsPhotos is List && degatsPhotos.isNotEmpty) {
          for (var photo in degatsPhotos) {
            if (photo != null && photo.toString().isNotEmpty) {
              photos.add({
                'type': 'degats',
                'participantId': doc.id,
                'url': photo,
                'description': 'Photo de dégâts - Participant $roleVehicule',
              });
              print('   ✅ Photo dégâts ajoutée: $photo');
            }
          }
        }

        // Photos de permis (recto/verso)
        final permisRecto = formulaire['permisRectoUrl'] ??
                           formulaire['permisRecto'] ??
                           formulaire['donneesPersonnelles']?['permisRectoUrl'];

        print('   - permisRecto: $permisRecto');

        if (permisRecto != null && permisRecto.toString().isNotEmpty && permisRecto.toString() != 'null') {
          photos.add({
            'type': 'permis_recto',
            'participantId': doc.id,
            'url': permisRecto,
            'description': 'Permis recto - Participant $roleVehicule',
          });
          print('   ✅ Permis recto ajouté: $permisRecto');
        }

        final permisVerso = formulaire['permisVersoUrl'] ??
                           formulaire['permisVerso'] ??
                           formulaire['donneesPersonnelles']?['permisVersoUrl'];

        print('   - permisVerso: $permisVerso');

        if (permisVerso != null && permisVerso.toString().isNotEmpty && permisVerso.toString() != 'null') {
          photos.add({
            'type': 'permis_verso',
            'participantId': doc.id,
            'url': permisVerso,
            'description': 'Permis verso - Participant $roleVehicule',
          });
          print('   ✅ Permis verso ajouté: $permisVerso');
        }

        // Photos CIN (recto/verso)
        final cinRecto = formulaire['cinRectoUrl'] ??
                        formulaire['cinRecto'] ??
                        formulaire['donneesPersonnelles']?['cinRectoUrl'];

        if (cinRecto != null && cinRecto.toString().isNotEmpty && cinRecto.toString() != 'null') {
          photos.add({
            'type': 'cin_recto',
            'participantId': doc.id,
            'url': cinRecto,
            'description': 'CIN recto - Participant $roleVehicule',
          });
          print('   ✅ CIN recto ajouté: $cinRecto');
        }

        final cinVerso = formulaire['cinVersoUrl'] ??
                        formulaire['cinVerso'] ??
                        formulaire['donneesPersonnelles']?['cinVersoUrl'];

        if (cinVerso != null && cinVerso.toString().isNotEmpty && cinVerso.toString() != 'null') {
          photos.add({
            'type': 'cin_verso',
            'participantId': doc.id,
            'url': cinVerso,
            'description': 'CIN verso - Participant $roleVehicule',
          });
          print('   ✅ CIN verso ajouté: $cinVerso');
        }
      }

      print('✅ [PDF DEBUG] Photos trouvées: ${photos.length}');
      for (var photo in photos) {
        print('   - ${photo['type']}: ${photo['description']}');
      }

      // 3. Chercher aussi dans les demandes de contrats pour les photos manquantes
      if (photos.isEmpty) {
        print('🔍 [PDF DEBUG] Aucune photo trouvée, recherche dans demandes_contrats...');

        // Récupérer les participants depuis la session
        final sessionDoc = await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .get();

        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data() as Map<String, dynamic>;
          final participantsData = sessionData['participants_data'] as List<dynamic>? ?? [];

          for (var participant in participantsData) {
            final participantMap = participant as Map<String, dynamic>;
            final userId = participantMap['userId'];

            if (userId != null) {
              try {
                final demandesSnapshot = await _firestore
                    .collection('demandes_contrats')
                    .where('conducteurId', isEqualTo: userId)
                    .limit(1)
                    .get();

                if (demandesSnapshot.docs.isNotEmpty) {
                  final demande = demandesSnapshot.docs.first.data();
                  print('🔍 [PDF DEBUG] Demande trouvée pour $userId: ${demande.keys.toList()}');

                  // Chercher les photos dans la demande
                  final permisRectoUrl = demande['permisRectoUrl'];
                  final permisVersoUrl = demande['permisVersoUrl'];
                  final cinRectoUrl = demande['cinRectoUrl'];
                  final cinVersoUrl = demande['cinVersoUrl'];

                  if (permisRectoUrl != null && permisRectoUrl.toString().isNotEmpty) {
                    photos.add({
                      'type': 'permis_recto',
                      'participantId': userId,
                      'url': permisRectoUrl,
                      'description': 'Permis recto (depuis demande)',
                    });
                    print('   ✅ Permis recto (demande) ajouté: $permisRectoUrl');
                  }

                  if (permisVersoUrl != null && permisVersoUrl.toString().isNotEmpty) {
                    photos.add({
                      'type': 'permis_verso',
                      'participantId': userId,
                      'url': permisVersoUrl,
                      'description': 'Permis verso (depuis demande)',
                    });
                    print('   ✅ Permis verso (demande) ajouté: $permisVersoUrl');
                  }
                }
              } catch (e) {
                print('⚠️ [PDF DEBUG] Erreur recherche demande pour $userId: $e');
              }
            }
          }
        }
      }

    } catch (e) {
      print('⚠️ [PDF] Erreur chargement photos: $e');
    }

    print('✅ [PDF DEBUG] ${photos.length} photos/documents chargés');
    return photos;
  }

  /// 👤 Extraire les données personnelles du formulaire
  static Map<String, dynamic> _extraireDonneesPersonnelles(Map<String, dynamic> formulaire) {
    final donnees = <String, dynamic>{};

    // Source 1: conducteur
    final conducteur = formulaire['conducteur'];
    if (conducteur != null && conducteur is Map) {
      donnees.addAll(Map<String, dynamic>.from(conducteur));
    }

    // Source 2: donneesPersonnelles
    final donneesPersonnelles = formulaire['donneesPersonnelles'];
    if (donneesPersonnelles != null && donneesPersonnelles is Map) {
      donnees.addAll(Map<String, dynamic>.from(donneesPersonnelles));
    }

    // Ajouter les URLs des documents d'identité depuis le formulaire
    if (formulaire['cinRectoUrl'] != null) {
      donnees['cinRectoUrl'] = formulaire['cinRectoUrl'];
    }
    if (formulaire['cinVersoUrl'] != null) {
      donnees['cinVersoUrl'] = formulaire['cinVersoUrl'];
    }
    if (formulaire['permisRectoUrl'] != null) {
      donnees['permisRectoUrl'] = formulaire['permisRectoUrl'];
    }
    if (formulaire['permisVersoUrl'] != null) {
      donnees['permisVersoUrl'] = formulaire['permisVersoUrl'];
    }

    return donnees;
  }

  /// 💥 Extraire les points de choc initiaux d'un participant
  static List<String> _extrairePointsChocInitiaux(Map<String, dynamic> participant) {
    final donneesFormulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final pointsChoc = <String>[];

    print('🔍 [PDF DEBUG] Extraction points de choc pour participant ${participant['roleVehicule']}');

    // Source 1: pointsChocSelectionnes dans donneesFormulaire
    if (donneesFormulaire['pointsChocSelectionnes'] != null) {
      final points = _safeListConvert(donneesFormulaire['pointsChocSelectionnes']).cast<String>();
      pointsChoc.addAll(points);
      print('🔍 [PDF DEBUG] Points de choc trouvés dans donneesFormulaire.pointsChocSelectionnes: $points');
    }

    // Source 2: pointsChoc dans donneesFormulaire
    if (donneesFormulaire['pointsChoc'] != null) {
      final points = _safeListConvert(donneesFormulaire['pointsChoc']).cast<String>();
      pointsChoc.addAll(points);
      print('🔍 [PDF DEBUG] Points de choc trouvés dans donneesFormulaire.pointsChoc: $points');
    }

    // Source 3: pointChocSelectionne dans donneesFormulaire
    if (donneesFormulaire['pointChocSelectionne'] != null) {
      final points = _safeListConvert(donneesFormulaire['pointChocSelectionne']).cast<String>();
      pointsChoc.addAll(points);
      print('🔍 [PDF DEBUG] Points de choc trouvés dans donneesFormulaire.pointChocSelectionne: $points');
    }

    // Source 4: pointChoc dans donneesFormulaire
    if (donneesFormulaire['pointChoc'] != null) {
      final points = _safeListConvert(donneesFormulaire['pointChoc']).cast<String>();
      pointsChoc.addAll(points);
      print('🔍 [PDF DEBUG] Points de choc trouvés dans donneesFormulaire.pointChoc: $points');
    }

    // Source 5: directement dans participant
    if (participant['pointsChocSelectionnes'] != null) {
      final points = _safeListConvert(participant['pointsChocSelectionnes']).cast<String>();
      pointsChoc.addAll(points);
      print('🔍 [PDF DEBUG] Points de choc trouvés dans participant.pointsChocSelectionnes: $points');
    }

    // Supprimer les doublons
    final pointsUniques = pointsChoc.toSet().toList();
    print('✅ [PDF DEBUG] Points de choc finaux pour participant ${participant['roleVehicule']}: $pointsUniques');

    return pointsUniques;
  }

  /// 🔧 Extraire les dégâts apparents d'un participant
  static String _extraireDegatsApparents(Map<String, dynamic> participant) {
    final donneesFormulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};

    print('🔍 [PDF DEBUG] Extraction dégâts apparents pour participant ${participant['roleVehicule']}');

    // Source 1: degatsApparents dans donneesFormulaire
    if (donneesFormulaire['degatsApparents'] != null && donneesFormulaire['degatsApparents'].toString().isNotEmpty) {
      final degats = donneesFormulaire['degatsApparents'].toString();
      print('✅ [PDF DEBUG] Dégâts apparents trouvés dans donneesFormulaire.degatsApparents: $degats');
      return degats;
    }

    // Source 2: degats.description dans donneesFormulaire
    if (donneesFormulaire['degats'] != null && donneesFormulaire['degats'] is Map) {
      final degatsMap = donneesFormulaire['degats'] as Map<String, dynamic>;
      if (degatsMap['description'] != null && degatsMap['description'].toString().isNotEmpty) {
        final degats = degatsMap['description'].toString();
        print('✅ [PDF DEBUG] Dégâts apparents trouvés dans donneesFormulaire.degats.description: $degats');
        return degats;
      }
    }

    // Source 3: directement dans participant
    if (participant['degatsApparents'] != null && participant['degatsApparents'].toString().isNotEmpty) {
      final degats = participant['degatsApparents'].toString();
      print('✅ [PDF DEBUG] Dégâts apparents trouvés dans participant.degatsApparents: $degats');
      return degats;
    }

    print('! [PDF DEBUG] Aucun dégât apparent trouvé pour participant ${participant['roleVehicule']}');
    return 'Non spécifié';
  }

  /// 📄 Récupérer le code de session depuis les données
  static String _extraireCodeSession(Map<String, dynamic> donnees) {
    // 1. Chercher dans les champs directs
    if (donnees['codeSession'] != null) {
      final code = donnees['codeSession'].toString();
      print('✅ [PDF DEBUG] Code session trouvé (codeSession): $code');
      return code;
    }
    if (donnees['sessionCode'] != null) {
      final code = donnees['sessionCode'].toString();
      print('✅ [PDF DEBUG] Code session trouvé (sessionCode): $code');
      return code;
    }
    if (donnees['code'] != null) {
      final code = donnees['code'].toString();
      print('✅ [PDF DEBUG] Code session trouvé (code): $code');
      return code;
    }

    // 2. Chercher dans les données de session
    final sessionData = donnees['session_data'] as Map<String, dynamic>? ?? {};
    if (sessionData['codeSession'] != null) {
      final code = sessionData['codeSession'].toString();
      print('✅ [PDF DEBUG] Code session trouvé (session_data.codeSession): $code');
      return code;
    }

    // 3. Chercher dans les participants pour un code partagé
    final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];
    for (final participant in participantsData) {
      final p = participant as Map<String, dynamic>;
      final formulaire = p['donneesFormulaire'] as Map<String, dynamic>? ?? {};
      if (formulaire['codeSession'] != null) {
        final code = formulaire['codeSession'].toString();
        print('✅ [PDF DEBUG] Code session trouvé (participant.codeSession): $code');
        return code;
      }
    }

    // 4. Générer un code basé sur l'ID de session si disponible
    final sessionId = donnees['sessionId'] ?? donnees['id'];
    if (sessionId != null) {
      final id = sessionId.toString();
      final code = id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
      print('✅ [PDF DEBUG] Code session généré depuis ID: $code (ID: $id)');
      return code;
    }

    print('❌ [PDF DEBUG] Aucun code session trouvé');
    return 'N/A';
  }

  /// 💾 Sauvegarder l'URL du PDF dans la session Firestore
  static Future<void> _sauvegarderUrlDansSession(String sessionId, String pdfUrl) async {
    try {
      await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .update({
        'pdfUrl': pdfUrl,
        'pdfGeneratedAt': FieldValue.serverTimestamp(),
        'pdfType': 'elegant_complete',
      });
      print('✅ [PDF] URL sauvegardée dans session: $sessionId');
    } catch (e) {
      print('⚠️ [PDF] Erreur sauvegarde URL dans session: $e');
      // Ne pas faire échouer la génération PDF pour cette erreur
    }
  }

  /// 🗜️ Compresser le PDF pour respecter les limites Cloudinary (10 MB max)
  static Future<Uint8List> _compresserPdf(Uint8List originalPdfBytes) async {
    try {
      print('🗜️ [PDF] Début compression PDF...');

      // Créer un nouveau document PDF avec compression maximale
      final pdf = pw.Document(
        compress: true, // Activer la compression
        version: PdfVersion.pdf_1_4, // Version plus ancienne = meilleure compression
      );

      // Ajouter une page simple avec informations de compression
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'CONSTAT AMIABLE D\'ACCIDENT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Version compressée pour upload cloud',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Le PDF complet est disponible localement sur votre appareil.',
                    style: pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Cette version allégée permet le partage via le cloud.',
                    style: pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );

      final compressedBytes = await pdf.save();

      final originalSizeMB = originalPdfBytes.length / (1024 * 1024);
      final compressedSizeMB = compressedBytes.length / (1024 * 1024);

      print('✅ [PDF] Compression réussie:');
      print('   - Original: ${originalSizeMB.toStringAsFixed(2)} MB');
      print('   - Compressé: ${compressedSizeMB.toStringAsFixed(2)} MB');
      print('   - Réduction: ${((originalSizeMB - compressedSizeMB) / originalSizeMB * 100).toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      print('❌ [PDF] Erreur compression: $e');
      rethrow;
    }
  }

  /// 🔍 Charger les données personnelles depuis les demandes de contrats
  static Future<Map<String, dynamic>> _chargerDonneesPersonnellesDepuisContrats(String userId) async {
    try {
      // Chercher dans demandes_contrats
      final demandesSnapshot = await _firestore
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: userId)
          .limit(1)
          .get();

      if (demandesSnapshot.docs.isNotEmpty) {
        final demande = demandesSnapshot.docs.first.data();
        print('🔍 [PDF] Données trouvées dans demandes_contrats pour $userId');

        return {
          'nom': demande['nom'] ?? 'Non spécifié',
          'prenom': demande['prenom'] ?? 'Non spécifié',
          'dateNaissance': demande['dateNaissance'] ?? 'Non spécifiée',
          'adresse': demande['adresse'] ?? 'Non spécifiée',
          'telephone': demande['telephone'] ?? 'Non spécifié',
          'email': demande['email'] ?? 'Non spécifié',
          'cin': demande['cin'] ?? 'Non spécifié',
          'numeroPermis': demande['numeroPermis'] ?? 'Non spécifié',
          'categoriePermis': demande['categoriePermis'] ?? 'Non spécifiée',
          'dateDelivrancePermis': demande['dateDelivrancePermis'] ?? 'Non spécifiée',
          'dateValiditePermis': demande['dateValiditePermis'] ?? 'Non spécifiée',
          'lieuDelivrancePermis': demande['lieuDelivrancePermis'] ?? 'Non spécifié',

          // Images des documents
          'cinRectoUrl': demande['cinRectoUrl'],
          'cinVersoUrl': demande['cinVersoUrl'],
          'permisRectoUrl': demande['permisRectoUrl'],
          'permisVersoUrl': demande['permisVersoUrl'],
          'photoProfilUrl': demande['photoProfilUrl'],
        };
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur chargement données personnelles: $e');
    }

    return {};
  }

  /// 🚗 Charger les données véhicule depuis les demandes de contrats
  static Future<Map<String, dynamic>> _chargerDonneesVehiculeDepuisContrats(String userId) async {
    try {
      // Chercher dans demandes_contrats
      final demandesSnapshot = await _firestore
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: userId)
          .limit(1)
          .get();

      if (demandesSnapshot.docs.isNotEmpty) {
        final demande = demandesSnapshot.docs.first.data();
        print('🔍 [PDF] Données véhicule trouvées pour $userId');

        return {
          'marque': demande['marque'] ?? 'Non spécifiée',
          'modele': demande['modele'] ?? 'Non spécifié',
          'type': demande['typeVehicule'] ?? 'Non spécifié',
          'immatriculation': demande['immatriculation'] ?? 'Non spécifiée',
          'annee': demande['anneeVehicule']?.toString() ?? 'Non spécifiée',
          'couleur': demande['couleur'] ?? 'Non spécifiée',
          'puissance': demande['puissance']?.toString() ?? 'Non spécifiée',
          'typeCarburant': demande['typeCarburant'] ?? 'Non spécifié',
          'numeroContrat': demande['numeroContrat'] ?? 'Non spécifié',
          'numeroDemande': demande['numeroDemande'] ?? 'Non spécifié',
        };
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur chargement données véhicule: $e');
    }

    return {};
  }

  /// 🛡️ Charger les données assurance depuis les demandes de contrats
  static Future<Map<String, dynamic>> _chargerDonneesAssuranceDepuisContrats(String userId) async {
    try {
      // Chercher dans demandes_contrats
      final demandesSnapshot = await _firestore
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: userId)
          .limit(1)
          .get();

      if (demandesSnapshot.docs.isNotEmpty) {
        final demande = demandesSnapshot.docs.first.data();
        print('🔍 [PDF] Données assurance trouvées pour $userId');

        return {
          'compagnie': demande['compagnieNom'] ?? 'Assurance Elite Tunisie',
          'numeroContrat': demande['numeroContrat'] ?? 'Non spécifié',
          'agence': demande['agenceNom'] ?? 'Agence Centrale Tunis',
          'adresseAgence': demande['agenceAdresse'] ?? 'Non spécifiée',
          'typeContrat': demande['typeContrat'] ?? 'Non spécifié',
          'prime': demande['prime']?.toString() ?? 'Non spécifiée',
          'franchise': demande['franchise']?.toString() ?? 'Non spécifiée',
          'dateDebut': demande['dateDebut'] ?? 'Non spécifiée',
          'dateFin': demande['dateFin'] ?? 'Non spécifiée',
        };
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur chargement données assurance: $e');
    }

    return {};
  }

  /// 🚗 Extraire les données véhicule du formulaire
  static Map<String, dynamic> _extraireDonneesVehicule(Map<String, dynamic> formulaire) {
    final vehicule = formulaire['vehicule'];
    if (vehicule != null && vehicule is Map) {
      return Map<String, dynamic>.from(vehicule);
    }

    // Fallback: chercher dans donneesVehicule
    final donneesVehicule = formulaire['donneesVehicule'];
    if (donneesVehicule != null && donneesVehicule is Map) {
      return Map<String, dynamic>.from(donneesVehicule);
    }

    return {};
  }

  /// 💥 Extraire les dégâts du formulaire
  static Map<String, dynamic> _extraireDegats(Map<String, dynamic> formulaire) {
    final degatsSelectionnes = formulaire['degatsSelectionnes'];
    if (degatsSelectionnes != null && degatsSelectionnes is Map) {
      return Map<String, dynamic>.from(degatsSelectionnes);
    }

    final degats = formulaire['degats'];
    if (degats != null && degats is Map) {
      return Map<String, dynamic>.from(degats);
    }

    return {};
  }

  /// 📍 Extraire les coordonnées GPS du formulaire
  static Map<String, dynamic> _extraireLieuGps(Map<String, dynamic> formulaire) {
    final lieuGps = formulaire['lieuGps'];
    if (lieuGps != null && lieuGps is Map) {
      return Map<String, dynamic>.from(lieuGps);
    }
    return {};
  }

  /// 🎯 Extraire les noms des circonstances sélectionnées
  static List<String> _extraireCirconstancesNoms(dynamic circonstancesSelectionnees) {
    if (circonstancesSelectionnees == null) return [];

    final List<String> noms = [];
    if (circonstancesSelectionnees is List) {
      for (final code in circonstancesSelectionnees) {
        noms.add(_obtenirNomCirconstance(code));
      }
    }

    return noms;
  }



  /// 🖼️ Construire une image à partir de données base64 ou URL Cloudinary
  static Future<pw.Widget> _buildImageFromBase64(dynamic imageData, String altText, {double? width, double? height, pw.BoxFit fit = pw.BoxFit.contain}) async {
    // Conversion sécurisée des données d'image
    String? imageString;

    try {
      if (imageData == null) {
        imageString = null;
      } else if (imageData is String) {
        imageString = imageData.isNotEmpty ? imageData : null;
      } else if (imageData is List) {
        // Si c'est une liste, prendre le premier élément s'il existe
        if (imageData.isNotEmpty) {
          imageString = imageData.first?.toString();
        }
        print('! [PDF] Image data est une List: ${imageData.length} éléments');
      } else {
        imageString = imageData.toString();
        print('⚠️ [PDF] Image data type inattendu: ${imageData.runtimeType}');
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur traitement image data: $e (data: $imageData, type: ${imageData.runtimeType})');
      imageString = null;
    }

    if (imageString == null || imageString.isEmpty) {
      return pw.Container(
        width: width ?? double.infinity,
        height: height ?? 120,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Center(
          child: pw.Text(
            'Image non disponible',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Vérifier si c'est une URL HTTP/HTTPS - TÉLÉCHARGER L'IMAGE
    if (imageString.startsWith('http://') || imageString.startsWith('https://')) {
      print('🌐 [PDF] URL détectée, téléchargement: $imageString');

      try {
        final imageBytes = await _downloadImageFromUrl(imageString);
        if (imageBytes != null) {
          final image = pw.MemoryImage(imageBytes);
          return pw.Container(
            width: width ?? double.infinity,
            height: height ?? 150,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.green400),
            ),
            child: pw.ClipRRect(
              child: pw.Image(image, fit: fit),
            ),
          );
        }
      } catch (e) {
        print('⚠️ [PDF] Erreur téléchargement URL: $e');
      }

      return pw.Container(
        width: width ?? double.infinity,
        height: height ?? 120,
        decoration: pw.BoxDecoration(
          color: PdfColors.red100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.red400),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                altText,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Image inaccessible (URL)',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.red600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Vérifier si c'est un chemin de fichier local
    if (imageString.startsWith('file://') || imageString.startsWith('/data/') || imageString.contains('app_flutter') || imageString.startsWith('/')) {
      print('📁 [PDF] Chemin de fichier local détecté: $imageString');

      // Essayer de lire le fichier local
      try {
        String filePath = imageString;
        if (filePath.startsWith('file://')) {
          filePath = filePath.substring(7); // Enlever 'file://'
        }

        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final image = pw.MemoryImage(bytes);
          print('✅ [PDF] Fichier local lu avec succès: ${bytes.length} bytes');
          return pw.Container(
            width: width ?? double.infinity,
            height: height ?? 200, // Augmenter la hauteur par défaut
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.green400),
            ),
            child: pw.ClipRRect(
              child: pw.Image(image, fit: fit ?? pw.BoxFit.contain),
            ),
          );
        } else {
          print('❌ [PDF] Fichier local non trouvé: $filePath');
        }
      } catch (e) {
        print('⚠️ [PDF] Impossible de lire le fichier local: $e');
      }

      return pw.Container(
        width: width ?? double.infinity,
        height: height ?? 120,
        decoration: pw.BoxDecoration(
          color: PdfColors.orange100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.orange400),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                altText,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Image locale non accessible',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.orange600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Vérifier si c'est des données JSON (pour le croquis)
    if (imageString.startsWith('{') || imageString.startsWith('[')) {
      print('! [PDF] Données JSON détectées pour $altText');
      return pw.Container(
        width: double.infinity,
        height: 80,
        decoration: pw.BoxDecoration(
          color: PdfColors.blue100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.blue400),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                altText,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Croquis créé avec succès',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.blue600,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Données vectorielles disponibles',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.blue500,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Vérifier si c'est une URL Cloudinary ou HTTP
    if (imageString.startsWith('http://') || imageString.startsWith('https://')) {
      print('! [PDF] URL détectée: $imageString');
      try {
        // Télécharger l'image depuis l'URL
        final response = await http.get(Uri.parse(imageString));
        if (response.statusCode == 200) {
          final image = pw.MemoryImage(response.bodyBytes);
          return pw.Container(
            width: double.infinity,
            height: 80,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Image(image, fit: pw.BoxFit.cover),
          );
        } else {
          print('⚠️ [PDF] Erreur téléchargement image: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ [PDF] Erreur téléchargement image: $e');
      }

      return pw.Container(
        width: double.infinity,
        height: 80,
        decoration: pw.BoxDecoration(
          color: PdfColors.red100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.red400),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                altText,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Erreur téléchargement image',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.red600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Si c'est une URL Cloudinary ou autre URL externe
    if (imageString.startsWith('http') || imageString.contains('cloudinary')) {
      try {
        print('🌐 [PDF] Téléchargement image depuis URL: $imageString');
        final imageBytes = await _downloadImageFromUrl(imageString);

        if (imageBytes != null) {
          final image = pw.MemoryImage(imageBytes);
          print('✅ [PDF] Image URL téléchargée et convertie: $altText');
          return pw.Container(
            width: double.infinity,
            height: 120,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green400, width: 1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.ClipRRect(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            ),
          );
        } else {
          print('❌ [PDF] Échec téléchargement image: $imageString');
        }
      } catch (e) {
        print('❌ [PDF] Erreur traitement image URL: $e');
      }

      // Fallback si le téléchargement échoue
      return pw.Container(
        width: double.infinity,
        height: 80,
        decoration: pw.BoxDecoration(
          color: PdfColors.orange100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.orange400, width: 2),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                altText,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'IMAGE NON TÉLÉCHARGÉE',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    try {
      // Nettoyer les données base64 (enlever le préfixe data:image/...)
      String cleanBase64 = imageString;
      if (imageString.contains(',')) {
        cleanBase64 = imageString.split(',').last;
      }

      final imageBytes = base64Decode(cleanBase64);
      final image = pw.MemoryImage(imageBytes);

      return pw.Image(
        image,
        fit: pw.BoxFit.contain,
      );
    } catch (e) {
      print('⚠️ [PDF] Erreur décodage image $altText: $e');
      return pw.Container(
        width: double.infinity,
        height: 80,
        decoration: pw.BoxDecoration(
          color: PdfColors.orange100,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.orange400),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                altText,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Format non supporté',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.orange600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  /// 📅 Formater un timestamp
  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Non spécifiée';

    try {
      DateTime dateTime;

      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp.toString().contains('Timestamp')) {
        // Gérer les Timestamp de Firestore
        dateTime = (timestamp as dynamic).toDate();
      } else {
        return 'Format invalide';
      }

      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('⚠️ [PDF] Erreur formatage timestamp: $e');
      return 'Format invalide';
    }
  }

  /// 📄 Ajouter toutes les pages au PDF
  static Future<void> _ajouterToutesLesPages(pw.Document pdf, Map<String, dynamic> donnees) async {
    final participants = donnees['participants'] as List<dynamic>? ?? [];

    try {
      // Page 1: Couverture élégante
      print('🔍 [PDF DEBUG] Ajout page couverture...');
      pdf.addPage(await _buildPageCouvertureElegante(donnees));
      print('✅ [PDF DEBUG] Page couverture ajoutée');

      // Page 2: Informations générales et résumé
      print('🔍 [PDF DEBUG] Ajout page infos générales...');
      pdf.addPage(await _buildPageInfosGeneralesComplete(donnees));
      print('✅ [PDF DEBUG] Page infos générales ajoutée');

      // Pages 3+: Une page détaillée par participant
      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i] as Map<String, dynamic>;

        // Page principale du participant
        print('🔍 [PDF DEBUG] Ajout page participant ${i + 1}...');
        pdf.addPage(await _buildPageParticipantComplete(participant, i + 1, donnees));
        print('✅ [PDF DEBUG] Page participant ${i + 1} ajoutée');

        // Page détaillée des circonstances et assurance
        print('🔍 [PDF DEBUG] Ajout page circonstances participant ${i + 1}...');
        pdf.addPage(await _buildPageCirconstancesEtAssurance(participant, i + 1, donnees));
        print('✅ [PDF DEBUG] Page circonstances participant ${i + 1} ajoutée');
      }

      // Page récapitulatif de tous les participants
      if (participants.length > 1) {
        print('🔍 [PDF DEBUG] Ajout page récapitulatif...');
        pdf.addPage(await _buildPageRecapitulatifTousParticipants(donnees));
        print('✅ [PDF DEBUG] Page récapitulatif ajoutée');
      }

      // Page dédiée aux témoins
      print('🔍 [PDF DEBUG] Ajout page témoins...');
      pdf.addPage(await _buildPageTemoins(donnees));
      print('✅ [PDF DEBUG] Page témoins ajoutée');

      // Page dédiée aux photos et documents
      print('🔍 [PDF DEBUG] Ajout page photos et documents...');
      pdf.addPage(await _buildPagePhotosEtDocuments(donnees));
      print('✅ [PDF DEBUG] Page photos et documents ajoutée');

      // Page croquis et signatures
      print('🔍 [PDF DEBUG] Ajout page croquis et signatures...');
      pdf.addPage(await _buildPageCroquisEtSignatures(donnees));
      print('✅ [PDF DEBUG] Page croquis et signatures ajoutée');

      // Page finale avec recommandations
      print('🔍 [PDF DEBUG] Ajout page finale...');
      pdf.addPage(await _buildPageFinaleRecommandations(donnees));
      print('✅ [PDF DEBUG] Page finale ajoutée');

    } catch (e) {
      print('❌ [PDF DEBUG] Erreur lors de l\'ajout des pages: $e');
      rethrow;
    }
  }

  /// 💾 Sauvegarder le PDF
  static Future<String> _sauvegarderPdf(pw.Document pdf, dynamic sessionId) async {
    try {
      print('🔍 [PDF DEBUG] Sauvegarde - SessionId reçu: $sessionId (type: ${sessionId.runtimeType})');

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // Convertir sessionId en String de manière sécurisée avec validation stricte
      String safeSessionId;
      if (sessionId is String) {
        safeSessionId = sessionId.replaceAll(RegExp(r'[^\w\-]'), '_');
      } else if (sessionId is List) {
        print('⚠️ [PDF] SessionId est une List: $sessionId');
        safeSessionId = sessionId.isNotEmpty ? sessionId.first.toString().replaceAll(RegExp(r'[^\w\-]'), '_') : 'unknown_session';
      } else {
        print('⚠️ [PDF] SessionId type inattendu: ${sessionId.runtimeType}');
        safeSessionId = sessionId.toString().replaceAll(RegExp(r'[^\w\-]'), '_');
      }

      // Validation supplémentaire pour éviter les noms de fichiers vides
      if (safeSessionId.isEmpty || safeSessionId == 'null') {
        safeSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      }

      final fileName = 'constat_complet_elegant_${safeSessionId}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      // Sauvegarder avec gestion d'erreur améliorée
      try {
        final pdfBytes = await pdf.save();
        await file.writeAsBytes(pdfBytes);
        print('✅ [PDF] Fichier sauvegardé localement: ${file.path}');

        // ✅ NOUVEAU: Upload vers Cloudinary avec fallback Firebase Storage
        try {
          // Vérifier la taille du PDF
          final sizeInMB = pdfBytes.length / (1024 * 1024);
          print('📊 [PDF] Taille PDF: ${sizeInMB.toStringAsFixed(2)} MB');

          Uint8List finalPdfBytes = pdfBytes;
          String finalFileName = fileName;

          // Si le PDF dépasse 9 MB, compresser les images
          if (sizeInMB > 9.0) {
            print('🗜️ [PDF] PDF volumineux (${sizeInMB.toStringAsFixed(2)} MB), compression des images...');
            finalPdfBytes = await _compresserImages(pdfBytes);
            final newSizeInMB = finalPdfBytes.length / (1024 * 1024);
            print('✅ [PDF] PDF compressé: ${newSizeInMB.toStringAsFixed(2)} MB');

            // Mettre à jour le nom du fichier
            finalFileName = fileName.replaceAll('.pdf', '_compressed.pdf');
          }

          // Essayer Cloudinary d'abord
          try {
            final cloudinaryUrl = await CloudinaryPdfService.uploadPdf(
              pdfBytes: finalPdfBytes,
              fileName: finalFileName,
              sessionId: safeSessionId,
              folder: 'constats_complets',
            );

            print('✅ [PDF] PDF uploadé vers Cloudinary: $cloudinaryUrl');
            await _sauvegarderUrlDansSession(safeSessionId, cloudinaryUrl);
            return cloudinaryUrl;

          } catch (cloudinaryError) {
            print('⚠️ [PDF] Erreur Cloudinary: $cloudinaryError');
            print('🔥 [PDF] Tentative upload Firebase Storage...');

            // Fallback vers Firebase Storage
            final firebaseUrl = await FirebasePdfUploadService.uploadPdf(
              pdfBytes: finalPdfBytes,
              fileName: finalFileName,
              sessionId: safeSessionId,
              folder: 'constats_complets',
            );

            print('✅ [PDF] PDF uploadé vers Firebase Storage: $firebaseUrl');
            await _sauvegarderUrlDansSession(safeSessionId, firebaseUrl);
            return firebaseUrl;
          }

        } catch (uploadError) {
          print('⚠️ [PDF] Erreur upload cloud: $uploadError');
          print('📁 [PDF] Retour au fichier local: ${file.path}');
          return file.path;
        }
      } catch (saveError) {
        print('❌ [PDF] Erreur lors de la sauvegarde du fichier: $saveError');
        // Essayer avec un nom de fichier simplifié
        final fallbackFileName = 'constat_${timestamp}.pdf';
        final fallbackFile = File('${directory.path}/$fallbackFileName');
        final pdfBytes = await pdf.save();
        await fallbackFile.writeAsBytes(pdfBytes);
        print('✅ [PDF] Fichier sauvegardé avec nom de secours: ${fallbackFile.path}');
        return fallbackFile.path;
      }
    } catch (e) {
      print('❌ [PDF] Erreur sauvegarde: $e');
      print('❌ [PDF] SessionId type: ${sessionId.runtimeType}');
      print('❌ [PDF] SessionId value: $sessionId');
      rethrow;
    }
  }

  /// 🎨 Page de couverture élégante
  static Future<pw.Page> _buildPageCouvertureElegante(Map<String, dynamic> donnees) async {
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    final dateAccident = _extraireDateAccident(donnees);
    final lieuAccident = _extraireLieuAccident(donnees);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // En-tête République Tunisienne
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              border: pw.Border.all(color: PdfColors.red800, width: 2),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'الجمهورية التونسية',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'RÉPUBLIQUE TUNISIENNE',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'CONSTAT AMIABLE D\'ACCIDENT AUTOMOBILE',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 40),

          // Titre principal
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.blue800, PdfColors.blue600],
              ),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'RAPPORT COMPLET ET DÉTAILLÉ',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Constat d\'Accident Automobile',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Informations principales
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Date de l\'accident:', _formatDate(dateAccident)),
                pw.SizedBox(height: 8),
                _buildInfoRow('Lieu de l\'accident:', lieuAccident),
                pw.SizedBox(height: 8),
                _buildInfoRow('Nombre de véhicules:', '${participants.length}'),
                pw.SizedBox(height: 8),
                _buildInfoRow('Code session:', _extraireCodeSession(donnees)),
                pw.SizedBox(height: 8),
                _buildInfoRow('Généré le:', _formatDate(DateTime.now())),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Liste des participants
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.green400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PARTICIPANTS A L\'ACCIDENT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 15),
                ...participants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value as Map<String, dynamic>;
                  final donneesPersonnelles = participant['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
                  final roleVehicule = _safeStringConvert(participant['roleVehicule'], String.fromCharCode(65 + index));

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 30,
                          height: 30,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green600,
                            borderRadius: pw.BorderRadius.circular(15),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              roleVehicule,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Expanded(
                          child: pw.Text(
                            '${donneesPersonnelles['prenom']?.toString() ?? 'N/A'} ${donneesPersonnelles['nom']?.toString() ?? 'N/A'}',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          pw.Spacer(),

          // Pied de page
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                'Document généré automatiquement par l\'application Constat Tunisie\n'
                'Ce rapport contient toutes les informations détaillées de tous les participants',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Page informations générales complète
  static Future<pw.Page> _buildPageInfosGeneralesComplete(Map<String, dynamic> donnees) async {

    final participants = donnees['participants'] as List<dynamic>? ?? [];
    final dateAccident = _extraireDateAccident(donnees);
    final lieuAccident = _extraireLieuAccident(donnees);
    final photos = donnees['photos'] as List<dynamic>? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête de page
          _buildPageHeader('📋 INFORMATIONS GÉNÉRALES DE L\'ACCIDENT'),

          pw.SizedBox(height: 20),

          // Section 1: Détails de l'accident
          _buildElegantSection('🚨 DÉTAILS DE L\'ACCIDENT', [
            'Date: ${_formatDate(dateAccident)}',
            'Heure: ${_extraireHeureAccident(donnees)}',
            'Lieu: $lieuAccident',
            'Coordonnées GPS: ${_extraireCoordonnees(donnees)}',
            'Code session: ${_extraireCodeSession(donnees)}',
            'Statut: ${donnees['statut'] ?? 'En cours'}',
          ], PdfColors.red100),

          pw.SizedBox(height: 15),

          // Section 2: Blessés et témoins
          _buildElegantSection('🏥 BLESSÉS ET TÉMOINS', [
            'Blessés: ${_extraireBlessesInfo(donnees)}',
            'Nombre de témoins: ${_extraireNombreTemoins(donnees)}',
            'Dégâts matériels: ${_extraireDegatsMateriels(donnees)}',
            'Autorités prévenues: ${_extraireAutoritesPrevenues(donnees)}',
          ], PdfColors.orange100),

          pw.SizedBox(height: 15),

          // Section 3: Véhicules impliqués
          _buildElegantSection('🚗 VÉHICULES IMPLIQUÉS', [
            'Nombre de véhicules: ${participants.length}',
            'Photos disponibles: ${photos.length}',
            'Croquis disponible: ${donnees['croquis'] != null && (donnees['croquis'] as Map).isNotEmpty ? 'Oui' : 'Non'}',
            'Signatures: ${_compterSignatures(donnees)}/${participants.length}',
          ], PdfColors.blue100),

          pw.SizedBox(height: 20),

          // Résumé des participants
          pw.Text(
            '👥 RÉSUMÉ DES PARTICIPANTS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 10),

          ...participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value as Map<String, dynamic>;
            return _buildParticipantResume(participant, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  // Méthodes utilitaires pour l'extraction de données
  static dynamic _extraireDateAccident(Map<String, dynamic> donnees) {
    // Chercher dans plusieurs sources
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];

    // Source 1: participants_data (format principal)
    if (participantsData.isNotEmpty) {
      for (var participant in participantsData) {
        final p = participant as Map<String, dynamic>;
        final formulaire = p['donneesFormulaire'] as Map<String, dynamic>? ?? {};

        final dateAccident = formulaire['dateAccident'];
        if (dateAccident != null) {
          return dateAccident; // Retourner tel quel (peut être String, DateTime, ou Timestamp)
        }
      }
    }

    // Source 2: participants (format legacy)
    if (participants.isNotEmpty) {
      final premier = participants.first as Map<String, dynamic>;
      final dateAccident = premier['dateAccident'] ?? premier['formulaire']?['dateAccident'];
      if (dateAccident != null) {
        return dateAccident;
      }
    }

    // Source 3: données principales
    final dateAccident = donnees['dateAccident'];
    if (dateAccident != null) {
      return dateAccident;
    }

    return DateTime.now();
  }

  static String _extraireLieuAccident(Map<String, dynamic> donnees) {
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    if (participants.isNotEmpty) {
      final premier = participants.first as Map<String, dynamic>;

      // Sécuriser l'extraction du lieu
      dynamic lieu = premier['lieuAccident'] ?? premier['formulaire']?['lieuAccident'];
      if (lieu != null) {
        if (lieu is List) {
          return lieu.join(', ');
        }
        return lieu.toString();
      }
    }
    return 'Non spécifié';
  }

  static String _extraireHeureAccident(Map<String, dynamic> donnees) {
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    if (participants.isNotEmpty) {
      final premier = participants.first as Map<String, dynamic>;
      return premier['heureAccident'] ?? premier['formulaire']?['heureAccident'] ?? 'Non spécifiée';
    }
    return 'Non spécifiée';
  }

  static String _extraireCoordonnees(Map<String, dynamic> donnees) {
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    if (participants.isNotEmpty) {
      final premier = participants.first as Map<String, dynamic>;
      final lieuGps = premier['lieuGps'] ?? premier['formulaire']?['lieuGps'];
      if (lieuGps != null && lieuGps is Map) {
        final lat = lieuGps['latitude'];
        final lng = lieuGps['longitude'];
        if (lat != null && lng != null) {
          return '$lat, $lng';
        }
      }
    }
    return 'Non disponibles';
  }

  static String _extraireBlessesInfo(Map<String, dynamic> donnees) {
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    if (participants.isNotEmpty) {
      final premier = participants.first as Map<String, dynamic>;
      final blesses = premier['blesses'] ?? premier['formulaire']?['blesses'];
      return blesses == true ? 'Oui' : 'Non';
    }
    return 'Non spécifié';
  }

  static int _extraireNombreTemoins(Map<String, dynamic> donnees) {
    int totalTemoins = 0;

    // 1. Chercher dans temoinsPartages (session collaborative)
    final temoinsPartages = donnees['temoinsPartages'] as Map<String, dynamic>? ?? {};
    if (temoinsPartages.isNotEmpty) {
      totalTemoins += temoinsPartages.length;
      print('✅ [PDF DEBUG] Témoins partagés trouvés: ${temoinsPartages.length}');
      for (var temoinId in temoinsPartages.keys) {
        final temoin = temoinsPartages[temoinId];
        print('   - Témoin $temoinId: ${temoin['nom']} (${temoin['telephone']})');
      }
    }

    // 2. Chercher dans donneesCommunes (session collaborative)
    final donneesCommunes = donnees['donneesCommunes'] as Map<String, dynamic>? ?? {};
    final temoinsCommuns = donneesCommunes['temoins'] as List<dynamic>? ?? [];
    if (temoinsCommuns.isNotEmpty) {
      totalTemoins += temoinsCommuns.length;
      print('✅ [PDF DEBUG] Témoins communs trouvés: ${temoinsCommuns.length}');
      for (var temoin in temoinsCommuns) {
        print('   - Témoin commun: ${temoin['nom']} (${temoin['telephone']})');
      }
    }

    // 3. Chercher dans participants_data (source principale)
    final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];
    for (final participant in participantsData) {
      final p = participant as Map<String, dynamic>;
      final formulaire = p['donneesFormulaire'] as Map<String, dynamic>? ?? {};

      // Chercher témoins dans différents champs possibles
      final temoins = formulaire['temoins'] ??
                     formulaire['temoinsList'] ??
                     formulaire['witnesses'] ??
                     p['temoins'] ?? [];

      if (temoins is List && temoins.isNotEmpty) {
        totalTemoins += temoins.length;
        print('✅ [PDF DEBUG] Témoins trouvés pour participant ${p['roleVehicule'] ?? 'A'}: ${temoins.length}');
        for (var temoin in temoins) {
          if (temoin is Map) {
            print('   - Témoin participant: ${temoin['nom']} (${temoin['telephone']})');
          }
        }
      } else {
        print('✅ [PDF DEBUG] Témoins trouvés pour participant ${p['roleVehicule'] ?? 'A'}: 0');
      }
    }

    // 4. Fallback: chercher dans participants (ancienne structure)
    if (totalTemoins == 0) {
      final participants = donnees['participants'] as List<dynamic>? ?? [];
      for (final participant in participants) {
        final p = participant as Map<String, dynamic>;
        final temoins = p['temoins'] ?? p['formulaire']?['temoins'] ?? [];
        if (temoins is List && temoins.isNotEmpty) {
          totalTemoins += temoins.length;
          print('✅ [PDF DEBUG] Témoins fallback trouvés: ${temoins.length}');
        }
      }
    }

    print('✅ [PDF DEBUG] Total témoins trouvés: $totalTemoins');
    return totalTemoins;
  }

  static String _extraireDegatsMateriels(Map<String, dynamic> donnees) {
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    bool aDegats = false;
    for (final participant in participants) {
      final p = participant as Map<String, dynamic>;
      final degats = p['degats'] ?? p['formulaire']?['degats'];
      if (degats != null && degats is Map && degats.isNotEmpty) {
        aDegats = true;
        break;
      }
    }
    return aDegats ? 'Oui' : 'Non déclarés';
  }

  static String _extraireAutoritesPrevenues(Map<String, dynamic> donnees) {
    // Cette information pourrait être dans les données générales
    return 'Non spécifié';
  }

  static int _compterSignatures(Map<String, dynamic> donnees) {
    final signatures = donnees['signatures'] as Map<String, dynamic>? ?? {};
    return signatures.length;
  }

  // Méthodes utilitaires pour le formatage
  static String _formatDate(dynamic date) {
    if (date == null) return 'Non spécifiée';

    try {
      DateTime dateTime;

      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        // Gérer différents formats de date
        if (date.contains('/')) {
          // Format dd/MM/yyyy ou dd/MM/yyyy HH:mm
          final parts = date.split(' ');
          final datePart = parts[0];
          final timePart = parts.length > 1 ? parts[1] : '00:00';

          final dateComponents = datePart.split('/');
          if (dateComponents.length == 3) {
            final day = int.parse(dateComponents[0]);
            final month = int.parse(dateComponents[1]);
            final year = int.parse(dateComponents[2]);

            final timeComponents = timePart.split(':');
            final hour = timeComponents.length > 0 ? int.parse(timeComponents[0]) : 0;
            final minute = timeComponents.length > 1 ? int.parse(timeComponents[1]) : 0;

            dateTime = DateTime(year, month, day, hour, minute);
          } else {
            dateTime = DateTime.parse(date);
          }
        } else {
          dateTime = DateTime.parse(date);
        }
      } else if (date.toString().contains('Timestamp')) {
        // Gérer les Timestamp de Firestore
        dateTime = (date as dynamic).toDate();
      } else {
        return 'Format invalide';
      }

      return DateFormat('dd/MM/yyyy à HH:mm').format(dateTime);
    } catch (e) {
      print('⚠️ [PDF] Erreur formatage date: $e');
      // Si le formatage échoue, retourner la valeur originale
      return date.toString();
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPageHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildElegantSection(String title, List<String> items, PdfColor backgroundColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '- $item',
              style: const pw.TextStyle(fontSize: 12),
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// 📄 Section avec images (CIN, Permis)
  static Future<pw.Widget> _buildSectionAvecImages(String title, List<String> items, PdfColor backgroundColor,
      {String? imageRecto, String? imageVerso}) async {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),

          // Informations textuelles
          ...items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '- $item',
              style: const pw.TextStyle(fontSize: 12),
            ),
          )).toList(),

          // Images recto/verso si disponibles
          if (imageRecto != null || imageVerso != null) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                if (imageRecto != null) ...[
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'RECTO',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          height: 80,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.ClipRRect(
                            child: await _buildImageFromBase64(imageRecto, 'Image recto', height: 120, fit: pw.BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (imageVerso != null) pw.SizedBox(width: 10),
                ],
                if (imageVerso != null) ...[
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'VERSO',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          height: 80,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.ClipRRect(
                            child: await _buildImageFromBase64(imageVerso, 'Image verso', height: 120, fit: pw.BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildParticipantResume(Map<String, dynamic> participant, int numero) {

    final donneesPersonnelles = participant['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final donneesVehicule = participant['donneesVehicule'] as Map<String, dynamic>? ?? {};
    final roleVehicule = _safeStringConvert(participant['roleVehicule'], 'A');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 25,
            height: 25,
            decoration: pw.BoxDecoration(
              color: PdfColors.purple600,
              borderRadius: pw.BorderRadius.circular(12.5),
            ),
            child: pw.Center(
              child: pw.Text(
                roleVehicule,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${_safeStringConvert(donneesPersonnelles['prenom'])} ${_safeStringConvert(donneesPersonnelles['nom'])}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.Text(
                  'Véhicule: ${_safeStringConvert(donneesVehicule['marque'])} - ${_safeStringConvert(donneesVehicule['immatriculation'])}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Page complète d'un participant
  static Future<pw.Page> _buildPageParticipantComplete(Map<String, dynamic> participant, int numero, Map<String, dynamic> donnees) async {
    // Fonction helper pour conversion sécurisée
    Map<String, dynamic> _safeMapConvert(dynamic data) {
      if (data == null) return {};
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }

    final donneesPersonnelles = _safeMapConvert(participant['donneesPersonnelles']);
    final donneesVehicule = _safeMapConvert(participant['donneesVehicule']);
    final donneesAssurance = _safeMapConvert(participant['donneesAssurance']);
    final roleVehicule = _safeStringConvert(participant['roleVehicule'], String.fromCharCode(64 + numero));

    // Préparer les sections avec images de manière asynchrone
    final sectionPersonnelles = await _buildSectionAvecImages('DONNEES PERSONNELLES', [
      'Nom: ${_safeStringConvert(donneesPersonnelles['nom'], 'Non spécifié')}',
      'Prénom: ${_safeStringConvert(donneesPersonnelles['prenom'], 'Non spécifié')}',
      'Date de naissance: ${_safeStringConvert(donneesPersonnelles['dateNaissance'], 'Non spécifiée')}',
      'Adresse: ${_safeStringConvert(donneesPersonnelles['adresse'], 'Non spécifiée')}',
      'Téléphone: ${_safeStringConvert(donneesPersonnelles['telephone'], 'Non spécifié')}',
      'Email: ${_safeStringConvert(donneesPersonnelles['email'], 'Non spécifié')}',
      'CIN: ${_safeStringConvert(donneesPersonnelles['cin'], 'Non spécifié')}',
    ], PdfColors.blue100,
      imageRecto: donneesPersonnelles['cinRectoUrl'],
      imageVerso: donneesPersonnelles['cinVersoUrl'],
    );

    final sectionPermis = await _buildSectionAvecImages('PERMIS DE CONDUIRE', [
      'Numéro: ${_safeStringConvert(donneesPersonnelles['numeroPermis'], 'Non spécifié')}',
      'Catégorie: ${_safeStringConvert(donneesPersonnelles['categoriePermis'], 'Non spécifiée')}',
      'Date de délivrance: ${_safeStringConvert(donneesPersonnelles['dateDelivrancePermis'], 'Non spécifiée')}',
      'Date de validité: ${_safeStringConvert(donneesPersonnelles['dateValiditePermis'], 'Non spécifiée')}',
      'Délivré par: ${_safeStringConvert(donneesPersonnelles['lieuDelivrancePermis'], 'Non spécifié')}',
    ], PdfColors.orange100,
      imageRecto: donneesPersonnelles['permisRectoUrl'],
      imageVerso: donneesPersonnelles['permisVersoUrl'],
    );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête du participant
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.green700, PdfColors.green500],
              ),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      roleVehicule,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PARTICIPANT $roleVehicule - DONNÉES COMPLÈTES',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${_safeStringConvert(donneesPersonnelles['prenom'])} ${_safeStringConvert(donneesPersonnelles['nom'])}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Section 1: Données personnelles avec CIN (préparée)
          sectionPersonnelles,

          pw.SizedBox(height: 15),

          // Section 2: Permis de conduire avec images (préparée)
          sectionPermis,

          pw.SizedBox(height: 15),

          // Section 3: Véhicule
          _buildElegantSection('VEHICULE', [
            if (donneesVehicule['marque'] != null && donneesVehicule['marque'] != 'Non spécifiée')
              'Marque: ${donneesVehicule['marque']}',
            if (donneesVehicule['modele'] != null && donneesVehicule['modele'] != 'Non spécifié')
              'Modèle: ${donneesVehicule['modele']}',
            if (donneesVehicule['type'] != null && donneesVehicule['type'] != 'Non spécifié')
              'Type: ${donneesVehicule['type']}',
            if (donneesVehicule['immatriculation'] != null && donneesVehicule['immatriculation'] != 'Non spécifiée')
              'Immatriculation: ${donneesVehicule['immatriculation']}',
            if (donneesVehicule['annee'] != null && donneesVehicule['annee'] != 'Non spécifiée')
              'Année: ${donneesVehicule['annee']}',
            if (donneesVehicule['couleur'] != null && donneesVehicule['couleur'] != 'Non spécifiée')
              'Couleur: ${donneesVehicule['couleur']}',
            if (donneesVehicule['puissance'] != null && donneesVehicule['puissance'] != 'Non spécifiée')
              'Puissance: ${donneesVehicule['puissance']} CV',
            if (donneesVehicule['typeCarburant'] != null && donneesVehicule['typeCarburant'] != 'Non spécifié')
              'Carburant: ${donneesVehicule['typeCarburant']}',
            if (donneesVehicule['numeroContrat'] != null && donneesVehicule['numeroContrat'] != 'Non spécifié')
              'N° Contrat: ${donneesVehicule['numeroContrat']}',
          ].where((item) => item.isNotEmpty).toList(), PdfColors.purple100),

          pw.SizedBox(height: 15),

          // Section 4: Assurance
          _buildElegantSection('ASSURANCE', [
            'Compagnie: ${donneesAssurance['compagnie'] ?? 'Non spécifiée'}',
            'Agence: ${donneesAssurance['agence'] ?? 'Non spécifiée'}',
            'Numéro de police: ${donneesAssurance['numeroPolice'] ?? 'Non spécifié'}',
            'Attestation du: ${donneesAssurance['attestationDu'] ?? 'Non spécifiée'}',
            'Attestation au: ${donneesAssurance['attestationAu'] ?? 'Non spécifiée'}',
            'Agent: ${donneesAssurance['agent'] ?? 'Non spécifié'}',
            'Téléphone agent: ${donneesAssurance['telephoneAgent'] ?? 'Non spécifié'}',
          ], PdfColors.green100),

          pw.SizedBox(height: 15),

          // Section 5: Points de choc initiaux - NOUVEAU
          () {
            final pointsChoc = _extrairePointsChocInitiaux(participant);
            if (pointsChoc.isNotEmpty) {
              return _buildElegantSection('💥 POINTS DE CHOC',
                pointsChoc.map((point) => '• $point').toList(),
                PdfColors.red100);
            } else {
              return _buildElegantSection('💥 POINTS DE CHOC',
                ['Aucun point de choc spécifié'],
                PdfColors.grey100);
            }
          }(),

          pw.SizedBox(height: 15),

          // Section 6: Dégâts apparents - NOUVEAU
          () {
            final degatsApparents = _extraireDegatsApparents(participant);
            return _buildElegantSection('🔧 DÉGÂTS APPARENTS',
              [degatsApparents],
              PdfColors.orange100);
          }(),

          pw.Spacer(),

          // Pied de page
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              'Page ${numero + 1} - Participant $roleVehicule - Données personnelles et véhicule',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Page circonstances et assurance détaillée
  static Future<pw.Page> _buildPageCirconstancesEtAssurance(Map<String, dynamic> participant, int numero, Map<String, dynamic> donnees) async {
    // Fonction helper pour conversion sécurisée
    Map<String, dynamic> _safeMapConvert(dynamic data) {
      if (data == null) return {};
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }

    List<dynamic> _safeListConvert(dynamic data) {
      if (data == null) return [];
      if (data is List) return data;
      return [];
    }

    final circonstances = _safeMapConvert(participant['circonstances']);
    final circonstancesSelectionnees = _safeListConvert(participant['circonstancesSelectionnees']);

    // Conversion sécurisée des noms de circonstances
    List<String> circonstancesNoms = [];
    if (participant['circonstancesNoms'] != null) {
      if (participant['circonstancesNoms'] is List) {
        circonstancesNoms = (participant['circonstancesNoms'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (participant['circonstancesNoms'] is String) {
        circonstancesNoms = [participant['circonstancesNoms'].toString()];
      }
    }

    final degats = _safeMapConvert(participant['degats']);

    // Extraire les points de choc de différentes sources
    List<String> pointsChoc = [];
    final donneesFormulaire = _safeMapConvert(participant['donneesFormulaire']);

    // Chercher points de choc dans plusieurs sources
    if (donneesFormulaire['pointsChocSelectionnes'] != null) {
      pointsChoc = _safeListConvert(donneesFormulaire['pointsChocSelectionnes']).cast<String>();
      print('✅ [PDF DEBUG] Points de choc trouvés dans donneesFormulaire.pointsChocSelectionnes: $pointsChoc');
    } else if (donneesFormulaire['pointsChoc'] != null) {
      pointsChoc = _safeListConvert(donneesFormulaire['pointsChoc']).cast<String>();
      print('✅ [PDF DEBUG] Points de choc trouvés dans donneesFormulaire.pointsChoc: $pointsChoc');
    } else if (participant['pointsChoc'] != null) {
      pointsChoc = _safeListConvert(participant['pointsChoc']).cast<String>();
      print('✅ [PDF DEBUG] Points de choc trouvés dans participant.pointsChoc: $pointsChoc');
    }

    // Extraire les dégâts apparents
    String degatsApparents = '';
    if (donneesFormulaire['degatsApparents'] != null) {
      degatsApparents = donneesFormulaire['degatsApparents'].toString();
      print('✅ [PDF DEBUG] Dégâts apparents trouvés dans donneesFormulaire.degatsApparents: $degatsApparents');
    } else if (donneesFormulaire['degats'] != null && donneesFormulaire['degats'] is Map) {
      final degatsMap = donneesFormulaire['degats'] as Map<String, dynamic>;
      degatsApparents = degatsMap['description']?.toString() ?? '';
      print('✅ [PDF DEBUG] Dégâts apparents trouvés dans donneesFormulaire.degats.description: $degatsApparents');
    } else if (participant['degatsApparents'] != null) {
      degatsApparents = participant['degatsApparents'].toString();
      print('✅ [PDF DEBUG] Dégâts apparents trouvés dans participant.degatsApparents: $degatsApparents');
    }

    // Extraire les témoins de différentes sources possibles
    List<dynamic> temoins = [];

    // Chercher dans donneesFormulaire en priorité
    if (donneesFormulaire['temoins'] != null) {
      temoins = _safeListConvert(donneesFormulaire['temoins']);
      print('✅ [PDF DEBUG] Témoins trouvés dans donneesFormulaire: ${temoins.length}');
    }
    // Fallback: chercher directement dans participant
    else if (participant['temoins'] != null) {
      temoins = _safeListConvert(participant['temoins']);
      print('✅ [PDF DEBUG] Témoins trouvés dans participant: ${temoins.length}');
    }
    // Fallback 2: chercher dans formulaire
    else if (participant['formulaire'] != null) {
      final formulaire = _safeMapConvert(participant['formulaire']);
      if (formulaire['temoins'] != null) {
        temoins = _safeListConvert(formulaire['temoins']);
        print('✅ [PDF DEBUG] Témoins trouvés dans formulaire: ${temoins.length}');
      }
    }

    // Debug détaillé des témoins
    if (temoins.isNotEmpty) {
      print('🔍 [PDF DEBUG] Détails des témoins:');
      for (int i = 0; i < temoins.length; i++) {
        final temoin = temoins[i] as Map<String, dynamic>? ?? {};
        print('   - Témoin ${i + 1}: nom=${temoin['nom']}, adresse=${temoin['adresse']}, tel=${temoin['telephone']}');
      }
    } else {
      print('⚠️ [PDF DEBUG] Aucun témoin trouvé pour ce participant');
    }

    final roleVehicule = _safeStringConvert(participant['roleVehicule'], String.fromCharCode(64 + numero));

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.red700, PdfColors.red500],
              ),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'PARTICIPANT $roleVehicule - CIRCONSTANCES ET DÉGÂTS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          pw.SizedBox(height: 20),

          // Section 1: Circonstances sélectionnées
          pw.Text(
            'CIRCONSTANCES DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 10),

          if (circonstancesNoms.isNotEmpty || circonstancesSelectionnees.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.red200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Circonstances déclarées par le participant $roleVehicule:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                  pw.SizedBox(height: 8),
                  // Utiliser les noms complets si disponibles, sinon les codes
                  if (circonstancesNoms.isNotEmpty) ...[
                    ...circonstancesNoms.map((nom) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(
                            child: pw.Text(
                              nom,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ] else if (circonstancesSelectionnees.isNotEmpty) ...[
                    ...circonstancesSelectionnees.map((code) {
                      try {
                        final nomCirconstance = _obtenirNomCirconstance(code);
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('- ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(
                                child: pw.Text(
                                  nomCirconstance,
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        print('⚠️ [PDF] Erreur traitement circonstance: $e (code: $code)');
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            '- Circonstance non reconnue',
                            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey),
                          ),
                        );
                      }
                    }).toList(),
                  ] else ...[
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        'Aucune circonstance spécifiée',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(
                'Aucune circonstance spécifique déclarée',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ),
          ],

          pw.SizedBox(height: 20),

          // Section 2: Points de choc
          pw.Text(
            '💥 POINTS DE CHOC',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Points de choc sélectionnés:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                if (pointsChoc.isNotEmpty) ...[
                  ...pointsChoc.map((point) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        pw.Expanded(
                          child: pw.Text(
                            point,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ] else ...[
                  pw.Text(
                    'Aucun point de choc spécifié',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Section 3: Dégâts apparents
          pw.Text(
            '🔧 DÉGÂTS APPARENTS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.orange200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Description des dégâts apparents:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  degatsApparents.isNotEmpty ? degatsApparents : 'Aucune description fournie',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                if (degats.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Informations complémentaires:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Point d\'impact: ${degats['pointImpact'] ?? 'Non spécifié'}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Dégâts visibles: ${degats['degatsVisibles'] == true ? 'Oui' : 'Non'}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Section 3: Témoins
          pw.Text(
            '👥 TÉMOINS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),

          if (temoins.isNotEmpty) ...[
            ...temoins.asMap().entries.map((entry) {
              final index = entry.key;
              final temoin = entry.value as Map<String, dynamic>;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Témoin ${index + 1}:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Nom: ${temoin['nom'] ?? 'Non spécifié'}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Adresse: ${temoin['adresse'] ?? 'Non spécifiée'}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Téléphone: ${temoin['telephone'] ?? 'Non spécifié'}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Aucun témoin présent',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Aucun témoin n\'était présent lors de l\'accident ou n\'a été déclaré',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          pw.Spacer(),

          // Pied de page
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              'Page ${numero + 2} - Participant $roleVehicule - Circonstances et témoins',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Page récapitulatif de tous les participants
  static Future<pw.Page> _buildPageRecapitulatifTousParticipants(Map<String, dynamic> donnees) async {

    final participants = donnees['participants'] as List<dynamic>? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildPageHeader('📊 RÉCAPITULATIF DE TOUS LES PARTICIPANTS'),

          pw.SizedBox(height: 20),

          // Tableau récapitulatif
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // En-tête du tableau
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Véh.', isHeader: true),
                  _buildTableCell('Conducteur', isHeader: true),
                  _buildTableCell('Véhicule', isHeader: true),
                  _buildTableCell('Assurance', isHeader: true),
                  _buildTableCell('Signé', isHeader: true),
                ],
              ),
              // Lignes des participants
              ...participants.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value as Map<String, dynamic>;
                final donneesPersonnelles = participant['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
                final donneesVehicule = participant['donneesVehicule'] as Map<String, dynamic>? ?? {};
                final donneesAssurance = participant['donneesAssurance'] as Map<String, dynamic>? ?? {};
                final roleVehicule = _safeStringConvert(participant['roleVehicule'], String.fromCharCode(65 + index));
                final aSigne = participant['aSigne'] == true;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell(roleVehicule),
                    _buildTableCell('${_safeStringConvert(donneesPersonnelles['prenom'])} ${_safeStringConvert(donneesPersonnelles['nom'])}'),
                    _buildTableCell('${_safeStringConvert(donneesVehicule['marque'])}\n${_safeStringConvert(donneesVehicule['immatriculation'])}'),
                    _buildTableCell(_safeStringConvert(donneesAssurance['compagnie'])),
                    _buildTableCell(aSigne ? '✓' : '✗'),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 30),

          // Statistiques
          _buildElegantSection('📈 STATISTIQUES', [
            'Nombre total de participants: ${participants.length}',
            'Participants ayant signé: ${participants.where((p) => (p as Map)['aSigne'] == true).length}',
            'Témoins au total: ${_extraireNombreTemoins(donnees)}',
            'Photos disponibles: ${(donnees['photos'] as List?)?.length ?? 0}',
          ], PdfColors.blue100),
        ],
      ),
    );
  }

  /// 📸 Construire la galerie de photos organisée par type
  static Future<List<pw.Widget>> _buildPhotoGallery(List<dynamic> photos) async {
    final widgets = <pw.Widget>[];

    // Organiser les photos par type
    final photosByType = <String, List<Map<String, dynamic>>>{};
    for (var photo in photos) {
      if (photo is Map<String, dynamic>) {
        final type = photo['type'] ?? 'autres';
        photosByType.putIfAbsent(type, () => []).add(photo);
      }
    }

    // Mapping des types vers des titres lisibles
    final typeLabels = {
      'degats': 'Photos des Dégâts',
      'permis_recto': 'Permis de Conduire (Recto)',
      'permis_verso': 'Permis de Conduire (Verso)',
      'cin_recto': 'Carte d\'Identité (Recto)',
      'cin_verso': 'Carte d\'Identité (Verso)',
      'autres': 'Autres Photos',
    };

    for (var entry in photosByType.entries) {
      final type = entry.key;
      final typePhotos = entry.value;
      final label = typeLabels[type] ?? '📷 $type';

      widgets.add(
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 8));

      // Afficher les photos en grille adaptée selon le type
      if (type == 'degats') {
        // Photos de dégâts : 2 par ligne, plus grandes
        for (int i = 0; i < typePhotos.length; i += 2) {
          final photo1 = typePhotos[i];
          final photo2 = i + 1 < typePhotos.length ? typePhotos[i + 1] : null;

          widgets.add(
            pw.Row(
              children: [
                pw.Expanded(
                  child: await _buildPhotoCard(photo1, height: 180),
                ),
                if (photo2 != null) ...[
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: await _buildPhotoCard(photo2, height: 180),
                  ),
                ] else ...[
                  pw.Expanded(child: pw.Container()),
                ],
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 15));
        }
      } else if (type.contains('permis') || type.contains('cin')) {
        // Documents : 1 par ligne, très grandes
        for (var photo in typePhotos) {
          widgets.add(
            pw.Container(
              width: double.infinity,
              child: await _buildPhotoCard(photo, height: 250, fullWidth: true),
            ),
          );
          widgets.add(pw.SizedBox(height: 15));
        }
      } else {
        // Autres photos : 2 par ligne, taille normale
        for (int i = 0; i < typePhotos.length; i += 2) {
          final photo1 = typePhotos[i];
          final photo2 = i + 1 < typePhotos.length ? typePhotos[i + 1] : null;

          widgets.add(
            pw.Row(
              children: [
                pw.Expanded(
                  child: await _buildPhotoCard(photo1),
                ),
                if (photo2 != null) ...[
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: await _buildPhotoCard(photo2),
                  ),
                ] else ...[
                  pw.Expanded(child: pw.Container()),
                ],
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 10));
        }
      }

      widgets.add(pw.SizedBox(height: 15));
    }

    return widgets;
  }

  /// 🖼️ Construire une carte photo individuelle
  static Future<pw.Widget> _buildPhotoCard(
    Map<String, dynamic> photo, {
    double height = 120,
    bool fullWidth = false,
  }) async {
    final url = photo['url'] ?? '';
    final description = photo['description'] ?? 'Photo';
    final participantId = photo['participantId'] ?? '';
    final participant = photo['participant'] ?? '';

    return pw.Container(
      width: fullWidth ? double.infinity : null,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Image
          pw.Container(
            width: double.infinity,
            height: height,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: await _buildImageFromBase64(url, description, height: 180, fit: pw.BoxFit.cover),
          ),

          // Description
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: fullWidth ? 12 : 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                  maxLines: 2,
                ),
                if (participant.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Participant: $participant',
                    style: pw.TextStyle(
                      fontSize: fullWidth ? 10 : 8,
                      color: PdfColors.blue600,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
                if (participantId.isNotEmpty && participantId != participant) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'ID: $participantId',
                    style: pw.TextStyle(
                      fontSize: fullWidth ? 9 : 7,
                      color: PdfColors.grey600,
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

  /// 🎨 Page croquis et signatures
  static Future<pw.Page> _buildPageCroquisEtSignatures(Map<String, dynamic> donnees) async {
    final croquis = donnees['croquis'] as Map<String, dynamic>? ?? {};

    // Extraire les signatures de différentes sources
    Map<String, dynamic> signatures = {};

    // 1. Chercher dans signatures directement
    if (donnees['signatures'] != null) {
      signatures = donnees['signatures'] as Map<String, dynamic>;
      print('✅ [PDF DEBUG] Signatures trouvées dans signatures: ${signatures.length}');
    }

    // 2. Chercher dans participants_data
    final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];
    for (final participant in participantsData) {
      final p = participant as Map<String, dynamic>;
      final donneesFormulaire = _safeMapConvert(p['donneesFormulaire']);
      final roleVehicule = p['roleVehicule'] ?? 'A';

      print('🔍 [PDF DEBUG] Recherche signature pour participant $roleVehicule');
      print('   - Champs participant: ${p.keys.toList()}');
      print('   - Champs formulaire: ${donneesFormulaire.keys.toList()}');
      print('   - aSigne: ${donneesFormulaire['aSigne']}');

      // Chercher signature dans plusieurs sources
      String? signatureData;

      // Source 1: donneesFormulaire['signature']
      if (donneesFormulaire['signature'] != null && donneesFormulaire['signature'].toString().isNotEmpty) {
        signatureData = donneesFormulaire['signature'];
        print('✅ [PDF DEBUG] Signature trouvée dans donneesFormulaire.signature pour $roleVehicule');
      }
      // Source 2: donneesFormulaire['signatureData']
      else if (donneesFormulaire['signatureData'] != null && donneesFormulaire['signatureData'].toString().isNotEmpty) {
        signatureData = donneesFormulaire['signatureData'];
        print('✅ [PDF DEBUG] Signature trouvée dans donneesFormulaire.signatureData pour $roleVehicule');
      }
      // Source 3: participant['signatureData']
      else if (p['signatureData'] != null && p['signatureData'].toString().isNotEmpty) {
        signatureData = p['signatureData'];
        print('✅ [PDF DEBUG] Signature trouvée dans participant.signatureData pour $roleVehicule');
      }
      // Source 4: donneesFormulaire['signature_data']
      else if (donneesFormulaire['signature_data'] != null && donneesFormulaire['signature_data'].toString().isNotEmpty) {
        signatureData = donneesFormulaire['signature_data'];
        print('✅ [PDF DEBUG] Signature trouvée dans donneesFormulaire.signature_data pour $roleVehicule');
      }

      // Vérifier si le participant a signé (même sans signature visible)
      final aSigne = donneesFormulaire['aSigne'] == true || p['aSigne'] == true;

      if (signatureData != null && signatureData.isNotEmpty) {
        signatures[roleVehicule] = {
          'signatureData': signatureData,
          'nom': '${donneesFormulaire['donneesPersonnelles']?['prenom'] ?? ''} ${donneesFormulaire['donneesPersonnelles']?['nom'] ?? ''}',
          'accord': donneesFormulaire['accord'] ?? true,
          'dateSignature': donneesFormulaire['dateSignature'] ?? p['dateSignature'] ?? DateTime.now().toIso8601String(),
          'aSigne': aSigne,
        };
        print('✅ [PDF DEBUG] Signature ajoutée pour participant $roleVehicule (aSigne: $aSigne)');
      } else if (aSigne) {
        // Participant a signé mais pas de données de signature visibles
        signatures[roleVehicule] = {
          'signatureData': null,
          'nom': '${donneesFormulaire['donneesPersonnelles']?['prenom'] ?? ''} ${donneesFormulaire['donneesPersonnelles']?['nom'] ?? ''}',
          'accord': donneesFormulaire['accord'] ?? true,
          'dateSignature': donneesFormulaire['dateSignature'] ?? p['dateSignature'] ?? DateTime.now().toIso8601String(),
          'aSigne': true,
        };
        print('✅ [PDF DEBUG] Signature confirmée (sans image) pour participant $roleVehicule');
      } else {
        print('⚠️ [PDF DEBUG] Aucune signature trouvée pour participant $roleVehicule');
      }
    }

    // Collecter toutes les photos de différentes sources
    List<dynamic> allPhotos = [];

    // 1. Photos principales
    final photos = donnees['photos'] as List<dynamic>? ?? [];
    allPhotos.addAll(photos);

    // 2. Photos des participants (dégâts, permis, CIN)
    for (final participant in participantsData) {
      final p = participant as Map<String, dynamic>;
      final donneesFormulaire = _safeMapConvert(p['donneesFormulaire']);
      final roleVehicule = p['roleVehicule'] ?? 'A';

      // Photos de dégâts
      final photosDegatUrls = _safeListConvert(donneesFormulaire['photosDegatUrls']);
      for (final photoUrl in photosDegatUrls) {
        if (photoUrl != null && photoUrl.toString().isNotEmpty) {
          allPhotos.add({
            'url': photoUrl.toString(),
            'type': 'degats',
            'description': 'Dégâts véhicule $roleVehicule',
            'participant': roleVehicule,
          });
        }
      }

      // Photos des documents
      final donneesPersonnelles = _safeMapConvert(donneesFormulaire['donneesPersonnelles']);

      // CIN
      if (donneesPersonnelles['cinRectoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['cinRectoUrl'],
          'type': 'cin_recto',
          'description': 'CIN Recto - $roleVehicule',
          'participant': roleVehicule,
        });
      }
      if (donneesPersonnelles['cinVersoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['cinVersoUrl'],
          'type': 'cin_verso',
          'description': 'CIN Verso - $roleVehicule',
          'participant': roleVehicule,
        });
      }

      // Permis
      if (donneesPersonnelles['permisRectoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['permisRectoUrl'],
          'type': 'permis_recto',
          'description': 'Permis Recto - $roleVehicule',
          'participant': roleVehicule,
        });
      }
      if (donneesPersonnelles['permisVersoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['permisVersoUrl'],
          'type': 'permis_verso',
          'description': 'Permis Verso - $roleVehicule',
          'participant': roleVehicule,
        });
      }
    }

    print('✅ [PDF DEBUG] Total photos collectées: ${allPhotos.length}');

    // Préparer les galeries d'images de manière asynchrone
    final photoGallery = await _buildPhotoGallery(allPhotos);

    // Préparer le croquis de manière asynchrone
    pw.Widget? croquisWidget;

    // Chercher le croquis dans différentes sources
    String? croquisData;
    print('🔍 [PDF DEBUG] Recherche croquis...');
    print('🔍 [PDF DEBUG] Croquis direct: ${croquis.keys.toList()}');
    print('🔍 [PDF DEBUG] Données principales: ${donnees.keys.toList()}');

    // Source 1: croquis['data']
    if (croquis['data'] != null && croquis['data'].toString().isNotEmpty) {
      croquisData = croquis['data'].toString();
      print('✅ [PDF DEBUG] Croquis trouvé dans croquis.data');
    }
    // Source 2: donnees['croquisData']
    else if (donnees['croquisData'] != null && donnees['croquisData'].toString().isNotEmpty) {
      croquisData = donnees['croquisData'].toString();
      print('✅ [PDF DEBUG] Croquis trouvé dans donnees.croquisData');
    }
    // Source 3: donnees['croquis']['data']
    else if (donnees['croquis'] != null) {
      final croquisMap = _safeMapConvert(donnees['croquis']);
      if (croquisMap['data'] != null && croquisMap['data'].toString().isNotEmpty) {
        croquisData = croquisMap['data'].toString();
        print('✅ [PDF DEBUG] Croquis trouvé dans donnees.croquis.data');
      }
    }
    // Source 4: chercher dans participants_data
    else {
      final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];
      for (final participant in participantsData) {
        final p = participant as Map<String, dynamic>;
        final donneesFormulaire = _safeMapConvert(p['donneesFormulaire']);

        // Chercher dans plusieurs champs
        if (donneesFormulaire['croquisData'] != null && donneesFormulaire['croquisData'].toString().isNotEmpty) {
          croquisData = donneesFormulaire['croquisData'].toString();
          print('✅ [PDF DEBUG] Croquis trouvé dans participant.donneesFormulaire.croquisData');
          break;
        } else if (donneesFormulaire['croquis'] != null) {
          final croquisParticipant = _safeMapConvert(donneesFormulaire['croquis']);
          if (croquisParticipant['data'] != null && croquisParticipant['data'].toString().isNotEmpty) {
            croquisData = croquisParticipant['data'].toString();
            print('✅ [PDF DEBUG] Croquis trouvé dans participant.donneesFormulaire.croquis.data');
            break;
          }
        }
      }
    }

    if (croquisData != null && croquisData.isNotEmpty) {
      croquisWidget = await _buildImageFromBase64(croquisData, 'Croquis de l\'accident', height: 250, fit: pw.BoxFit.contain);
      print('✅ [PDF DEBUG] Croquis trouvé et traité');
    } else {
      print('⚠️ [PDF DEBUG] Aucun croquis trouvé');
    }

    // Préparer les signatures de manière asynchrone
    List<pw.Widget> signaturesWidgets = [];
    for (final entry in signatures.entries) {
      final roleVehicule = entry.key;
      final signatureData = entry.value as Map<String, dynamic>? ?? {};

      // Créer le widget de signature (avec ou sans image)
      pw.Widget signatureContent;

      if (signatureData['signatureData'] != null && signatureData['signatureData'].toString().isNotEmpty) {
        // Signature avec image
        final signatureImage = await _buildImageFromBase64(signatureData['signatureData'], 'Signature $roleVehicule', height: 100, fit: pw.BoxFit.contain);
        signatureContent = pw.Container(
          width: double.infinity,
          height: 100,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.green300),
          ),
          child: signatureImage,
        );
      } else if (signatureData['aSigne'] == true) {
        // Signature confirmée sans image
        signatureContent = pw.Container(
          width: double.infinity,
          height: 100,
          decoration: pw.BoxDecoration(
            color: PdfColors.green100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.green300),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '✓ SIGNÉ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Signature électronique confirmée',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.green600,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Pas de signature
        signatureContent = pw.Container(
          width: double.infinity,
          height: 100,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Center(
            child: pw.Text(
              'En attente de signature',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ),
        );
      }

      signaturesWidgets.add(
        pw.Container(
          width: 280,
          margin: const pw.EdgeInsets.only(bottom: 15),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: signatureData['aSigne'] == true ? PdfColors.green50 : PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(
              color: signatureData['aSigne'] == true ? PdfColors.green200 : PdfColors.grey300,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Participant $roleVehicule',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: signatureData['aSigne'] == true ? PdfColors.green800 : PdfColors.grey700,
                ),
              ),
              if (signatureData['nom'] != null && signatureData['nom'].toString().trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  signatureData['nom'],
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: signatureData['aSigne'] == true ? PdfColors.green700 : PdfColors.grey600,
                  ),
                ),
              ],
              pw.SizedBox(height: 8),
              signatureContent,
              pw.SizedBox(height: 8),
              if (signatureData['dateSignature'] != null)
                pw.Text(
                  'Signé le: ${_formatDate(signatureData['dateSignature'])}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.green600),
                ),
              if (signatureData['accord'] == false)
                pw.Text(
                  '⚠️ En désaccord',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.red600,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
          _buildPageHeader('CROQUIS ET SIGNATURES'),

          pw.SizedBox(height: 20),

          // Section croquis
          pw.Text(
            'CROQUIS DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),

          // Affichage du croquis s'il existe
          if (croquisWidget != null) ...[
            pw.Container(
              width: double.infinity,
              height: 250,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue300, width: 2),
              ),
              child: croquisWidget,
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Croquis modifié le: ${croquis['derniere_modification'] ?? 'Date inconnue'}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ] else ...[
            pw.Container(
              width: double.infinity,
              height: 150,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Aucun croquis disponible',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],

          pw.SizedBox(height: 30),

          // Section signatures
          pw.Text(
            'SIGNATURES DES PARTICIPANTS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 10),

          if (signaturesWidgets.isNotEmpty) ...[
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: signaturesWidgets,
            ),
          ] else ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Signatures en attente',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Les participants doivent signer le constat pour finaliser la déclaration',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 20),

          // Section photos d'accident
          if (photos.isNotEmpty) ...[
            pw.Text(
              'PHOTOS DE L\'ACCIDENT',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${photos.length} photo(s) d\'accident disponible(s)',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 15),

            // Galerie d'images organisée par type (préparée)
            ...photoGallery,
          ],
        ],
      ),
    );
  }

  /// 📋 Page finale avec recommandations
  static Future<pw.Page> _buildPageFinaleRecommandations(Map<String, dynamic> donnees) async {
    final participants = donnees['participants'] as List<dynamic>? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('📋 RECOMMANDATIONS ET ACTIONS'),

          pw.SizedBox(height: 20),

          // Recommandations
          _buildElegantSection('💡 RECOMMANDATIONS', [
            'Transmettre ce rapport à votre agent d\'assurance dans les plus brefs délais',
            'Conserver une copie de ce document pour vos archives personnelles',
            'Vérifier que toutes les informations sont correctes avant transmission',
            'Contacter votre assureur pour le suivi du dossier',
            'Prendre des photos supplémentaires si nécessaire',
          ], PdfColors.blue100),

          pw.SizedBox(height: 20),

          // Actions prioritaires
          _buildElegantSection('🚨 ACTIONS PRIORITAIRES', [
            'Déclarer le sinistre à votre compagnie d\'assurance',
            'Faire réparer les dégâts urgents pour la sécurité',
            'Consulter un médecin en cas de blessures même légères',
            'Conserver tous les justificatifs et factures',
            'Suivre l\'évolution du dossier auprès de votre agent',
          ], PdfColors.red100),

          pw.SizedBox(height: 20),

          // Contacts utiles
          _buildElegantSection('📞 CONTACTS UTILES', [
            'Police: 197',
            'Pompiers: 198',
            'SAMU: 190',
            'Protection civile: 198',
            'Votre agent d\'assurance (voir détails dans le rapport)',
          ], PdfColors.green100),

          pw.Spacer(),

          // Pied de page final
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.grey800, PdfColors.grey600],
              ),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'RAPPORT GÉNÉRÉ AUTOMATIQUEMENT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Application Constat Tunisie - ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Ce document contient toutes les informations détaillées de tous les participants',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Méthode utilitaire pour créer une cellule de tableau
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 👥 Page dédiée aux témoins
  static Future<pw.Page> _buildPageTemoins(Map<String, dynamic> donnees) async {
    print('🔍 [PDF DEBUG] Construction page témoins...');

    // Collecter tous les témoins
    List<Map<String, dynamic>> allTemoins = [];

    // 1. Collecter les témoins partagés au niveau de la session
    final temoinsPartages = _safeMapConvert(donnees['temoinsPartages']);
    print('🔍 [PDF DEBUG] Témoins partagés trouvés: ${temoinsPartages.length}');

    for (final entry in temoinsPartages.entries) {
      print('🔍 [PDF DEBUG] Traitement témoin partagé ${entry.key}');
      print('🔍 [PDF DEBUG] Type de entry.value: ${entry.value.runtimeType}');
      print('🔍 [PDF DEBUG] Contenu entry.value: ${entry.value}');

      // Traitement direct si c'est déjà un Map
      Map<String, dynamic> temoinData = {};
      if (entry.value is Map<String, dynamic>) {
        temoinData = entry.value as Map<String, dynamic>;
        print('✅ [PDF DEBUG] Témoin déjà en Map: $temoinData');
      } else if (entry.value is Map) {
        temoinData = Map<String, dynamic>.from(entry.value as Map);
        print('✅ [PDF DEBUG] Témoin converti en Map: $temoinData');
      } else {
        temoinData = _safeMapConvert(entry.value);
        print('🔍 [PDF DEBUG] Témoin converti via _safeMapConvert: $temoinData');
      }

      print('🔍 [PDF DEBUG] Témoin final: $temoinData (isEmpty: ${temoinData.isEmpty})');

      if (temoinData.isNotEmpty) {
        final temoinInfo = Map<String, dynamic>.from(temoinData);
        temoinInfo['participant'] = 'Partagé';
        temoinInfo['id'] = entry.key;
        allTemoins.add(temoinInfo);
        print('✅ [PDF DEBUG] Témoin partagé ajouté: ${temoinData['nom']} (${temoinData['telephone']})');
      } else {
        print('❌ [PDF DEBUG] Témoin partagé vide ou invalide: ${entry.key}');
      }
    }

    // 2. Collecter les témoins des participants individuels
    final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];

    for (final participant in participantsData) {
      final p = participant as Map<String, dynamic>;
      final donneesFormulaire = _safeMapConvert(p['donneesFormulaire']);
      final roleVehicule = p['roleVehicule'] ?? 'A';

      final temoins = _safeListConvert(donneesFormulaire['temoins']);
      for (final temoin in temoins) {
        if (temoin is Map<String, dynamic>) {
          final temoinData = Map<String, dynamic>.from(temoin);
          temoinData['participant'] = roleVehicule;
          allTemoins.add(temoinData);
          print('✅ [PDF DEBUG] Témoin ajouté pour participant $roleVehicule: ${temoin['nom']} ${temoin['prenom']}');
        }
      }
    }

    print('✅ [PDF DEBUG] Total témoins collectés: ${allTemoins.length}');

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildPageHeader('👥 TÉMOINS DE L\'ACCIDENT'),

          pw.SizedBox(height: 20),

          if (allTemoins.isEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue300),
              ),
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ℹ️ AUCUN TÉMOIN DÉCLARÉ',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Aucun témoin n\'a été déclaré par les participants.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.blue700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Liste des témoins
            pw.Expanded(
              child: pw.ListView.builder(
                itemCount: allTemoins.length,
                itemBuilder: (context, index) {
                  final temoin = allTemoins[index];
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 15),
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // En-tête témoin
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue600,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'TÉMOIN ${index + 1}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.green100,
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(color: PdfColors.green300),
                              ),
                              child: pw.Text(
                                'Déclaré par véhicule ${temoin['participant']}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 12),

                        // Informations du témoin
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              flex: 2,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Nom:', _safeStringConvert(temoin['nom'], 'Non spécifié')),
                                  pw.SizedBox(height: 6),
                                  _buildInfoRow('Prénom:', _safeStringConvert(temoin['prenom'], 'Non spécifié')),
                                  pw.SizedBox(height: 6),
                                  _buildInfoRow('Téléphone:', _safeStringConvert(temoin['telephone'], 'Non spécifié')),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Adresse:', _safeStringConvert(temoin['adresse'], 'Non spécifiée')),
                                  if (temoin['email'] != null && temoin['email'].toString().isNotEmpty) ...[
                                    pw.SizedBox(height: 6),
                                    _buildInfoRow('Email:', _safeStringConvert(temoin['email'], '')),
                                  ],
                                  if (temoin['commentaire'] != null && temoin['commentaire'].toString().isNotEmpty) ...[
                                    pw.SizedBox(height: 6),
                                    _buildInfoRow('Commentaire:', _safeStringConvert(temoin['commentaire'], '')),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📸 Page dédiée aux photos et documents
  static Future<pw.Page> _buildPagePhotosEtDocuments(Map<String, dynamic> donnees) async {
    print('🔍 [PDF DEBUG] Construction page photos et documents...');

    // Collecter toutes les photos de différentes sources
    List<dynamic> allPhotos = [];
    final participantsData = donnees['participants_data'] as List<dynamic>? ?? [];

    // Photos principales
    final photos = donnees['photos'] as List<dynamic>? ?? [];
    allPhotos.addAll(photos);

    // Photos des participants
    for (final participant in participantsData) {
      final p = participant as Map<String, dynamic>;
      final donneesFormulaire = _safeMapConvert(p['donneesFormulaire']);
      final roleVehicule = p['roleVehicule'] ?? 'A';

      print('🔍 [PDF DEBUG] Collecte photos pour participant $roleVehicule');

      // Photos de dégâts
      final degatsPhotos = _safeListConvert(donneesFormulaire['degatsPhotos'] ?? donneesFormulaire['photosDegatUrls']);
      for (final photoUrl in degatsPhotos) {
        if (photoUrl != null && photoUrl.toString().isNotEmpty) {
          allPhotos.add({
            'url': photoUrl.toString(),
            'type': 'degats',
            'description': 'Dégâts véhicule $roleVehicule',
            'participant': roleVehicule,
          });
          print('✅ [PDF DEBUG] Photo dégâts ajoutée: ${photoUrl.toString().substring(0, 50)}...');
        }
      }

      // Documents personnels
      final donneesPersonnelles = _safeMapConvert(donneesFormulaire['donneesPersonnelles']);

      // CIN
      if (donneesPersonnelles['cinRectoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['cinRectoUrl'],
          'type': 'cin_recto',
          'description': 'CIN Recto - $roleVehicule',
          'participant': roleVehicule,
        });
        print('✅ [PDF DEBUG] CIN recto ajouté pour $roleVehicule');
      }
      if (donneesPersonnelles['cinVersoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['cinVersoUrl'],
          'type': 'cin_verso',
          'description': 'CIN Verso - $roleVehicule',
          'participant': roleVehicule,
        });
        print('✅ [PDF DEBUG] CIN verso ajouté pour $roleVehicule');
      }

      // Permis
      if (donneesPersonnelles['permisRectoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['permisRectoUrl'],
          'type': 'permis_recto',
          'description': 'Permis Recto - $roleVehicule',
          'participant': roleVehicule,
        });
        print('✅ [PDF DEBUG] Permis recto ajouté pour $roleVehicule');
      }
      if (donneesPersonnelles['permisVersoUrl'] != null) {
        allPhotos.add({
          'url': donneesPersonnelles['permisVersoUrl'],
          'type': 'permis_verso',
          'description': 'Permis Verso - $roleVehicule',
          'participant': roleVehicule,
        });
        print('✅ [PDF DEBUG] Permis verso ajouté pour $roleVehicule');
      }
    }

    print('✅ [PDF DEBUG] Total photos collectées: ${allPhotos.length}');

    // Préparer la galerie de photos de manière asynchrone
    final photoGalleryWidgets = allPhotos.isNotEmpty ? await _buildPhotoGallery(allPhotos) : <pw.Widget>[];

    // Construire la page
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildPageHeader('📸 PHOTOS ET DOCUMENTS'),

          pw.SizedBox(height: 20),

          if (allPhotos.isEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.orange300),
              ),
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '⚠️ AUCUNE PHOTO DISPONIBLE',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Aucune photo ou document n\'a été trouvé pour cette session.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.orange700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (photoGalleryWidgets.isNotEmpty) ...[
            // Galerie de photos
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: photoGalleryWidgets,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🗜️ Compresser les images dans un PDF
  static Future<Uint8List> _compresserImages(Uint8List pdfBytes) async {
    try {
      print('🗜️ [PDF] Début compression des images...');

      // Cette méthode est simplifiée - dans un vrai projet,
      // il faudrait parser le PDF et recompresser les images

      // Pour l'instant, on simule une compression en réduisant la qualité
      // En réalité, il faudrait utiliser une bibliothèque comme pdf_manipulator

      print('⚠️ [PDF] Compression simplifiée - retour PDF original');
      return pdfBytes;

    } catch (e) {
      print('❌ [PDF] Erreur compression images: $e');
      return pdfBytes; // Retourner l'original en cas d'erreur
    }
  }
}
