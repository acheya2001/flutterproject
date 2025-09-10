import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'modern_single_accident_info_screen.dart';

/// 🔗 Écran pour rejoindre une session - Conducteur inscrit
class JoinSessionRegisteredScreen extends StatefulWidget {
  const JoinSessionRegisteredScreen({Key? key}) : super(key: key);

  @override
  State<JoinSessionRegisteredScreen> createState() => _JoinSessionRegisteredScreenState();
}

class _JoinSessionRegisteredScreenState extends State<JoinSessionRegisteredScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rejoindre une session'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // En-tête avec icône
            _buildHeader(),
            
            const SizedBox(height: 40),
            
            // Champ de saisie du code
            _buildCodeInput(),
            
            const SizedBox(height: 32),
            
            // Instructions
            _buildInstructions(),
            
            const SizedBox(height: 40),
            
            // Bouton rejoindre
            _buildJoinButton(),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
    );
  }

  /// 🎯 En-tête avec icône
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🔗',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Rejoindre une session',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Saisissez le code de session partagé par l\'autre conducteur',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🔢 Champ de saisie du code
  Widget _buildCodeInput() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            'Code de session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'Ex: ABC12345',
              prefixIcon: Icon(Icons.qr_code, color: Colors.blue[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            onChanged: (value) {
              if (mounted) setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 📋 Instructions
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Comment ça marche ?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. L\'autre conducteur vous partage un code de session\n'
            '2. Saisissez ce code dans le champ ci-dessus\n'
            '3. Vous accéderez au formulaire de constat partagé\n'
            '4. Vos informations personnelles seront pré-remplies\n'
            '5. Vous pourrez voir et valider les informations communes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// ▶️ Bouton rejoindre
  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _joinSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Rejoindre la session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// ❌ Message d'erreur
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔗 Rejoindre la session
  Future<void> _joinSession() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      if (mounted) setState(() {
        _errorMessage = 'Veuillez saisir un code de session';
      });
      return;
    }

    if (code.length < 6) {
      if (mounted) setState(() {
        _errorMessage = 'Le code doit contenir au moins 6 caractères';
      });
      return;
    }

    if (mounted) setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Rechercher la session par code
      final sessionQuery = await FirebaseFirestore.instance
          .collection('accident_sessions_complete')
          .where('sessionCode', isEqualTo: code)
          .where('statut', whereIn: ['en_attente_participants', 'en_cours_remplissage'])
          .limit(1)
          .get();

      if (sessionQuery.docs.isEmpty) {
        if (mounted) setState(() {
          _errorMessage = 'Code de session invalide ou session expirée';
          _isLoading = false;
        });
        return;
      }

      final sessionDoc = sessionQuery.docs.first;
      final sessionData = sessionDoc.data();
      
      // Vérifier que l'utilisateur n'est pas déjà dans la session
      final user = FirebaseAuth.instance.currentUser!;
      final participants = List<String>.from(sessionData['participants'] ?? []);
      
      if (participants.contains(user.uid)) {
        if (mounted) setState(() {
          _errorMessage = 'Vous participez déjà à cette session';
          _isLoading = false;
        });
        return;
      }

      // Ajouter l'utilisateur à la session
      final nextLetter = String.fromCharCode(65 + participants.length); // A, B, C, D...
      
      await sessionDoc.reference.update({
        'participants': FieldValue.arrayUnion([user.uid]),
        'participantLetters.${user.uid}': nextLetter,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Naviguer vers le formulaire de constat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModernSingleAccidentInfoScreen(
            typeAccident: 'Collision entre deux véhicules',
          ),
        ),
      );

    } catch (e) {
      if (mounted) setState(() {
        _errorMessage = 'Erreur lors de la connexion à la session: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

