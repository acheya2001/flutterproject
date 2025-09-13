import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import '../models/collaborative_session_model.dart';
import '../features/constat/models/constat_officiel_model.dart';
import '../features/conducteur/models/conducteur_vehicle_model.dart';
import '../features/auth/models/conducteur_model.dart';

/// 📄 Service moderne de génération PDF pour agents d'assurance
/// Design élégant et professionnel pour l'envoi aux agents
class ModernPDFAgentService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎨 Couleurs du thème moderne
  static const _primaryColor = PdfColor.fromInt(0xFF1565C0); // Bleu professionnel
  static const _accentColor = PdfColor.fromInt(0xFF0D47A1); // Bleu foncé
  static const _successColor = PdfColor.fromInt(0xFF2E7D32); // Vert
  static const _warningColor = PdfColor.fromInt(0xFFE65100); // Orange
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const _darkGray = PdfColor.fromInt(0xFF424242);

  /// 📋 Générer PDF moderne pour agent à partir d'une session collaborative
  static Future<Uint8List> genererPDFPourAgent({
    required CollaborativeSession session,
    required String agentEmail,
    required String agencyName,
    required String companyName,
  }) async {
    final pdf = pw.Document();

    // Charger les données complètes de la session
    final sessionData = await _chargerDonneesSession(session.id);
    
    // Page 1: Couverture et résumé exécutif
    pdf.addPage(await _buildPageCouverture(session, sessionData, agentEmail, agencyName, companyName));
    
    // Page 2: Détails des véhicules et conducteurs
    pdf.addPage(await _buildPageVehicules(session, sessionData));
    
    // Page 3: Circonstances et analyse
    pdf.addPage(await _buildPageCirconstances(session, sessionData));
    
    // Page 4: Croquis et photos (si disponibles)
    pdf.addPage(await _buildPageVisuels(session, sessionData));
    
    // Page 5: Recommandations et actions
    pdf.addPage(await _buildPageRecommandations(session, sessionData, agentEmail));

    return pdf.save();
  }

  /// 📊 Charger toutes les données nécessaires de la session
  static Future<Map<String, dynamic>> _chargerDonneesSession(String sessionId) async {
    try {
      // Charger les données de base de la session
      final sessionDoc = await _firestore.collection('collaborative_sessions').doc(sessionId).get();
      final sessionData = sessionDoc.data() ?? {};

      // Charger les participants
      final participantsQuery = await _firestore
          .collection('session_participants')
          .where('sessionId', isEqualTo: sessionId)
          .get();
      
      final participants = participantsQuery.docs.map((doc) => doc.data()).toList();

      // Charger les données de constat officiel si disponible
      ConstatOfficielModel? constatOfficiel;
      try {
        final constatDoc = await _firestore
            .collection('constats_officiels')
            .where('sessionId', isEqualTo: sessionId)
            .limit(1)
            .get();
        
        if (constatDoc.docs.isNotEmpty) {
          constatOfficiel = ConstatOfficielModel.fromMap(constatDoc.docs.first.data());
        }
      } catch (e) {
        print('Erreur chargement constat officiel: $e');
      }

      // Charger les véhicules impliqués
      final vehicules = <Map<String, dynamic>>[];
      for (final participant in participants) {
        if (participant['vehiculeId'] != null) {
          try {
            final vehiculeDoc = await _firestore
                .collection('conducteur_vehicles')
                .doc(participant['vehiculeId'])
                .get();
            
            if (vehiculeDoc.exists) {
              vehicules.add({
                'participant': participant,
                'vehicule': vehiculeDoc.data(),
              });
            }
          } catch (e) {
            print('Erreur chargement véhicule: $e');
          }
        }
      }

      return {
        'session': sessionData,
        'participants': participants,
        'vehicules': vehicules,
        'constatOfficiel': constatOfficiel,
        'dateGeneration': DateTime.now(),
      };
    } catch (e) {
      print('Erreur chargement données session: $e');
      return {};
    }
  }

  /// 📄 Page de couverture moderne
  static Future<pw.Page> _buildPageCouverture(
    CollaborativeSession session,
    Map<String, dynamic> sessionData,
    String agentEmail,
    String agencyName,
    String companyName,
  ) async {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (context) => pw.Stack(
        children: [
          // Arrière-plan dégradé
          pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [_primaryColor, _accentColor],
              ),
            ),
          ),
          
          // Contenu principal
          pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête avec logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CONSTAT TUNISIE',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Rapport d\'Accident Automobile',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.white.shade(0.7),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'URGENT',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 60),
                
                // Informations principales
                pw.Container(
                  padding: const pw.EdgeInsets.all(30),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.black.shade(0.1),
                        offset: const PdfPoint(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NOUVEAU SINISTRE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      
                      pw.SizedBox(height: 20),
                      
                      _buildInfoRow('Code Session:', session.codeSession),
                      _buildInfoRow('Date Accident:', _formatDate(sessionData['session']?['dateAccident'])),
                      _buildInfoRow('Lieu:', sessionData['session']?['lieuAccident'] ?? 'Non spécifié'),
                      _buildInfoRow('Nombre Véhicules:', '${session.nombreVehicules}'),
                      _buildInfoRow('Statut:', _getStatutLabel(session.statut)),
                      
                      pw.SizedBox(height: 20),
                      
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: _lightGray,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'DESTINATAIRE',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: _darkGray,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            _buildInfoRow('Agent:', agentEmail),
                            _buildInfoRow('Agence:', agencyName),
                            _buildInfoRow('Compagnie:', companyName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Pied de page
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white.shade(0.1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Généré le ${_formatDateTime(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white.shade(0.7),
                        ),
                      ),
                      pw.Text(
                        'Page 1/5',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white.shade(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Page des circonstances et analyse
  static Future<pw.Page> _buildPageCirconstances(
    CollaborativeSession session,
    Map<String, dynamic> sessionData,
  ) async {
    final constatOfficiel = sessionData['constatOfficiel'] as ConstatOfficielModel?;

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      header: (context) => _buildModernHeader('CIRCONSTANCES & ANALYSE', context),
      footer: (context) => _buildModernFooter(context),
      build: (context) => [
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Informations générales de l'accident
          _buildSectionCard(
            'INFORMATIONS GÉNÉRALES',
            [
              _buildInfoRow('Date:', _formatDate(constatOfficiel?.dateAccident)),
              _buildInfoRow('Heure:', constatOfficiel?.heureAccident ?? 'Non spécifiée'),
              _buildInfoRow('Lieu:', constatOfficiel?.lieuAccident ?? 'Non spécifié'),
              _buildInfoRow('Blessés:', constatOfficiel?.blesses == true ? 'OUI ⚠️' : 'NON ✅'),
              _buildInfoRow('Dégâts matériels:', constatOfficiel?.degatsMateriels == true ? 'OUI' : 'NON'),
              _buildInfoRow('Témoins:', constatOfficiel?.temoins == true ? 'OUI' : 'NON'),
            ],
          ),

          pw.SizedBox(height: 20),

          // Circonstances par véhicule
          if (constatOfficiel != null && constatOfficiel.circumstances.isNotEmpty)
            _buildSectionCard(
              'CIRCONSTANCES DÉCLARÉES',
              _buildCirconstancesList(constatOfficiel.circumstances),
            ),

          pw.SizedBox(height: 20),

          // Observations
          if (constatOfficiel != null && constatOfficiel.observations.isNotEmpty)
            _buildSectionCard(
              'OBSERVATIONS',
              constatOfficiel.observations.map((obs) => pw.Text('• $obs', style: const pw.TextStyle(fontSize: 11))).toList(),
            ),
        ],
      ),
    );
  }

  /// 🎨 Page des visuels (croquis et photos)
  static Future<pw.Page> _buildPageVisuels(
    CollaborativeSession session,
    Map<String, dynamic> sessionData,
  ) async {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      header: (context) => _buildModernHeader('CROQUIS & PHOTOS', context),
      footer: (context) => _buildModernFooter(context),
      build: (context) => [
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section croquis
          _buildSectionCard(
            'CROQUIS DE L\'ACCIDENT',
            [
              pw.Container(
                height: 250,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Icon(
                        pw.IconData(0xe3b7), // sketch icon
                        size: 48,
                        color: PdfColors.grey,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Croquis disponible dans l\'application',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Session: ${session.codeSession}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Section photos
          _buildSectionCard(
            'PHOTOS DE L\'ACCIDENT',
            [
              pw.Container(
                height: 150,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Icon(
                        pw.IconData(0xe3b6), // photo icon
                        size: 36,
                        color: PdfColors.grey,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Photos disponibles dans l\'application mobile',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Instructions d'accès
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _primaryColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Icon(
                      pw.IconData(0xe88f), // info icon
                      size: 16,
                      color: _primaryColor,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'ACCÈS AUX VISUELS COMPLETS',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Pour accéder aux croquis détaillés et photos haute résolution :',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '1. Connectez-vous à l\'application Constat Tunisie',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '2. Recherchez la session : ${session.codeSession}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '3. Consultez la section "Détails" → "Voir détails"',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Page des recommandations et actions
  static Future<pw.Page> _buildPageRecommandations(
    CollaborativeSession session,
    Map<String, dynamic> sessionData,
    String agentEmail,
  ) async {
    final vehicules = sessionData['vehicules'] as List<Map<String, dynamic>>? ?? [];

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      header: (context) => _buildModernHeader('RECOMMANDATIONS & ACTIONS', context),
      footer: (context) => _buildModernFooter(context),
      build: (context) => [
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Actions prioritaires
          _buildSectionCard(
            'ACTIONS PRIORITAIRES',
            [
              _buildActionItem('🔍', 'Vérifier les contrats d\'assurance', 'Haute', _warningColor),
              _buildActionItem('📞', 'Contacter les assurés', 'Haute', _warningColor),
              _buildActionItem('📋', 'Examiner les circonstances', 'Moyenne', PdfColors.orange),
              _buildActionItem('💰', 'Évaluer les dommages', 'Moyenne', PdfColors.orange),
              _buildActionItem('📄', 'Préparer le dossier sinistre', 'Normale', _successColor),
            ],
          ),

          pw.SizedBox(height: 20),

          // Informations de contact
          _buildSectionCard(
            'CONTACTS IMPLIQUÉS',
            _buildContactsList(vehicules),
          ),

          pw.SizedBox(height: 20),

          // Délais et échéances
          _buildSectionCard(
            'DÉLAIS & ÉCHÉANCES',
            [
              _buildDelaiItem('Déclaration sinistre', '5 jours ouvrés', _warningColor),
              _buildDelaiItem('Expertise si nécessaire', '10 jours ouvrés', PdfColors.orange),
              _buildDelaiItem('Règlement amiable', '30 jours', _successColor),
            ],
          ),

          pw.Spacer(),

          // Pied de page avec informations de contact
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SUPPORT TECHNIQUE',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkGray,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Pour toute question technique concernant ce rapport :',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Email: support@constat-tunisie.tn',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Tél: +216 XX XXX XXX',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  /// 📋 Construire une ligne d'information
  static pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _darkGray,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? 'Non spécifié',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Construire une carte de statistique
  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: _darkGray,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Construire une carte de véhicule
  static pw.Widget _buildVehiculeCard(String titre, Map<String, dynamic> vehiculeData) {
    final participant = vehiculeData['participant'] as Map<String, dynamic>? ?? {};
    final vehicule = vehiculeData['vehicule'] as Map<String, dynamic>? ?? {};

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _primaryColor),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.black.shade(0.05),
            offset: const PdfPoint(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête du véhicule
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              titre,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),

          pw.SizedBox(height: 12),

          // Informations du véhicule
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Colonne 1: Véhicule
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VÉHICULE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkGray,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _buildInfoRow('Marque:', vehicule['brand']),
                    _buildInfoRow('Modèle:', vehicule['model']),
                    _buildInfoRow('Immatriculation:', vehicule['plate']),
                    _buildInfoRow('Couleur:', vehicule['color']),
                    _buildInfoRow('Année:', vehicule['year']?.toString()),
                  ],
                ),
              ),

              pw.SizedBox(width: 20),

              // Colonne 2: Conducteur
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONDUCTEUR',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkGray,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _buildInfoRow('Nom:', vehicule['conducteurNom']),
                    _buildInfoRow('Prénom:', vehicule['conducteurPrenom']),
                    _buildInfoRow('Téléphone:', vehicule['conducteurPhone']),
                    _buildInfoRow('Email:', vehicule['conducteurEmail']),
                    _buildInfoRow('Permis:', vehicule['permisNumber']),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Informations d'assurance
          if (vehicule['contracts'] != null && (vehicule['contracts'] as List).isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _lightGray,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ASSURANCE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _darkGray,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...((vehicule['contracts'] as List).take(1).map((contract) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Compagnie:', contract['companyName']),
                      _buildInfoRow('N° Contrat:', contract['contractNumber']),
                      _buildInfoRow('Agence:', contract['agencyName']),
                      _buildInfoRow('Validité:', contract['isValid'] == true ? 'Valide ✅' : 'Invalide ❌'),
                    ],
                  ))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📋 Construire une section avec carte
  static pw.Widget _buildSectionCard(String titre, List<pw.Widget> contenu) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titre,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          ...contenu,
        ],
      ),
    );
  }

  /// 📋 En-tête moderne
  static pw.Widget _buildModernHeader(String titre, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            titre,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.Text(
            'CONSTAT TUNISIE',
            style: pw.TextStyle(
              fontSize: 12,
              color: _darkGray,
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Pied de page moderne
  static pw.Widget _buildModernFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Document confidentiel - Usage professionnel uniquement',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber}/5',
            style: pw.TextStyle(
              fontSize: 10,
              color: _darkGray,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Construire un élément d'action
  static pw.Widget _buildActionItem(String icon, String action, String priorite, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            width: 30,
            height: 20,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                icon,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              action,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              color: color.shade(0.1),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              priorite,
              style: pw.TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📞 Construire la liste des contacts
  static List<pw.Widget> _buildContactsList(List<Map<String, dynamic>> vehicules) {
    final contacts = <pw.Widget>[];

    for (int i = 0; i < vehicules.length; i++) {
      final vehiculeData = vehicules[i];
      final vehicule = vehiculeData['vehicule'] as Map<String, dynamic>? ?? {};
      final role = String.fromCharCode(65 + i); // A, B, C...

      contacts.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _lightGray,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CONDUCTEUR $role',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${vehicule['conducteurPrenom']} ${vehicule['conducteurNom']}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Tél: ${vehicule['conducteurPhone']} | Email: ${vehicule['conducteurEmail']}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      );
    }

    return contacts;
  }

  /// ⏰ Construire un élément de délai
  static pw.Widget _buildDelaiItem(String action, String delai, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              action,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Text(
            delai,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Construire la liste des circonstances
  static List<pw.Widget> _buildCirconstancesList(Map<String, dynamic> circumstances) {
    final widgets = <pw.Widget>[];

    circumstances.forEach((vehicule, circs) {
      if (circs is List && circs.isNotEmpty) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VÉHICULE $vehicule',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...circs.map<pw.Widget>((circ) => pw.Text(
                  '• $circ',
                  style: const pw.TextStyle(fontSize: 10),
                )),
              ],
            ),
          ),
        );
      }
    });

    return widgets;
  }

  /// 🔢 Compter le nombre d'assureurs uniques
  static int _compterAssureurs(List<Map<String, dynamic>> vehicules) {
    final assureurs = <String>{};

    for (final vehiculeData in vehicules) {
      final vehicule = vehiculeData['vehicule'] as Map<String, dynamic>? ?? {};
      final contracts = vehicule['contracts'] as List? ?? [];

      for (final contract in contracts) {
        if (contract['companyName'] != null) {
          assureurs.add(contract['companyName']);
        }
      }
    }

    return assureurs.length;
  }

  /// 📅 Formater une date
  static String _formatDate(dynamic date) {
    if (date == null) return 'Non spécifiée';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return date;
      }
    } else {
      return 'Format invalide';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  /// 🕐 Formater une date avec heure
  static String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 📊 Obtenir le libellé du statut
  static String _getStatutLabel(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return 'Création';
      case SessionStatus.attente_participants:
        return 'En attente';
      case SessionStatus.en_cours:
        return 'En cours';
      case SessionStatus.validation_croquis:
        return 'Validation croquis';
      case SessionStatus.pret_signature:
        return 'Prêt signature';
      case SessionStatus.signe:
        return 'Signé';
      case SessionStatus.finalise:
        return 'Finalisé ✅';
      case SessionStatus.annule:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  /// 💾 Sauvegarder le PDF et obtenir l'URL
  static Future<String> sauvegarderPDFAgent({
    required String sessionId,
    required Uint8List pdfBytes,
    required String agentEmail,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'constat_agent_${sessionId}_$timestamp.pdf';
      final ref = _storage.ref().child('constats_agents/$sessionId/$fileName');

      await ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'sessionId': sessionId,
            'agentEmail': agentEmail,
            'generatedAt': DateTime.now().toIso8601String(),
            'type': 'agent_report',
          },
        ),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      print('Erreur sauvegarde PDF agent: $e');
      rethrow;
    }
  }

  /// 📧 Générer et envoyer le PDF à un agent
  static Future<String> genererEtEnvoyerPDFAgent({
    required String sessionId,
    required String agentEmail,
    required String agencyName,
    required String companyName,
  }) async {
    try {
      // Charger la session collaborative
      final sessionDoc = await _firestore.collection('collaborative_sessions').doc(sessionId).get();
      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée: $sessionId');
      }

      final session = CollaborativeSession.fromMap(sessionDoc.data()!, sessionDoc.id);

      // Générer le PDF
      final pdfBytes = await genererPDFPourAgent(
        session: session,
        agentEmail: agentEmail,
        agencyName: agencyName,
        companyName: companyName,
      );

      // Sauvegarder le PDF
      final pdfUrl = await sauvegarderPDFAgent(
        sessionId: sessionId,
        pdfBytes: pdfBytes,
        agentEmail: agentEmail,
      );

      // Créer une notification pour l'envoi d'email
      await _firestore.collection('notifications_agents').add({
        'destinataire': agentEmail,
        'type': 'constat_moderne',
        'sessionId': sessionId,
        'pdfUrl': pdfUrl,
        'agencyName': agencyName,
        'companyName': companyName,
        'dateCreation': Timestamp.fromDate(DateTime.now()),
        'statut': 'en_attente',
        'objet': 'Nouveau constat d\'accident - Session ${session.codeSession}',
        'message': 'Un nouveau constat d\'accident a été finalisé et nécessite votre attention.',
      });

      print('✅ PDF moderne généré et notification créée pour $agentEmail');
      return pdfUrl;
    } catch (e) {
      print('❌ Erreur génération PDF agent: $e');
      rethrow;
    }
  }
}
