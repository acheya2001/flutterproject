import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/modern_sinistre_service.dart';
import '../../common/widgets/custom_app_bar.dart';
import '../../common/widgets/gradient_background.dart';
import 'constat_form_screen.dart';

/// 🚗 Écran moderne pour conducteur inscrit rejoignant une session
class ModernJoinSessionScreen extends StatefulWidget {
  final String? codeSession;

  const ModernJoinSessionScreen({
    Key? key,
    this.codeSession,
  }) : super(key: key);

  @override
  State<ModernJoinSessionScreen> createState() => _ModernJoinSessionScreenState();
}

class _ModernJoinSessionScreenState extends State<ModernJoinSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _sessionData;
  List<Map<String, dynamic>> _vehicules = [];

  @override
  void initState() {
    super.initState();
    if (widget.codeSession != null) {
      _codeController.text = widget.codeSession!;
      _rejoindreSesssion();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _rejoindreSesssion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Vous devez être connecté');
      }

      final result = await ModernSinistreService.rejoindreSesssionInscrit(
        codeSession: _codeController.text.trim().toUpperCase(),
        conducteurId: user.uid,
      );

      if (result['success']) {
        setState(() {
          _sessionData = result['sessionData'];
          _vehicules = List<Map<String, dynamic>>.from(result['vehicules'] ?? []);
        });

        if (_vehicules.isEmpty) {
          _showNoVehiclesDialog();
        } else {
          _showVehicleSelectionDialog();
        }
      } else {
        _showErrorDialog(result['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showVehicleSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner votre véhicule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez le véhicule impliqué dans l\'accident :'),
            const SizedBox(height: 16),
            ..._vehicules.map((vehicule) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    vehicule['marque']?.substring(0, 1).toUpperCase() ?? 'V',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('${vehicule['marque']} ${vehicule['modele']}'),
                subtitle: Text('${vehicule['immatriculation']} • ${vehicule['annee']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _continuerAvecVehicule(vehicule),
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _continuerAvecVehicule(Map<String, dynamic> vehicule) {
    Navigator.pop(context); // Fermer le dialog
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConstatFormScreen(
          sessionData: _sessionData!,
          vehiculeSelectionne: vehicule,
          isInscrit: true,
        ),
      ),
    );
  }

  void _showNoVehiclesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun véhicule'),
        content: const Text(
          'Vous n\'avez aucun véhicule enregistré. '
          'Veuillez d\'abord ajouter un véhicule dans votre profil.',
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Rejoindre Session',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildCodeInput(),
            const SizedBox(height: 24),
            _buildJoinButton(),
            const SizedBox(height: 32),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
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
        children: [
          Icon(
            Icons.group_add,
            size: 48,
            color: Colors.green[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Rejoindre un Constat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'En tant que conducteur inscrit, vos informations seront pré-remplies',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
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
          Text(
            'Code de la session',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'Ex: ABC123',
              prefixIcon: const Icon(Icons.qr_code),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir le code';
              }
              if (value.trim().length < 6) {
                return 'Le code doit contenir au moins 6 caractères';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _rejoindreSesssion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Rejoindre la Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Avantages conducteur inscrit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('✓ Informations personnelles pré-remplies'),
          _buildInfoItem('✓ Véhicules et contrats automatiquement chargés'),
          _buildInfoItem('✓ Accès aux formulaires partagés'),
          _buildInfoItem('✓ Consultation du croquis de l\'accident'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 14,
        ),
      ),
    );
  }
}
