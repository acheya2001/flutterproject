import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/accident_session.dart';
import '../../models/accident_session_complete.dart';
import '../../services/accident_session_service.dart';
import '../../services/accident_session_complete_service.dart';
import '../../conducteur/screens/guest_vehicle_form_screen.dart';
import '../../conducteur/screens/multi_vehicle_constat_screen.dart';

/// 🔗 Écran pour rejoindre une session avec un code (conducteurs non-inscrits)
class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  AccidentSessionComplete? _sessionTrouvee;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une Session'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête explicatif
              _buildHeader(),
              
              const SizedBox(height: 32),
              
              // Formulaire de saisie du code
              _buildCodeForm(),
              
              const SizedBox(height: 24),
              
              // Informations sur la session trouvée
              if (_sessionTrouvee != null) _buildSessionInfo(),
              
              const Spacer(),
              
              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_add,
            color: Colors.green[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Rejoindre un Constat d\'Accident',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Saisissez le code de session que vous avez reçu pour participer au constat d\'accident.',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code de Session',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Saisissez le code',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.qr_code),
            hintText: 'ACC-2024-XXXXXX',
            suffixIcon: IconButton(
              onPressed: _rechercherSession,
              icon: const Icon(Icons.search),
              tooltip: 'Rechercher',
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir un code de session';
            }
            if (!value.trim().startsWith('ACC-')) {
              return 'Le code doit commencer par ACC-';
            }
            return null;
          },
          onChanged: (value) {
            if (_sessionTrouvee != null) {
              setState(() {
                _sessionTrouvee = null;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _rechercherSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(
              _isLoading ? 'Recherche...' : 'Rechercher la Session',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo() {
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
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Session trouvée !',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Code', _sessionTrouvee!.codeSession),
          _buildInfoRow('Véhicules impliqués', '${_sessionTrouvee!.conducteurs.length}'),
          _buildInfoRow('Statut', _getStatutText(_sessionTrouvee!.statut)),
          _buildInfoRow('Créé le', _formatDate(_sessionTrouvee!.dateCreation)),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vous allez remplir votre partie du constat sans créer de compte.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_sessionTrouvee != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _rejoindreSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.login),
              label: const Text(
                'Rejoindre la Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lien vers inscription
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/auth/register');
          },
          child: const Text(
            'Vous n\'avez pas de compte ? Inscrivez-vous',
            style: TextStyle(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Actions
  Future<void> _rechercherSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _sessionTrouvee = null;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();
      final session = await AccidentSessionCompleteService.obtenirSessionParCode(code);
      
      setState(() {
        _sessionTrouvee = session;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session introuvable: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _rejoindreSession() {
    if (_sessionTrouvee == null) return;

    // Vérifier si l'utilisateur est connecté
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Utilisateur connecté - aller directement au constat
      _naviguerVersConstat();
    } else {
      // Utilisateur non connecté - formulaire invité
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuestVehicleFormScreen(
            session: _sessionTrouvee!,
          ),
        ),
      );
    }
  }

  void _naviguerVersConstat() {
    // TODO: Déterminer le rôle de l'utilisateur dans la session
    final roleDisponible = _trouverRoleDisponible();
    
    if (roleDisponible != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiVehicleConstatScreen(
            sessionId: _sessionTrouvee!.id,
            monRole: roleDisponible,
            monVehicule: null, // Sera défini plus tard
            nombreVehicules: _sessionTrouvee!.conducteurs.length,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun rôle disponible dans cette session'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String? _trouverRoleDisponible() {
    // Trouver le premier rôle non occupé
    final rolesOccupes = _sessionTrouvee!.conducteurs.map((c) => c.roleVehicule).toList();
    final rolesDisponibles = ['A', 'B', 'C', 'D', 'E'];

    for (final role in rolesDisponibles) {
      if (!rolesOccupes.contains(role)) {
        return role;
      }
    }
    return null;
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case AccidentSession.STATUT_BROUILLON:
        return 'Brouillon';
      case AccidentSession.STATUT_PARTIES_EN_SAISIE:
        return 'En cours';
      case AccidentSession.STATUT_SIGNE_VALIDE:
        return 'Finalisé';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
