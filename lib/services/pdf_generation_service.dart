import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/accident_session.dart';

/// 📄 Service de génération PDF pour constats finalisés
class PDFGenerationService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

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
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(session),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          await _buildCroquis(session),
          pw.SizedBox(height: 20),
          await _buildSignatures(session),
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
          'Heure: ${session.heureAccident?.format(null) ?? 'Non spécifiée'}',
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
          pw.Text('${identite.prenomConducteur} ${identite.nomConducteur}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Permis: ${identite.numeroPermis}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('Assurance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${identite.compagnieAssurance}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Police: ${identite.numeroPolice}', style: const pw.TextStyle(fontSize: 10)),
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
            ...CirconstancesAccident.circonstances.entries.map((entry) {
              final numero = entry.key;
              final libelle = entry.value;
              final coche = circonstances.circonstancesSelectionnees.contains(numero);
              
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
              'Total cases cochées: ${circonstances.circonstancesSelectionnees.length}',
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
            pw.Text('Date: ${_formatDate(signature.dateSignature)}', style: const pw.TextStyle(fontSize: 10)),
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
}
