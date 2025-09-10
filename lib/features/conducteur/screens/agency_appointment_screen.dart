import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🏢 Écran pour prendre rendez-vous à l'agence
class AgencyAppointmentScreen extends StatefulWidget {
  final String agenceId;
  final Map<String, dynamic>? demandeData;

  const AgencyAppointmentScreen({
    Key? key,
    required this.agenceId,
    this.demandeData,
  }) : super(key: key);

  @override
  State<AgencyAppointmentScreen> createState() => _AgencyAppointmentScreenState();
}

class _AgencyAppointmentScreenState extends State<AgencyAppointmentScreen> {
  Map<String, dynamic>? _agenceData;
  bool _isLoading = true;
  DateTime? _selectedDate;
  String? _selectedTime;
  String _motif = 'Finalisation contrat d\'assurance';
  
  final List<String> _availableTimes = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
  ];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgenceData();
    });
  }

  Future<void> _loadAgenceData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('agences_assurance')
          .doc(widget.agenceId)
          .get();
      
      if (doc.exists) {
        if (mounted) setState(() {
          _agenceData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur lors du chargement de l\'agence: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Rendez-vous à l\'agence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _buildContent() {
    if (_agenceData == null) {
      return const Center(
        child: Text('Agence non trouvée'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAgencyInfo(),
          const SizedBox(height: 24),
          _buildAppointmentForm(),
          const SizedBox(height: 24),
          _buildPaymentInfo(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAgencyInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: Color(0xFF3B82F6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _agenceData!['nom'] ?? 'Agence',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _agenceData!['compagnieNom'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.location_on, 'Adresse', _agenceData!['adresse'] ?? 'N/A'),
          _buildInfoRow(Icons.phone, 'Téléphone', _agenceData!['telephone'] ?? 'N/A'),
          _buildInfoRow(Icons.access_time, 'Horaires', 'Lun-Ven: 8h30-17h30'),
          _buildInfoRow(Icons.person, 'Responsable', _agenceData!['responsable'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Prendre rendez-vous',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Sélection de la date
          const Text(
            'Choisir une date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? const Color(0xFF1F2937) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Sélection de l'heure
          const Text(
            'Choisir un créneau',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTimes.map((time) => _buildTimeChip(time)).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Motif
          const Text(
            'Motif du rendez-vous',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _motif,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
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

  Widget _buildTimeChip(String time) {
    final isSelected = _selectedTime == time;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informations de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💰 Paiement sur site uniquement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le paiement de votre prime d\'assurance se fait directement à l\'agence lors de votre rendez-vous.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '📋 Documents à apporter :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Carte d\'identité\n• Permis de conduire\n• Carte grise du véhicule\n• Ancien contrat (si renouvellement)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canConfirmAppointment() ? _confirmAppointment : null,
            icon: const Icon(Icons.check_circle),
            label: const Text(
              'Confirmer le rendez-vous',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _callAgency,
            icon: const Icon(Icons.phone),
            label: const Text('Appeler l\'agence'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.map),
            label: const Text('Voir sur la carte'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canConfirmAppointment() {
    return _selectedDate != null && _selectedTime != null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmAppointment() async {
    if (!_canConfirmAppointment()) return;
    
    try {
      // Créer le rendez-vous dans Firestore
      await FirebaseFirestore.instance.collection('appointments').add({
        'agenceId': widget.agenceId,
        'conducteurId': 'current_user_id', // TODO: Récupérer l'ID du conducteur
        'demandeId': widget.demandeData?['id'],
        'date': Timestamp.fromDate(_selectedDate!),
        'time': _selectedTime,
        'motif': _motif,
        'statut': 'confirme',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Rendez-vous confirmé'),
            content: Text(
              'Votre rendez-vous est confirmé pour le ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} à $_selectedTime.\n\nVous recevrez une confirmation par SMS.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la confirmation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callAgency() async {
    final phone = _agenceData!['telephone'];
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _openMaps() async {
    final address = _agenceData!['adresse'];
    if (address != null) {
      final uri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}

