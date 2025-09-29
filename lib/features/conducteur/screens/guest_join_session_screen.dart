import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/collaborative_session_service.dart';
import '../../../models/collaborative_session_model.dart';
import 'guest_accident_form_screen.dart';
import 'guest_combined_form_screen.dart';

/// 🔤 Formatter pour convertir le texte en majuscules
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// 🎯 Écran pour rejoindre une session en tant qu'invité (conducteur non inscrit)
class GuestJoinSessionScreen extends StatefulWidget {
  const GuestJoinSessionScreen({Key? key}) : super(key: key);

  @override
  State<GuestJoinSessionScreen> createState() => _GuestJoinSessionScreenState();
}

class _GuestJoinSessionScreenState extends State<GuestJoinSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Rejoindre en tant qu\'Invité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête informatif
              _buildHeader(),
              
              const SizedBox(height: 32),
              
              // Section code de session
              _buildCodeSection(),
              
              const SizedBox(height: 32),
              
              // Informations importantes
              _buildInfoSection(),
              
              const SizedBox(height: 40),
              
              // Bouton rejoindre
              _buildJoinButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 En-tête informatif
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Rejoindre une Session Collaborative',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Vous pouvez rejoindre une session d\'accident existante en tant qu\'invité sans avoir besoin de créer un compte. '
            'Vous pourrez remplir toutes les informations nécessaires pour le constat.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔢 Section code de session
  Widget _buildCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code de Session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'Entrez le code de session (lettres et chiffres)',
              prefixIcon: Icon(Icons.qr_code, color: Colors.green[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(10), // Augmenté pour codes plus longs
              UpperCaseTextFormatter(), // Convertir en majuscules
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le code de session';
              }
              if (value.length < 4) {
                return 'Le code doit contenir au moins 4 caractères';
              }
              if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
                return 'Le code ne peut contenir que des lettres et des chiffres';
              }
              return null;
            },
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Demandez le code de session (lettres et chiffres) au conducteur qui a créé l\'accident',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ℹ️ Section informations importantes
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informations importantes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Vous devrez saisir manuellement toutes vos informations'),
          _buildInfoItem('Informations personnelles, véhicule et assurance'),
          _buildInfoItem('Vous pourrez collaborer sur le croquis de l\'accident'),
          _buildInfoItem('Toutes vos données seront sécurisées'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 Bouton rejoindre
  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _rejoindreSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Rejoindre la Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// 🔗 Rejoindre la session
  Future<void> _rejoindreSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim();
      
      // Rechercher la session par code
      final session = await CollaborativeSessionService.obtenirSessionParCode(code);
      
      if (session == null) {
        _showErrorDialog('Session introuvable', 
            'Aucune session trouvée avec ce code. Vérifiez le code et réessayez.');
        return;
      }

      // Vérifier si la session accepte encore des participants
      if (session.statut == SessionStatus.finalise) {
        _showErrorDialog('Session terminée', 
            'Cette session est déjà terminée et n\'accepte plus de nouveaux participants.');
        return;
      }

      // Naviguer vers le formulaire combiné pour invité (assurance + constat)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GuestCombinedFormScreen(
            session: session,
          ),
        ),
      );

    } catch (e) {
      print('Erreur lors de la recherche de session: $e');
      _showErrorDialog('Erreur', 
          'Une erreur est survenue lors de la recherche de la session. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ❌ Afficher dialog d'erreur
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
