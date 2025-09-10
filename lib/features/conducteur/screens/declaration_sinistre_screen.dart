import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// 🚨 Écran de déclaration de sinistre
class DeclarationSinistreScreen extends StatefulWidget {
  final Map<String, dynamic> vehicule;

  const DeclarationSinistreScreen({
    Key? key,
    required this.vehicule,
  }) : super(key: key);

  @override
  State<DeclarationSinistreScreen> createState() => _DeclarationSinistreScreenState();
}

class _DeclarationSinistreScreenState extends State<DeclarationSinistreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _circonstancesController = TextEditingController();
  final _degatsController = TextEditingController();
  final _temoinsController = TextEditingController();

  String _typeSinistre = 'accident';
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    // Initialiser l'heure sans context
    _heureController.text = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _descriptionController.dispose();
    _circonstancesController.dispose();
    _degatsController.dispose();
    _temoinsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Déclaration de Sinistre',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du véhicule
              _buildVehiculeInfo(),
              
              const SizedBox(height: 24),
              
              // Type de sinistre
              _buildTypeSinistreSection(),
              
              const SizedBox(height: 24),
              
              // Date et heure
              _buildDateHeureSection(),
              
              const SizedBox(height: 24),
              
              // Lieu
              _buildLieuSection(),
              
              const SizedBox(height: 24),
              
              // Description
              _buildDescriptionSection(),
              
              const SizedBox(height: 24),
              
              // Circonstances
              _buildCirconstancesSection(),
              
              const SizedBox(height: 24),
              
              // Dégâts
              _buildDegatsSection(),
              
              const SizedBox(height: 24),
              
              // Témoins
              _buildTemoinsSection(),
              
              const SizedBox(height: 32),
              
              // Bouton de soumission
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehiculeInfo() {
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
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Véhicule Concerné',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.vehicule['marque']} ${widget.vehicule['modele']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Immatriculation: ${widget.vehicule['immatriculation']}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Contrat N°: ${widget.vehicule['numeroContrat']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSinistreSection() {
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
          Row(
            children: [
              Icon(Icons.category, color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Type de Sinistre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTypeChip('accident', 'Accident', Icons.car_crash),
              _buildTypeChip('vol', 'Vol', Icons.security),
              _buildTypeChip('incendie', 'Incendie', Icons.local_fire_department),
              _buildTypeChip('vandalisme', 'Vandalisme', Icons.warning),
              _buildTypeChip('catastrophe', 'Catastrophe Naturelle', Icons.thunderstorm),
              _buildTypeChip('autre', 'Autre', Icons.help_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _typeSinistre == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _typeSinistre = value);
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selectedColor: Colors.red[100],
      checkmarkColor: Colors.red[700],
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildDateHeureSection() {
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
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Date et Heure du Sinistre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heureController,
                  decoration: const InputDecoration(
                    labelText: 'Heure',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: _selectTime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une heure';
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

  Widget _buildLieuSection() {
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
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Lieu du Sinistre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lieuController,
            decoration: const InputDecoration(
              labelText: 'Adresse précise du sinistre',
              prefixIcon: Icon(Icons.place),
              border: OutlineInputBorder(),
              hintText: 'Ex: Avenue Habib Bourguiba, Tunis',
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez indiquer le lieu du sinistre';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
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
          Row(
            children: [
              Icon(Icons.description, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Description du Sinistre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Décrivez ce qui s\'est passé',
              border: OutlineInputBorder(),
              hintText: 'Décrivez les faits de manière précise et chronologique...',
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez décrire le sinistre';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCirconstancesSection() {
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
          Row(
            children: [
              Icon(Icons.info, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Circonstances',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _circonstancesController,
            decoration: const InputDecoration(
              labelText: 'Conditions météo, circulation, etc.',
              border: OutlineInputBorder(),
              hintText: 'Ex: Temps pluvieux, circulation dense, visibilité réduite...',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDegatsSection() {
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
          Row(
            children: [
              Icon(Icons.build, color: Colors.red[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Dégâts Constatés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _degatsController,
            decoration: const InputDecoration(
              labelText: 'Décrivez les dégâts sur votre véhicule',
              border: OutlineInputBorder(),
              hintText: 'Ex: Pare-choc avant enfoncé, phare cassé, rayures sur la portière...',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez décrire les dégâts';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemoinsSection() {
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
          Row(
            children: [
              Icon(Icons.people, color: Colors.teal[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Témoins (Optionnel)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _temoinsController,
            decoration: const InputDecoration(
              labelText: 'Noms et contacts des témoins',
              border: OutlineInputBorder(),
              hintText: 'Ex: Ahmed Ben Ali - 98 123 456',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitDeclaration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Déclarer le Sinistre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      if (mounted) setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _heureController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitDeclaration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Créer la déclaration de sinistre
      await FirebaseFirestore.instance.collection('sinistres').add({
        'conducteurId': user.uid,
        'vehiculeId': widget.vehicule['id'],
        'contratId': widget.vehicule['contratId'],
        'numeroContrat': widget.vehicule['numeroContrat'],
        'typeSinistre': _typeSinistre,
        'dateSinistre': Timestamp.fromDate(_selectedDate),
        'heureSinistre': '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'lieu': _lieuController.text.trim(),
        'description': _descriptionController.text.trim(),
        'circonstances': _circonstancesController.text.trim(),
        'degats': _degatsController.text.trim(),
        'temoins': _temoinsController.text.trim(),
        'statut': 'en_attente_expertise',
        'dateDeclaration': FieldValue.serverTimestamp(),
        'vehiculeInfo': {
          'marque': widget.vehicule['marque'],
          'modele': widget.vehicule['modele'],
          'immatriculation': widget.vehicule['immatriculation'],
        },
      });

      // Afficher le succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sinistre déclaré avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner à l'écran précédent
      Navigator.pop(context);
      
    } catch (e) {
      print('❌ Erreur déclaration sinistre: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

