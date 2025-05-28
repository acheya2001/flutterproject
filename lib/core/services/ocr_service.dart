import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Extraire les informations d'un permis de conduire
  Future<Map<String, dynamic>?> extractPermisInfo(File imageFile) async {
    try {
      debugPrint('[OCRService] Extraction des informations du permis de conduire');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String text = recognizedText.text.toLowerCase();
      debugPrint('[OCRService] Texte extrait: $text');
      
      // Rechercher le numéro de permis (format typique tunisien)
      final RegExp numeroRegex = RegExp(r'\b\d{6,10}\b');
      final numeroMatches = numeroRegex.allMatches(text);
      String? numero;
      if (numeroMatches.isNotEmpty) {
        numero = numeroMatches.first.group(0);
      }
      
      // Rechercher les dates (format JJ/MM/AAAA)
      final RegExp dateRegex = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b');
      final dateMatches = dateRegex.allMatches(text);
      
      DateTime? delivreLe;
      DateTime? valideJusquau;
      
      if (dateMatches.length >= 2) {
        // Supposer que la première date est la date de délivrance et la deuxième est la date d'expiration
        final match1 = dateMatches.elementAt(0);
        final match2 = dateMatches.elementAt(1);
        
        try {
          final dateStr1 = match1.group(0);
          final dateStr2 = match2.group(0);
          
          if (dateStr1 != null && dateStr2 != null) {
            final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
            delivreLe = dateFormat.parse(dateStr1);
            valideJusquau = dateFormat.parse(dateStr2);
            
            // Si la date d'expiration est antérieure à la date de délivrance, inverser
            if (valideJusquau.isBefore(delivreLe)) {
              final temp = delivreLe;
              delivreLe = valideJusquau;
              valideJusquau = temp;
            }
          }
        } catch (e) {
          debugPrint('[OCRService] Erreur lors du parsing des dates: $e');
        }
      } else if (dateMatches.length == 1) {
        // S'il n'y a qu'une seule date, essayer de déterminer si c'est la date de délivrance ou d'expiration
        final match = dateMatches.first;
        final dateStr = match.group(0);
        
        if (dateStr != null) {
          try {
            final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
            final date = dateFormat.parse(dateStr);
            
            // Si la date est dans le futur, c'est probablement la date d'expiration
            if (date.isAfter(DateTime.now())) {
              valideJusquau = date;
            } else {
              delivreLe = date;
            }
          } catch (e) {
            debugPrint('[OCRService] Erreur lors du parsing de la date: $e');
          }
        }
      }
      
      // Rechercher des mots clés pour identifier le type de permis
      String? categorie;
      if (text.contains('catégorie') || text.contains('categorie')) {
        final RegExp categorieRegex = RegExp(r'cat[ée]gorie\s+([a-e]\d?)', caseSensitive: false);
        final categorieMatch = categorieRegex.firstMatch(text);
        if (categorieMatch != null && categorieMatch.groupCount >= 1) {
          categorie = categorieMatch.group(1)?.toUpperCase();
        }
      }
      
      // Rechercher le nom et prénom
      String? nom;
      String? prenom;
      
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.contains('nom') && !line.contains('prénom') && !line.contains('prenom')) {
          if (i + 1 < lines.length) {
            nom = lines[i + 1].trim();
          }
        } else if (line.contains('prénom') || line.contains('prenom')) {
          if (i + 1 < lines.length) {
            prenom = lines[i + 1].trim();
          }
        }
      }
      
      debugPrint('[OCRService] Informations extraites: Numéro: $numero, Nom: $nom, Prénom: $prenom, Délivré le: $delivreLe, Valide jusqu\'au: $valideJusquau, Catégorie: $categorie');
      
      return {
        'numero': numero,
        'nom': nom,
        'prenom': prenom,
        'delivreLe': delivreLe,
        'valideJusquau': valideJusquau,
        'categorie': categorie,
        'estValide': valideJusquau != null ? valideJusquau.isAfter(DateTime.now()) : null,
      };
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de l\'extraction des informations du permis: $e');
      return null;
    }
  }

  // Extraire les informations d'une carte d'identité nationale
  Future<Map<String, dynamic>?> extractCINInfo(File imageFile) async {
    try {
      debugPrint('[OCRService] Extraction des informations de la CIN');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String text = recognizedText.text;
      debugPrint('[OCRService] Texte extrait: $text');
      
      // Rechercher le numéro de CIN (8 chiffres pour la Tunisie)
      final RegExp cinRegex = RegExp(r'\b\d{8}\b');
      final cinMatches = cinRegex.allMatches(text);
      String? cin;
      if (cinMatches.isNotEmpty) {
        cin = cinMatches.first.group(0);
      }
      
      // Rechercher le nom et prénom
      String? nom;
      String? prenom;
      
      // Rechercher des lignes qui pourraient contenir le nom et prénom
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        
        // Rechercher des mots clés comme "Nom" ou "Prénom"
        if (line.contains('nom') && !line.contains('prénom') && !line.contains('prenom')) {
          if (i + 1 < lines.length) {
            nom = lines[i + 1].trim();
          }
        } else if (line.contains('prénom') || line.contains('prenom')) {
          if (i + 1 < lines.length) {
            prenom = lines[i + 1].trim();
          }
        }
      }
      
      // Rechercher l'adresse
      String? adresse;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        if (line.contains('adresse') || line.contains('domicile')) {
          if (i + 1 < lines.length) {
            adresse = lines[i + 1].trim();
            
            // Essayer de capturer plusieurs lignes d'adresse
            int j = i + 2;
            while (j < lines.length && 
                  !lines[j].toLowerCase().contains('nom') && 
                  !lines[j].toLowerCase().contains('prénom') && 
                  !lines[j].toLowerCase().contains('cin') && 
                  !lines[j].toLowerCase().contains('date')) {
              adresse = '$adresse ${lines[j].trim()}';
              j++;
            }
          }
          break;
        }
      }
      
      // Rechercher la date de naissance
      DateTime? dateNaissance;
      final RegExp dateRegex = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b');
      final dateMatches = dateRegex.allMatches(text);
      
      if (dateMatches.isNotEmpty) {
        final dateStr = dateMatches.first.group(0);
        if (dateStr != null) {
          try {
            final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
            dateNaissance = dateFormat.parse(dateStr);
          } catch (e) {
            debugPrint('[OCRService] Erreur lors du parsing de la date de naissance: $e');
          }
        }
      }
      
      debugPrint('[OCRService] Informations extraites: CIN: $cin, Nom: $nom, Prénom: $prenom, Adresse: $adresse, Date de naissance: $dateNaissance');
      
      return {
        'cin': cin,
        'nom': nom,
        'prenom': prenom,
        'adresse': adresse,
        'dateNaissance': dateNaissance,
      };
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de l\'extraction des informations de la CIN: $e');
      return null;
    }
  }

  // Extraire les informations d'une carte grise
  Future<Map<String, dynamic>?> extractCarteGriseInfo(File imageFile) async {
    try {
      debugPrint('[OCRService] Extraction des informations de la carte grise');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String text = recognizedText.text;
      debugPrint('[OCRService] Texte extrait: $text');
      
      // Rechercher l'immatriculation (format tunisien)
      String? immatriculation;
      final RegExp immatRegex = RegExp(r'\b\d{1,3}\s*(?:تونس|tunis)\s*\d{1,4}\b', caseSensitive: false);
      final immatMatches = immatRegex.allMatches(text.toLowerCase());
      if (immatMatches.isNotEmpty) {
        immatriculation = immatMatches.first.group(0);
      }
      
      // Rechercher la marque et le modèle
      String? marque;
      String? modele;
      
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        
        if (line.contains('marque') || line.contains('brand')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            marque = parts[1].trim();
          } else if (i + 1 < lines.length) {
            marque = lines[i + 1].trim();
          }
        } else if (line.contains('modèle') || line.contains('modele') || line.contains('model')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            modele = parts[1].trim();
          } else if (i + 1 < lines.length) {
            modele = lines[i + 1].trim();
          }
        }
      }
      
      // Rechercher le nom du propriétaire
      String? proprietaire;
      String? nomProprietaire;
      String? prenomProprietaire;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        if (line.contains('propriétaire') || line.contains('proprietaire') || line.contains('owner')) {
          if (i + 1 < lines.length) {
            proprietaire = lines[i + 1].trim();
            
            // Essayer de séparer le nom et prénom
            final nameParts = proprietaire.split(' ');
            if (nameParts.length > 1) {
              prenomProprietaire = nameParts[0];
              nomProprietaire = nameParts.sublist(1).join(' ');
            } else {
              nomProprietaire = proprietaire;
            }
          }
          break;
        }
      }
      
      // Rechercher l'année
      int? annee;
      final RegExp anneeRegex = RegExp(r'\b(19|20)\d{2}\b');
      final anneeMatches = anneeRegex.allMatches(text);
      if (anneeMatches.isNotEmpty) {
        final anneeStr = anneeMatches.first.group(0);
        if (anneeStr != null) {
          annee = int.tryParse(anneeStr);
        }
      }
      
      // Rechercher le numéro de carte grise
      String? numeroCarteGrise;
      final RegExp numeroRegex = RegExp(r'\b[A-Z0-9]{5,15}\b');
      final numeroMatches = numeroRegex.allMatches(text.toUpperCase());
      if (numeroMatches.isNotEmpty) {
        // Prendre le premier numéro qui ne ressemble pas à une immatriculation
        for (final match in numeroMatches) {
          final numero = match.group(0);
          if (numero != null && !immatRegex.hasMatch(numero.toLowerCase())) {
            numeroCarteGrise = numero;
            break;
          }
        }
      }
      
      // Rechercher le type de véhicule
      String? typeVehicule;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        if (line.contains('type') || line.contains('genre')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            typeVehicule = parts[1].trim();
          } else if (i + 1 < lines.length) {
            typeVehicule = lines[i + 1].trim();
          }
          break;
        }
      }
      
      // Rechercher la puissance fiscale
      int? puissance;
      final RegExp puissanceRegex = RegExp(r'\b(\d{1,3})\s*(?:cv|hp|ch)\b', caseSensitive: false);
      final puissanceMatches = puissanceRegex.allMatches(text.toLowerCase());
      if (puissanceMatches.isNotEmpty) {
        final puissanceStr = puissanceMatches.first.group(1);
        if (puissanceStr != null) {
          puissance = int.tryParse(puissanceStr);
        }
      }
      
      // Rechercher la date de première mise en circulation
      DateTime? dateMiseEnCirculation;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        if (line.contains('circulation') || line.contains('mise en service')) {
          final RegExp dateRegex = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b');
          final dateMatches = dateRegex.allMatches(line);
          
          if (dateMatches.isNotEmpty) {
            final dateStr = dateMatches.first.group(0);
            if (dateStr != null) {
              try {
                final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
                dateMiseEnCirculation = dateFormat.parse(dateStr);
              } catch (e) {
                debugPrint('[OCRService] Erreur lors du parsing de la date de mise en circulation: $e');
              }
            }
          } else if (i + 1 < lines.length) {
            // Chercher dans la ligne suivante
            final nextLine = lines[i + 1].trim();
            final nextLineMatches = dateRegex.allMatches(nextLine);
            if (nextLineMatches.isNotEmpty) {
              final dateStr = nextLineMatches.first.group(0);
              if (dateStr != null) {
                try {
                  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
                  dateMiseEnCirculation = dateFormat.parse(dateStr);
                } catch (e) {
                  debugPrint('[OCRService] Erreur lors du parsing de la date de mise en circulation: $e');
                }
              }
            }
          }
          break;
        }
      }
      
      // Rechercher la couleur
      String? couleur;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        if (line.contains('couleur') || line.contains('color')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            couleur = parts[1].trim();
          } else if (i + 1 < lines.length) {
            couleur = lines[i + 1].trim();
          }
          break;
        }
      }
      
      debugPrint('[OCRService] Informations extraites: Immatriculation: $immatriculation, Marque: $marque, Modèle: $modele, Propriétaire: $proprietaire, Année: $annee, Numéro carte grise: $numeroCarteGrise, Type: $typeVehicule, Puissance: $puissance, Date mise en circulation: $dateMiseEnCirculation, Couleur: $couleur');
      
      return {
        'immatriculation': immatriculation,
        'marque': marque,
        'modele': modele,
        'proprietaire': proprietaire,
        'nomProprietaire': nomProprietaire,
        'prenomProprietaire': prenomProprietaire,
        'annee': annee,
        'numeroCarteGrise': numeroCarteGrise,
        'typeVehicule': typeVehicule,
        'puissance': puissance,
        'dateMiseEnCirculation': dateMiseEnCirculation,
        'couleur': couleur,
      };
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de l\'extraction des informations de la carte grise: $e');
      return null;
    }
  }

  // Extraire les informations d'une attestation d'assurance
  Future<Map<String, dynamic>?> extractAssuranceInfo(File imageFile) async {
    try {
      debugPrint('[OCRService] Extraction des informations de l\'attestation d\'assurance');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String text = recognizedText.text;
      debugPrint('[OCRService] Texte extrait: $text');
      
      // Rechercher le numéro de police
      String? numeroPolice;
      final RegExp policeRegex = RegExp(r'\b(?:police|contrat|policy|contract)\s*(?:n[°o]|number|#)?\s*:?\s*([A-Z0-9\-./]+)', caseSensitive: false);
      final policeMatches = policeRegex.allMatches(text.toLowerCase());
      
      if (policeMatches.isNotEmpty) {
        for (final match in policeMatches) {
          if (match.groupCount >= 1) {
            numeroPolice = match.group(1)?.trim();
            if (numeroPolice != null && numeroPolice.isNotEmpty) {
              break;
            }
          }
        }
      }
      
      // Si on n'a pas trouvé avec le regex précédent, essayer un autre pattern
      if (numeroPolice == null || numeroPolice.isEmpty) {
        final RegExp simplePoliceRegex = RegExp(r'\b[A-Z0-9]{5,15}(?:[/-][A-Z0-9]{1,10}){0,3}\b');
        final simplePoliceMatches = simplePoliceRegex.allMatches(text.toUpperCase());
        
        if (simplePoliceMatches.isNotEmpty) {
          numeroPolice = simplePoliceMatches.first.group(0);
        }
      }
      
      // Rechercher la compagnie d'assurance
      String? compagnieAssurance;
      final lines = text.split('\n');
      
      // Liste des compagnies d'assurance tunisiennes connues
      final List<String> compagniesConnues = [
        'star', 'comar', 'mag', 'astree', 'lloyd', 'biat', 'carte', 'gat', 'ami', 'ctama', 
        'assurances', 'assurance', 'insurance'
      ];
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        
        // Vérifier si la ligne contient le nom d'une compagnie connue
        for (final compagnie in compagniesConnues) {
          if (line.contains(compagnie)) {
            compagnieAssurance = lines[i].trim();
            break;
          }
        }
        
        if (compagnieAssurance != null) {
          break;
        }
      }
      
      // Rechercher les dates de validité
      DateTime? dateDebut;
      DateTime? dateFin;
      
      // Rechercher des patterns comme "du ... au ..." ou "valable du ... au ..."
      // Utiliser une expression régulière simplifiée pour éviter les problèmes de syntaxe
      final RegExp periodeRegex = RegExp(r'du\s+(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})\s+au\s+(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})');
      final periodeMatches = periodeRegex.allMatches(text.toLowerCase());
      
      if (periodeMatches.isNotEmpty) {
        for (final match in periodeMatches) {
          if (match.groupCount >= 2) {
            final dateDebutStr = match.group(1);
            final dateFinStr = match.group(2);
            
            if (dateDebutStr != null && dateFinStr != null) {
              try {
                // Essayer différents formats de date
                final List<DateFormat> formats = [
                  DateFormat('dd/MM/yyyy'),
                  DateFormat('d/M/yyyy'),
                  DateFormat('dd-MM-yyyy'),
                  DateFormat('dd.MM.yyyy'),
                ];
                
                for (final format in formats) {
                  try {
                    dateDebut = format.parse(dateDebutStr);
                    dateFin = format.parse(dateFinStr);
                    break;
                  } catch (e) {
                    // Continuer avec le format suivant
                  }
                }
              } catch (e) {
                debugPrint('[OCRService] Erreur lors du parsing des dates de validité: $e');
              }
            }
            
            if (dateDebut != null && dateFin != null) {
              break;
            }
          }
        }
      }
      
      // Si on n'a pas trouvé avec le regex précédent, chercher toutes les dates
      if (dateDebut == null || dateFin == null) {
        final RegExp dateRegex = RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\b');
        final dateMatches = dateRegex.allMatches(text);
        
        final List<DateTime> dates = [];
        
        for (final match in dateMatches) {
          final dateStr = match.group(0);
          if (dateStr != null) {
            try {
              final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
              final date = dateFormat.parse(dateStr);
              dates.add(date);
            } catch (e) {
              // Ignorer les erreurs de parsing
            }
          }
        }
        
        // Trier les dates
        dates.sort();
        
        // Prendre la première date comme date de début et la dernière comme date de fin
        if (dates.length >= 2) {
          dateDebut = dates.first;
          dateFin = dates.last;
        } else if (dates.length == 1) {
          // Si on n'a qu'une seule date, essayer de déterminer si c'est la date de début ou de fin
          final date = dates.first;
          
          // Si la date est dans le passé, c'est probablement la date de début
          if (date.isBefore(DateTime.now())) {
            dateDebut = date;
            // Estimer la date de fin à un an plus tard
            dateFin = DateTime(date.year + 1, date.month, date.day);
          } else {
            // Si la date est dans le futur, c'est probablement la date de fin
            dateFin = date;
            // Estimer la date de début à un an plus tôt
            dateDebut = DateTime(date.year - 1, date.month, date.day);
          }
        }
      }
      
      // Rechercher l'immatriculation du véhicule
      String? immatriculation;
      final RegExp immatRegex = RegExp(r'\b\d{1,3}\s*(?:تونس|tunis)\s*\d{1,4}\b', caseSensitive: false);
      final immatMatches = immatRegex.allMatches(text.toLowerCase());
      if (immatMatches.isNotEmpty) {
        immatriculation = immatMatches.first.group(0);
      }
      
      // Vérifier si l'assurance est valide
      bool assuranceValide = false;
      if (dateFin != null) {
        assuranceValide = dateFin.isAfter(DateTime.now());
      }
      
      debugPrint('[OCRService] Informations extraites: Numéro police: $numeroPolice, Compagnie: $compagnieAssurance, Date début: $dateDebut, Date fin: $dateFin, Immatriculation: $immatriculation, Assurance valide: $assuranceValide');
      
      return {
        'numeroPolice': numeroPolice,
        'compagnieAssurance': compagnieAssurance,
        'dateDebut': dateDebut,
        'dateFin': dateFin,
        'immatriculation': immatriculation,
        'assuranceValide': assuranceValide,
      };
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de l\'extraction des informations de l\'assurance: $e');
      return null;
    }
  }

  // Méthode générique pour extraire du texte d'une image
  Future<String?> extractText(File imageFile) async {
    try {
      debugPrint('[OCRService] Extraction de texte générique');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String text = recognizedText.text;
      debugPrint('[OCRService] Texte extrait: $text');
      
      return text;
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de l\'extraction de texte: $e');
      return null;
    }
  }

  // Détecter le type de document
  Future<String?> detectDocumentType(File imageFile) async {
    try {
      debugPrint('[OCRService] Détection du type de document');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final String text = recognizedText.text.toLowerCase();
      
      // Mots clés pour chaque type de document
      final Map<String, List<String>> keywordsByType = {
        'permis': ['permis', 'conduire', 'driving', 'license', 'catégorie', 'categorie'],
        'cin': ['carte', 'identité', 'identity', 'nationale', 'national', 'cin'],
        'carte_grise': ['carte', 'grise', 'registration', 'certificat', 'immatriculation', 'circulation'],
        'assurance': ['assurance', 'insurance', 'attestation', 'police', 'policy', 'contrat', 'contract'],
      };
      
      // Compter les occurrences de mots clés pour chaque type
      final Map<String, int> scores = {};
      
      for (final entry in keywordsByType.entries) {
        final String type = entry.key;
        final List<String> keywords = entry.value;
        
        int score = 0;
        for (final keyword in keywords) {
          if (text.contains(keyword)) {
            score++;
          }
        }
        
        scores[type] = score;
      }
      
      // Trouver le type avec le score le plus élevé
      String? detectedType;
      int maxScore = 0;
      
      for (final entry in scores.entries) {
        if (entry.value > maxScore) {
          maxScore = entry.value;
          detectedType = entry.key;
        }
      }
      
      // Vérifier si le score est suffisant
      if (maxScore >= 2) {
        debugPrint('[OCRService] Type de document détecté: $detectedType avec un score de $maxScore');
        return detectedType;
      } else {
        debugPrint('[OCRService] Type de document non détecté (score insuffisant)');
        return null;
      }
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de la détection du type de document: $e');
      return null;
    }
  }

  // Vérifier si un document est expiré
  Future<bool?> isDocumentExpired(File imageFile, String documentType) async {
    try {
      debugPrint('[OCRService] Vérification de l\'expiration du document de type: $documentType');
      
      switch (documentType) {
        case 'permis':
          final permisInfo = await extractPermisInfo(imageFile);
          if (permisInfo != null && permisInfo['valideJusquau'] != null) {
            final DateTime valideJusquau = permisInfo['valideJusquau'];
            return valideJusquau.isBefore(DateTime.now());
          }
          break;
          
        case 'assurance':
          final assuranceInfo = await extractAssuranceInfo(imageFile);
          if (assuranceInfo != null && assuranceInfo['dateFin'] != null) {
            final DateTime dateFin = assuranceInfo['dateFin'];
            return dateFin.isBefore(DateTime.now());
          }
          break;
          
        case 'cin':
          // Les CIN tunisiennes n'ont généralement pas de date d'expiration
          return false;
          
        case 'carte_grise':
          // Les cartes grises n'ont généralement pas de date d'expiration
          return false;
      }
      
      debugPrint('[OCRService] Impossible de déterminer si le document est expiré');
      return null;
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de la vérification de l\'expiration: $e');
      return null;
    }
  }

  // Extraire automatiquement les informations en fonction du type de document
  Future<Map<String, dynamic>?> extractDocumentInfo(File imageFile) async {
    try {
      debugPrint('[OCRService] Extraction automatique des informations du document');
      
      // Détecter le type de document
      final String? documentType = await detectDocumentType(imageFile);
      
      if (documentType == null) {
        debugPrint('[OCRService] Type de document non détecté');
        return null;
      }
      
      // Extraire les informations en fonction du type
      Map<String, dynamic>? result;
      
      switch (documentType) {
        case 'permis':
          result = await extractPermisInfo(imageFile);
          break;
          
        case 'cin':
          result = await extractCINInfo(imageFile);
          break;
          
        case 'carte_grise':
          result = await extractCarteGriseInfo(imageFile);
          break;
          
        case 'assurance':
          result = await extractAssuranceInfo(imageFile);
          break;
      }
      
      if (result != null) {
        // Ajouter le type de document au résultat
        result['documentType'] = documentType;
        
        // Vérifier si le document est expiré
        final bool? isExpired = await isDocumentExpired(imageFile, documentType);
        if (isExpired != null) {
          result['isExpired'] = isExpired;
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('[OCRService] Erreur lors de l\'extraction automatique: $e');
      return null;
    }
  }

  // Libérer les ressources
  void dispose() {
    _textRecognizer.close();
  }
}