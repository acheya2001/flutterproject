import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_routes.dart';
import '../../../services/conducteur_workaround_service.dart';

/// 📝 Formulaire d'inscription conducteur - SIMPLIFIÉ (infos personnelles uniquement)
class ConducteurRegisterSimpleScreen extends ConsumerStatefulWidget {
  const ConducteurRegisterSimpleScreen({super.key});

  @override
  _ConducteurRegisterSimpleScreenState createState() => _ConducteurRegisterSimpleScreenState();
}

class _ConducteurRegisterSimpleScreenState extends ConsumerState<ConducteurRegisterSimpleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les informations personnelles UNIQUEMENT
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _cinController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Variables d'état
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _cinController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Inscription Conducteur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenue !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre compte conducteur',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Après inscription, vous pourrez faire des demandes d\'assurance depuis votre dashboard.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations personnelles', Icons.person),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _prenomController,
                label: 'Prénom',
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _nomController,
                label: 'Nom',
                icon: Icons.person,
                validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cinController,
          label: 'Numéro CIN',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'CIN requis';
            if (value!.length != 8) return 'CIN doit contenir 8 chiffres';
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _telephoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty == true ? 'Téléphone requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Email requis';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildTextField(
          controller: _adresseController,
          label: 'Adresse',
          icon: Icons.location_on,
          maxLines: 2,
          validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
        ),
        
        const SizedBox(height: 24),
        _buildSectionTitle('Mot de passe', Icons.lock),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _passwordController,
          label: 'Mot de passe',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (value) {
            if (value?.isEmpty == true) return 'Mot de passe requis';
            if (value!.length < 6) return 'Minimum 6 caractères';
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          icon: Icons.lock,
          isPassword: true,
          validator: (value) {
            if (value?.isEmpty == true) return 'Confirmation requise';
            if (value != _passwordController.text) return 'Mots de passe différents';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: isPassword ? (label.contains('Confirmer') ? _obscureConfirmPassword : _obscurePassword) : obscureText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          suffixIcon: isPassword
              ? Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Icon(
                      (label.contains('Confirmer') ? _obscureConfirmPassword : _obscurePassword)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        if (label.contains('Confirmer')) {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        } else {
                          _obscurePassword = !_obscurePassword;
                        }
                      });
                    },
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                'Créer mon compte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Utiliser le service de contournement qui fonctionne
        var result = await ConducteurWorkaroundService.inscrireConducteur(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          cin: _cinController.text.trim(),
          adresse: _adresseController.text.trim(),
        );

        // Si erreur de compatibilité Firebase, utiliser la méthode alternative
        if (result['success'] == false &&
            (result['error']?.toString().contains('PigeonUserDetails') == true ||
             result['error']?.toString().contains('compatibilité Firebase') == true)) {

          debugPrint('[UI] Utilisation de la méthode alternative d\'inscription');

          // Le service de contournement gère déjà les erreurs
          debugPrint('[UI] Service de contournement déjà utilisé');
        }

        if (result['success'] == true) {
          // Message de succès adapté selon la méthode utilisée
          final message = result['tempId'] != null
              ? '✅ Demande d\'inscription enregistrée ! Un administrateur va créer votre compte.'
              : '✅ Inscription réussie ! Vous pouvez maintenant vous connecter.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 5),
            ),
          );

          // Rediriger vers l'écran de connexion
          Navigator.pushNamed(context, AppRoutes.login);
        } else {
          setState(() {
            _errorMessage = result['error']?.toString() ?? 'Erreur lors de l\'inscription';
          });
        }
      } catch (e) {
        debugPrint('[UI] Erreur inscription: $e');

        // En cas d'erreur, essayer la méthode alternative
        try {
          // Pas besoin d'alternative, le service de contournement gère tout
          final alternativeResult = {'success': false, 'error': 'Service de contournement déjà utilisé'};

          if (alternativeResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Demande d\'inscription enregistrée ! Un administrateur va créer votre compte.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.pushNamed(context, AppRoutes.login);
          } else {
            setState(() {
              _errorMessage = alternativeResult['error']?.toString() ?? 'Erreur lors de l\'inscription';
            });
          }
        } catch (alternativeError) {
          setState(() {
            _errorMessage = 'Erreur lors de l\'inscription: $alternativeError';
          });
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
