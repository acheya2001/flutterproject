import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import '../../../services/admin_agence_expert_service.dart';

/// 🔧 Écran de création d'expert
class CreateExpertScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;

  const CreateExpertScreen({
    Key? key,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<CreateExpertScreen> createState() => _CreateExpertScreenState();
}

class _CreateExpertScreenState extends State<CreateExpertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _cinController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _numeroLicenceController = TextEditingController();

  List<String> _selectedSpecialites = [];
  List<String> _selectedGouvernorats = [];
  bool _isLoading = false;
  bool _emailGenerated = false;

  // Listes des options
  final List<String> _specialitesDisponibles = [
    'automobile',
    'incendie',
    'vol',
    'degats_eaux',
    'bris_glace',
    'catastrophes_naturelles',
    'responsabilite_civile',
    'dommages_corporels',
  ];

  final List<String> _gouvernoratsDisponibles = [
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Médenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kébili',
  ];

  @override
  void initState() {
    super.initState();
    _prenomController.addListener(_generateEmailIfNeeded);
    _nomController.addListener(_generateEmailIfNeeded);
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _cinController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _numeroLicenceController.dispose();
    super.dispose();
  }

  /// 📧 Générer l'email automatiquement
  void _generateEmailIfNeeded() {
    if (_prenomController.text.isNotEmpty && _nomController.text.isNotEmpty && !_emailGenerated) {
      final prenom = _prenomController.text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final nom = _nomController.text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final agence = widget.agenceData['nom'].toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      
      _emailController.text = '$prenom.$nom.expert@$agence.tn';
      _emailGenerated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Créer un Expert'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations Personnelles'),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations Professionnelles'),
              _buildProfessionalInfoSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Spécialités'),
              _buildSpecialitesSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Zones d\'Intervention'),
              _buildGouvernoratsSection(),
              const SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Titre de section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  /// 👤 Section informations personnelles
  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telephoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              border: OutlineInputBorder(),
              prefixText: '+216 ',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le téléphone est requis';
              }
              if (value.length != 8) {
                return 'Le numéro doit contenir 8 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cinController,
            decoration: const InputDecoration(
              labelText: 'CIN *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le CIN est requis';
              }
              if (value.length != 8) {
                return 'Le CIN doit contenir 8 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _emailGenerated = false;
                  _generateEmailIfNeeded();
                },
                tooltip: 'Régénérer l\'email',
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format d\'email invalide';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// 💼 Section informations professionnelles
  Widget _buildProfessionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _numeroLicenceController,
            decoration: const InputDecoration(
              labelText: 'Numéro de Licence',
              border: OutlineInputBorder(),
              helperText: 'Laissez vide pour génération automatique',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agence d\'affectation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.agenceData['nom'] ?? 'Agence non définie',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Code: ${widget.agenceData['code'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔧 Section spécialités
  Widget _buildSpecialitesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Sélectionnez les spécialités de l\'expert *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialitesDisponibles.map((specialite) {
              final isSelected = _selectedSpecialites.contains(specialite);
              return FilterChip(
                label: Text(_getSpecialiteDisplayName(specialite)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecialites.add(specialite);
                    } else {
                      _selectedSpecialites.remove(specialite);
                    }
                  });
                },
                selectedColor: const Color(0xFF667EEA).withOpacity(0.2),
                checkmarkColor: const Color(0xFF667EEA),
              );
            }).toList(),
          ),
          if (_selectedSpecialites.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Veuillez sélectionner au moins une spécialité',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🗺️ Section gouvernorats
  Widget _buildGouvernoratsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Zones d\'intervention *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gouvernoratsDisponibles.map((gouvernorat) {
              final isSelected = _selectedGouvernorats.contains(gouvernorat);
              return FilterChip(
                label: Text(gouvernorat),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGouvernorats.add(gouvernorat);
                    } else {
                      _selectedGouvernorats.remove(gouvernorat);
                    }
                  });
                },
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                checkmarkColor: const Color(0xFF10B981),
              );
            }).toList(),
          ),
          if (_selectedGouvernorats.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Veuillez sélectionner au moins une zone d\'intervention',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ Bouton de création
  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createExpert,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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
                'Créer l\'Expert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// 🏷️ Nom d'affichage des spécialités
  String _getSpecialiteDisplayName(String specialite) {
    switch (specialite) {
      case 'automobile':
        return 'Automobile';
      case 'incendie':
        return 'Incendie';
      case 'vol':
        return 'Vol';
      case 'degats_eaux':
        return 'Dégâts des eaux';
      case 'bris_glace':
        return 'Bris de glace';
      case 'catastrophes_naturelles':
        return 'Catastrophes naturelles';
      case 'responsabilite_civile':
        return 'Responsabilité civile';
      case 'dommages_corporels':
        return 'Dommages corporels';
      default:
        return specialite;
    }
  }

  /// ✅ Créer l'expert
  Future<void> _createExpert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecialites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une spécialité'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGouvernorats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une zone d\'intervention'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AdminAgenceExpertService.createExpert(
        agenceId: widget.agenceData['id'],
        agenceNom: widget.agenceData['nom'],
        compagnieId: widget.agenceData['compagnieId'],
        compagnieNom: widget.agenceData['compagnieNom'],
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        cin: _cinController.text.trim(),
        specialites: _selectedSpecialites,
        gouvernoratsIntervention: _selectedGouvernorats,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        adresse: _adresseController.text.trim().isNotEmpty ? _adresseController.text.trim() : null,
        numeroLicence: _numeroLicenceController.text.trim().isNotEmpty ? _numeroLicenceController.text.trim() : null,
      );

      if (result['success']) {
        _showSuccessDialog(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Afficher le dialogue de succès
  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '✅ Expert créé',
          style: TextStyle(fontSize: 14),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCopyableField('Nom', result['displayName']),
                const SizedBox(height: 6),
                _buildCopyableField('Email', result['email']),
                const SizedBox(height: 6),
                _buildCopyableField('Mot de passe', result['password']),
                const SizedBox(height: 6),
                _buildCopyableField('Code Expert', result['codeExpert']),
                const SizedBox(height: 6),
                _buildCopyableField('Licence', result['numeroLicence']),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    '⚠️ Notez ces informations et transmettez-les à l\'expert.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copyAllCredentials(result),
                    icon: const Icon(Icons.copy_all, size: 14),
                    label: const Text(
                      'Copier tout',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context, true); // Retourner à la liste
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminé'),
          ),
        ],
      ),
    );
  }

  /// 📋 Créer un champ copiable
  Widget _buildCopyableField(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(value, label),
          icon: const Icon(Icons.copy, size: 14),
          tooltip: 'Copier $label',
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          padding: const EdgeInsets.all(2),
        ),
      ],
    );
  }

  /// 📋 Copier dans le presse-papiers
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copié dans le presse-papiers'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 📋 Copier toutes les informations d'identification
  void _copyAllCredentials(Map<String, dynamic> result) {
    final credentials = '''
=== INFORMATIONS EXPERT ===
Nom: ${result['displayName']}
Email: ${result['email']}
Mot de passe: ${result['password']}
Code Expert: ${result['codeExpert']}
Numéro de Licence: ${result['numeroLicence']}

⚠️ Ces informations sont confidentielles et doivent être transmises de manière sécurisée à l'expert.
''';

    Clipboard.setData(ClipboardData(text: credentials));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les informations copiées dans le presse-papiers'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }
}
