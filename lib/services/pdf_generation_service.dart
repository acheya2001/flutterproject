import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/accident_session.dart';

/// 📄 Service de génération PDF pour constats finalisés et participants invités
class PDFGenerationService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 📋 Générer le PDF individuel d'un participant invité
  static Future<void> generateIndividualGuestPDF(
    Map<String, dynamic> guestData,
    String participantId,
  ) async {
    final pdf = pw.Document();

    // Page 1: Informations personnelles et véhicule
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              _buildGuestHeader('CONSTAT D\'ACCIDENT - PARTICIPANT INVITÉ'),
              pw.SizedBox(height: 20),

              // ID Participant
              _buildGuestInfoBox('ID Participant', participantId),
              pw.SizedBox(height: 20),

              // Informations personnelles
              _buildGuestSection('INFORMATIONS PERSONNELLES', [
                _buildGuestInfoRow('Nom', guestData['conducteur']?['nom'] ?? ''),
                _buildGuestInfoRow('Prénom', guestData['conducteur']?['prenom'] ?? ''),
                _buildGuestInfoRow('CIN', guestData['conducteur']?['cin'] ?? ''),
                _buildGuestInfoRow('Date de naissance', _formatGuestDate(guestData['conducteur']?['dateNaissance'])),
                _buildGuestInfoRow('Téléphone', guestData['conducteur']?['telephone'] ?? ''),
                _buildGuestInfoRow('Email', guestData['conducteur']?['email'] ?? ''),
                _buildGuestInfoRow('Adresse', guestData['conducteur']?['adresse'] ?? ''),
                _buildGuestInfoRow('Profession', guestData['conducteur']?['profession'] ?? ''),
              ]),

              pw.SizedBox(height: 20),

              // Permis de conduire
              _buildGuestSection('PERMIS DE CONDUIRE', [
                _buildGuestInfoRow('Numéro', guestData['conducteur']?['permis']?['numero'] ?? ''),
                _buildGuestInfoRow('Catégorie', guestData['conducteur']?['permis']?['categorie'] ?? ''),
                _buildGuestInfoRow('Date de délivrance', _formatGuestDate(guestData['conducteur']?['permis']?['dateDelivrance'])),
              ]),
            ],
          );
        },
      ),
    );

    // Page 2: Véhicule et assurance
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildGuestHeader('VÉHICULE ET ASSURANCE'),
              pw.SizedBox(height: 20),

              // Informations véhicule
              _buildGuestSection('INFORMATIONS VÉHICULE', [
                _buildGuestInfoRow('Immatriculation', guestData['vehicule']?['immatriculation'] ?? ''),
                _buildGuestInfoRow('Marque', guestData['vehicule']?['marque'] ?? ''),
                _buildGuestInfoRow('Modèle', guestData['vehicule']?['modele'] ?? ''),
                _buildGuestInfoRow('Année', guestData['vehicule']?['annee'] ?? ''),
                _buildGuestInfoRow('Couleur', guestData['vehicule']?['couleur'] ?? ''),
                _buildGuestInfoRow('VIN', guestData['vehicule']?['vin'] ?? ''),
                _buildGuestInfoRow('Carte grise', guestData['vehicule']?['carteGrise'] ?? ''),
                _buildGuestInfoRow('Carburant', guestData['vehicule']?['carburant'] ?? ''),
                _buildGuestInfoRow('Puissance', guestData['vehicule']?['puissance'] ?? ''),
                _buildGuestInfoRow('Usage', guestData['vehicule']?['usage'] ?? ''),
                _buildGuestInfoRow('Date 1ère circulation', _formatGuestDate(guestData['vehicule']?['datePremiereCirculation'])),
              ]),

              pw.SizedBox(height: 20),

              // Informations assurance
              _buildGuestSection('INFORMATIONS ASSURANCE', [
                _buildGuestInfoRow('Compagnie ID', guestData['assurance']?['compagnieId'] ?? ''),
                _buildGuestInfoRow('Agence ID', guestData['assurance']?['agenceId'] ?? ''),
                _buildGuestInfoRow('N° Contrat', guestData['assurance']?['numeroContrat'] ?? ''),
                _buildGuestInfoRow('N° Attestation', guestData['assurance']?['numeroAttestation'] ?? ''),
                _buildGuestInfoRow('Type contrat', guestData['assurance']?['typeContrat'] ?? ''),
                _buildGuestInfoRow('Date début', _formatGuestDate(guestData['assurance']?['dateDebut'])),
                _buildGuestInfoRow('Date fin', _formatGuestDate(guestData['assurance']?['dateFin'])),
                _buildGuestInfoRow('Assurance valide', guestData['assurance']?['assuranceValide'] == true ? 'Oui' : 'Non'),
              ]),
            ],
          );
        },
      ),
    );

    // Page 3: Accident et dégâts
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildGuestHeader('ACCIDENT ET DÉGÂTS'),
              pw.SizedBox(height: 20),

              // Informations accident
              _buildGuestSection('INFORMATIONS ACCIDENT', [
                _buildGuestInfoRow('Lieu', guestData['accident']?['lieu'] ?? ''),
                _buildGuestInfoRow('Ville', guestData['accident']?['ville'] ?? ''),
                _buildGuestInfoRow('Date', _formatGuestDate(guestData['accident']?['date'])),
                _buildGuestInfoRow('Heure', guestData['accident']?['heure'] ?? ''),
                _buildGuestInfoRow('Description', guestData['accident']?['description'] ?? ''),
              ]),

              pw.SizedBox(height: 20),

              // Dégâts
              _buildGuestSection('DÉGÂTS ET CIRCONSTANCES', [
                _buildGuestListRow('Points de choc', guestData['degats']?['pointsChoc'] ?? []),
                _buildGuestListRow('Dégâts apparents', guestData['degats']?['degatsApparents'] ?? []),
                _buildGuestInfoRow('Description dégâts', guestData['degats']?['description'] ?? ''),
                _buildGuestListRow('Circonstances', guestData['degats']?['circonstances'] ?? []),
                _buildGuestInfoRow('Observations', guestData['degats']?['observations'] ?? ''),
              ]),

              pw.SizedBox(height: 20),

              // Témoins
              _buildGuestWitnessesSection(guestData['temoins'] ?? []),
            ],
          );
        },
      ),
    );

    // Sauvegarder et partager le PDF
    await _saveGuestPDF(pdf, 'constat_individuel_$participantId.pdf');
  }

  /// 📋 Générer le PDF complet de la session collaborative
  static Future<void> generateCompleteSessionPDF(
    String sessionId,
    Map<String, dynamic> sessionData,
    List<Map<String, dynamic>> participantsData,
  ) async {
    final pdf = pw.Document();

    // Page de couverture
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'CONSTAT D\'ACCIDENT',
                  style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'SESSION COLLABORATIVE',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 40),
                _buildGuestInfoBox('ID Session', sessionId),
                pw.SizedBox(height: 20),
                _buildGuestInfoBox('Date de génération', DateTime.now().toString().split(' ')[0]),
                pw.SizedBox(height: 20),
                _buildGuestInfoBox('Nombre de participants', participantsData.length.toString()),
              ],
            ),
          );
        },
      ),
    );

    // Page pour chaque participant
    for (int i = 0; i < participantsData.length; i++) {
      final participant = participantsData[i];
      final participantData = participant['data'] as Map<String, dynamic>;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildGuestHeader('PARTICIPANT ${i + 1} - ${participant['type'].toString().toUpperCase()}'),
                pw.SizedBox(height: 20),

                // Informations de base
                _buildGuestSection('INFORMATIONS GÉNÉRALES', [
                  _buildGuestInfoRow('ID', participant['id']),
                  _buildGuestInfoRow('Type', participant['type']),
                  _buildGuestInfoRow('Rôle véhicule', participantData['roleVehicule'] ?? ''),
                  _buildGuestInfoRow('Statut', participantData['status'] ?? ''),
                ]),

                pw.SizedBox(height: 20),

                // Informations spécifiques selon le type
                if (participant['type'] == 'guest') ...[
                  _buildGuestSection('CONDUCTEUR', [
                    _buildGuestInfoRow('Nom', participantData['conducteur']?['nom'] ?? ''),
                    _buildGuestInfoRow('Prénom', participantData['conducteur']?['prenom'] ?? ''),
                    _buildGuestInfoRow('CIN', participantData['conducteur']?['cin'] ?? ''),
                    _buildGuestInfoRow('Téléphone', participantData['conducteur']?['telephone'] ?? ''),
                  ]),

                  pw.SizedBox(height: 15),

                  _buildGuestSection('VÉHICULE', [
                    _buildGuestInfoRow('Immatriculation', participantData['vehicule']?['immatriculation'] ?? ''),
                    _buildGuestInfoRow('Marque', participantData['vehicule']?['marque'] ?? ''),
                    _buildGuestInfoRow('Modèle', participantData['vehicule']?['modele'] ?? ''),
                    _buildGuestInfoRow('Couleur', participantData['vehicule']?['couleur'] ?? ''),
                  ]),
                ],
              ],
            );
          },
        ),
      );
    }

    // Sauvegarder et partager le PDF
    await _saveGuestPDF(pdf, 'constat_complet_$sessionId.pdf');
  }

  /// 📋 Générer le PDF complet du constat
  static Future<Uint8List> genererConstatComplet(AccidentSession session) async {
    final pdf = pw.Document();

    // Page 1: En-tête et informations générales
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(session),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildInformationsGenerales(session),
          pw.SizedBox(height: 20),
          _buildVehicules(session),
        ],
      ),
    );

    // Page 2: Circonstances et observations
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(session),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildCirconstances(session),
          pw.SizedBox(height: 20),
          _buildObservations(session),
        ],
      ),
    );

    // Page 3: Croquis et signatures
    final croquis = await _buildCroquis(session);
    final signatures = await _buildSignatures(session);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(session),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          croquis,
          pw.SizedBox(height: 20),
          signatures,
        ],
      ),
    );

    return pdf.save();
  }

  /// 📋 En-tête du document
  static pw.Widget _buildHeader(AccidentSession session) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CONSTAT AMIABLE D\'ACCIDENT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'République Tunisienne',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Code: ${session.codePublic}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Date: ${_formatDate(session.dateAccident!)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Pied de page
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  /// 📋 Informations générales (Cases 1-5)
  static pw.Widget _buildInformationsGenerales(AccidentSession session) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMATIONS GÉNÉRALES',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Case 1: Date et heure
        _buildSection('1. DATE ET HEURE DE L\'ACCIDENT', [
          'Date: ${_formatDate(session.dateAccident!)}',
          'Heure: ${session.heureAccident != null ? '${session.heureAccident!.hour.toString().padLeft(2, '0')}:${session.heureAccident!.minute.toString().padLeft(2, '0')}' : 'Non spécifiée'}',
        ]),
        
        // Case 2: Lieu
        _buildSection('2. LIEU DE L\'ACCIDENT', [
          session.localisation['adresse'] ?? 'Non spécifié',
          if (session.localisation['ville'] != null) 'Ville: ${session.localisation['ville']}',
        ]),
        
        // Case 3: Blessés
        _buildSection('3. BLESSÉS', [
          session.blesses ? '☑ OUI' : '☐ OUI',
          !session.blesses ? '☑ NON' : '☐ NON',
        ]),
        
        // Case 4: Dégâts matériels autres
        _buildSection('4. DÉGÂTS MATÉRIELS AUTRES QUE AUX VÉHICULES', [
          session.degatsAutres ? '☑ OUI' : '☐ OUI',
          !session.degatsAutres ? '☑ NON' : '☐ NON',
        ]),
        
        // Case 5: Témoins
        _buildSection('5. TÉMOINS', 
          session.temoins.isEmpty 
            ? ['Aucun témoin']
            : session.temoins.map((t) => '${t.nom} ${t.prenom} - ${t.telephone}').toList()
        ),
      ],
    );
  }

  /// 🚗 Informations des véhicules
  static pw.Widget _buildVehicules(AccidentSession session) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VÉHICULES IMPLIQUÉS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Véhicule A
            pw.Expanded(
              child: _buildVehiculeInfo('A', session.identitesVehicules['A']),
            ),
            pw.SizedBox(width: 20),
            // Véhicule B
            pw.Expanded(
              child: _buildVehiculeInfo('B', session.identitesVehicules['B']),
            ),
          ],
        ),
        
        // Autres véhicules si présents
        if (session.nombreParticipants > 2) ...[
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (session.identitesVehicules.containsKey('C'))
                pw.Expanded(
                  child: _buildVehiculeInfo('C', session.identitesVehicules['C']),
                ),
              if (session.identitesVehicules.containsKey('C') && 
                  session.identitesVehicules.containsKey('D'))
                pw.SizedBox(width: 20),
              if (session.identitesVehicules.containsKey('D'))
                pw.Expanded(
                  child: _buildVehiculeInfo('D', session.identitesVehicules['D']),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// 🚗 Informations d'un véhicule
  static pw.Widget _buildVehiculeInfo(String role, IdentiteVehicule? identite) {
    if (identite == null) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Text('Véhicule $role: Non renseigné'),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULE $role',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Marque: ${identite.marque}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Type: ${identite.type}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Immatriculation: ${identite.numeroImmatriculation}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('Conducteur:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${identite.marque} ${identite.type}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Immat: ${identite.numeroImmatriculation}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('Direction:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('De: ${identite.venantDe}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Vers: ${identite.allantA}', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// 📋 Circonstances de l'accident
  static pw.Widget _buildCirconstances(AccidentSession session) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CIRCONSTANCES DE L\'ACCIDENT',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Véhicule A
            pw.Expanded(
              child: _buildCirconstancesVehicule('A', session.circonstances['A']),
            ),
            pw.SizedBox(width: 20),
            // Véhicule B
            pw.Expanded(
              child: _buildCirconstancesVehicule('B', session.circonstances['B']),
            ),
          ],
        ),
      ],
    );
  }

  /// 📋 Circonstances d'un véhicule
  static pw.Widget _buildCirconstancesVehicule(String role, CirconstancesAccident? circonstances) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULE $role',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          
          if (circonstances != null) ...[
            ...CirconstancesAccident.circonstancesOfficielle.asMap().entries.map((entry) {
              final numero = entry.key + 1;
              final libelle = entry.value;
              final coche = circonstances.casesSelectionnees.contains(numero);
              
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  '${coche ? '☑' : '☐'} $numero. $libelle',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              );
            }),
            pw.SizedBox(height: 5),
            pw.Text(
              'Total cases cochées: ${circonstances.casesSelectionnees.length}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ] else
            pw.Text('Non renseigné', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// 📝 Observations
  static pw.Widget _buildObservations(AccidentSession session) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OBSERVATIONS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Observations générales
        _buildSection('Observations générales:', [
          session.observations.isNotEmpty ? session.observations : 'Aucune observation',
        ]),
        
        pw.SizedBox(height: 10),
        
        // Observations par véhicule
        ...session.observationsVehicules.entries.map((entry) {
          final role = entry.key;
          final obs = entry.value;
          return _buildSection('Observations véhicule $role:', [
            obs.isNotEmpty ? obs : 'Aucune observation',
          ]);
        }),
      ],
    );
  }

  /// 🎨 Croquis de l'accident
  static Future<pw.Widget> _buildCroquis(AccidentSession session) async {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CROQUIS DE L\'ACCIDENT',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        
        if (session.croquisFileId != null) ...[
          // TODO: Charger et afficher l'image du croquis
          pw.Container(
            height: 200,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Center(
              child: pw.Text('Croquis disponible (ID: ${session.croquisFileId})'),
            ),
          ),
        ] else
          pw.Container(
            height: 200,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Center(
              child: pw.Text('Aucun croquis fourni'),
            ),
          ),
      ],
    );
  }

  /// ✍️ Signatures des conducteurs
  static Future<pw.Widget> _buildSignatures(AccidentSession session) async {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SIGNATURES DES CONDUCTEURS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        
        pw.Row(
          children: [
            // Signature A
            pw.Expanded(
              child: _buildSignatureVehicule('A', session.signatures['A']),
            ),
            pw.SizedBox(width: 20),
            // Signature B
            pw.Expanded(
              child: _buildSignatureVehicule('B', session.signatures['B']),
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Informations de finalisation
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INFORMATIONS DE FINALISATION',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Date de finalisation: ${_formatDate(session.dateModification)}'),
              pw.Text('Statut: ${session.statut}'),
              pw.Text('Généré automatiquement par l\'application Constat Tunisie'),
            ],
          ),
        ),
      ],
    );
  }

  /// ✍️ Signature d'un véhicule
  static pw.Widget _buildSignatureVehicule(String role, SignatureConducteur? signature) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULE $role',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          
          if (signature != null) ...[
            pw.Container(
              height: 80,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Center(
                child: pw.Text('Signature électronique validée'),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Date: ${signature.dateSignature != null ? _formatDate(signature.dateSignature!) : 'Non signée'}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Responsabilité acceptée: ${signature.accepteResponsabilite ? 'OUI' : 'NON'}', style: const pw.TextStyle(fontSize: 10)),
          ] else
            pw.Container(
              height: 80,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Center(
                child: pw.Text('Non signé'),
              ),
            ),
        ],
      ),
    );
  }

  /// 📋 Section générique
  static pw.Widget _buildSection(String titre, List<String> contenu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titre,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 5),
          ...contenu.map((ligne) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
            child: pw.Text(ligne, style: const pw.TextStyle(fontSize: 11)),
          )),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// 💾 Sauvegarder le PDF dans Firebase Storage
  static Future<String> sauvegarderPDF(String sessionId, Uint8List pdfBytes) async {
    final ref = _storage.ref().child('constats/$sessionId/constat_final.pdf');
    await ref.putData(pdfBytes);
    return await ref.getDownloadURL();
  }

  /// 📧 Générer PDF pour envoi email (version allégée)
  static Future<Uint8List> genererPDFEmail(AccidentSession session) async {
    // Version simplifiée pour email
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(session),
            pw.SizedBox(height: 20),
            _buildInformationsGenerales(session),
            pw.SizedBox(height: 20),
            pw.Text(
              'Document généré automatiquement par l\'application Constat Tunisie',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ========== MÉTHODES UTILITAIRES POUR PDF INVITÉS ==========

  /// 🏗️ Construire l'en-tête pour invités
  static pw.Widget _buildGuestHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        border: pw.Border.all(color: PdfColors.blue),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 🏗️ Construire une section pour invités
  static pw.Widget _buildGuestSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 🏗️ Construire une ligne d'information pour invités
  static pw.Widget _buildGuestInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value.isNotEmpty ? value : 'Non renseigné'),
          ),
        ],
      ),
    );
  }

  /// 🏗️ Construire une ligne de liste pour invités
  static pw.Widget _buildGuestListRow(String label, List<dynamic> items) {
    final itemsText = items.isNotEmpty ? items.join(', ') : 'Aucun';
    return _buildGuestInfoRow(label, itemsText);
  }

  /// 🏗️ Construire une boîte d'information pour invités
  static pw.Widget _buildGuestInfoBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(value),
        ],
      ),
    );
  }

  /// 🏗️ Construire la section témoins pour invités
  static pw.Widget _buildGuestWitnessesSection(List<dynamic> witnesses) {
    if (witnesses.isEmpty) {
      return _buildGuestSection('TÉMOINS', [
        pw.Text('Aucun témoin déclaré'),
      ]);
    }

    final witnessWidgets = <pw.Widget>[];
    for (int i = 0; i < witnesses.length; i++) {
      final witness = witnesses[i] as Map<String, dynamic>;
      witnessWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Témoin ${i + 1}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              _buildGuestInfoRow('Nom', witness['nom'] ?? ''),
              _buildGuestInfoRow('Prénom', witness['prenom'] ?? ''),
              _buildGuestInfoRow('Téléphone', witness['telephone'] ?? ''),
              _buildGuestInfoRow('Adresse', witness['adresse'] ?? ''),
            ],
          ),
        ),
      );
    }

    return _buildGuestSection('TÉMOINS', witnessWidgets);
  }

  /// 📅 Formater une date pour invités
  static String _formatGuestDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// 💾 Sauvegarder et partager le PDF pour invités
  static Future<void> _saveGuestPDF(pw.Document pdf, String filename) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      // Partager le fichier
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Constat d\'accident - $filename',
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde du PDF: $e');
      rethrow;
    }
  }
}
