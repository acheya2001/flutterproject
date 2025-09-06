import 'package:flutter/material.dart';
import '../../models/accident_session.dart';
import '../../models/vehicule_model.dart';
import 'constat_section_screen.dart';

/// 👤 Formulaire pour conducteur non-inscrit (plus d'informations requises)
class GuestVehicleFormScreen extends StatefulWidget {
  final AccidentSession session;

  const GuestVehicleFormScreen({
    super.key,
    required this.session,
  });

  @override
  State<GuestVehicleFormScreen> createState() => _GuestVehicleFormScreenState();
}

class _GuestVehicleFormScreenState extends State<GuestVehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Informations personnelles
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();

  // Informations véhicule
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();

  // Informations assurance
  final _compagnieController = TextEditingController();
  final _numeroPoliceController = TextEditingController();
  final _agenceController = TextEditingController();
  DateTime? _dateDebutAssurance;
  DateTime? _dateFinAssurance;

  String? _roleAssigne;

  @override
  void initState() {
    super.initState();
    _determinerRole();
  }

  void _determinerRole() {
    // Trouver le premier rôle disponible
    for (final role in widget.session.rolesDisponibles) {
      if (role != 'A' && !widget.session.identitesVehicules.containsKey(role)) {
        _roleAssigne = role;
        break;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    _compagnieController.dispose();
    _numeroPoliceController.dispose();
    _agenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_roleAssigne == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session Complète'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Cette session est complète.\nTous les rôles sont déjà attribués.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Véhicule $_roleAssigne - Informations'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildEtapePersonnelle(),
                _buildEtapeVehicule(),
                _buildEtapeAssurance(),
              ],
            ),
          ),
          
          // Navigation
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _roleAssigne!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Véhicule $_roleAssigne',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Conducteur non-inscrit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${_currentStep + 1} sur 3',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapePersonnelle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vos Informations Personnelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ces informations sont nécessaires pour le constat officiel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nom requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prénom requis';
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
                labelText: 'Numéro de téléphone *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '+216 XX XXX XXX',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Téléphone requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Adresse requise';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ces informations ne seront utilisées que pour ce constat et ne créeront pas de compte automatiquement.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtapeVehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du Véhicule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Détails de votre véhicule impliqué dans l\'accident',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _marqueController,
                  decoration: const InputDecoration(
                    labelText: 'Marque *',
                    border: OutlineInputBorder(),
                    hintText: 'Peugeot, Renault...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Marque requise';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _modeleController,
                  decoration: const InputDecoration(
                    labelText: 'Modèle *',
                    border: OutlineInputBorder(),
                    hintText: '208, Clio...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Modèle requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _immatriculationController,
            decoration: const InputDecoration(
              labelText: 'Numéro d\'immatriculation *',
              border: OutlineInputBorder(),
              hintText: '123 TUN 456',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Immatriculation requise';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _couleurController,
                  decoration: const InputDecoration(
                    labelText: 'Couleur *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Couleur requise';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _anneeController,
                  decoration: const InputDecoration(
                    labelText: 'Année *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Année requise';
                    }
                    final annee = int.tryParse(value);
                    if (annee == null || annee < 1990 || annee > DateTime.now().year) {
                      return 'Année invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeAssurance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations d\'Assurance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Détails de votre contrat d\'assurance automobile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _compagnieController,
            decoration: const InputDecoration(
              labelText: 'Compagnie d\'assurance *',
              border: OutlineInputBorder(),
              hintText: 'STAR, AMI, COMAR...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Compagnie requise';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _numeroPoliceController,
            decoration: const InputDecoration(
              labelText: 'Numéro de police *',
              border: OutlineInputBorder(),
              hintText: 'Numéro de votre contrat',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Numéro de police requis';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _agenceController,
            decoration: const InputDecoration(
              labelText: 'Agence d\'assurance',
              border: OutlineInputBorder(),
              hintText: 'Nom de l\'agence (optionnel)',
            ),
          ),

          const SizedBox(height: 16),

          // Dates d'assurance
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectionnerDateDebut,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Début d\'assurance *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateDebutAssurance != null
                          ? '${_dateDebutAssurance!.day}/${_dateDebutAssurance!.month}/${_dateDebutAssurance!.year}'
                          : 'Sélectionner',
                      style: TextStyle(
                        color: _dateDebutAssurance != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectionnerDateFin,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fin d\'assurance *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateFinAssurance != null
                          ? '${_dateFinAssurance!.day}/${_dateFinAssurance!.month}/${_dateFinAssurance!.year}'
                          : 'Sélectionner',
                      style: TextStyle(
                        color: _dateFinAssurance != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Important',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assurez-vous que votre assurance est valide à la date de l\'accident. '
                  'Ces informations seront vérifiées par les compagnies d\'assurance.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
