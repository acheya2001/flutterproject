import 'package:flutter/material.dart';
import '../models/constat_officiel_model.dart';

/// 📋 Widget pour l'en-tête du constat (informations générales)
class ConstatHeaderWidget extends StatefulWidget {
  final ConstatOfficielModel constat;
  final TextEditingController lieuController;
  final TextEditingController heureController;
  final Function(ConstatOfficielModel) onChanged;

  const ConstatHeaderWidget({
    super.key,
    required this.constat,
    required this.lieuController,
    required this.heureController,
    required this.onChanged,
  });

  @override
  State<ConstatHeaderWidget> createState() => _ConstatHeaderWidgetState();
}

class _ConstatHeaderWidgetState extends State<ConstatHeaderWidget> {
  bool? _blesses;
  bool? _degatsMateriels;
  bool? _temoins;

  @override
  void initState() {
    super.initState();
    _blesses = widget.constat.blesses;
    _degatsMateriels = widget.constat.degatsMateriels;
    _temoins = widget.constat.temoins;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête officiel
        _buildOfficialHeader(),
        
        const SizedBox(height: 24),
        
        // Date de l'accident
        _buildDateSection(),
        
        const SizedBox(height: 24),
        
        // Lieu de l'accident
        _buildLieuSection(),
        
        const SizedBox(height: 24),
        
        // Questions générales
        _buildQuestionsSection(),
        
        const SizedBox(height: 24),
        
        // Informations sur les véhicules
        _buildVehiclesInfo(),
      ],
    );
  }

  Widget _buildOfficialHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Constat amiable d\'accident automobile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'À remplir par les conducteurs lors de tout accident matériel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Date de l\'accident',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[100],
                        ),
                        child: Text(
                          _formatDate(widget.constat.dateAccident),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Heure'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: widget.heureController,
                        decoration: const InputDecoration(
                          hintText: 'HH:MM',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _updateHeure,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLieuSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. Lieu de l\'accident',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: widget.lieuController,
              decoration: const InputDecoration(
                hintText: 'Adresse complète du lieu de l\'accident',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: _updateLieu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. Blessés',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            _buildYesNoQuestion(
              'Y a-t-il des blessés (même légers) ?',
              _blesses,
              (value) {
                if (mounted) setState(() {
                  _blesses = value;
                });
                _updateConstat();
              },
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '4. Dégâts matériels à d\'autres véhicules ou objets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            _buildYesNoQuestion(
              'Y a-t-il des dégâts matériels autres que ceux aux véhicules A et B ?',
              _degatsMateriels,
              (value) {
                if (mounted) setState(() {
                  _degatsMateriels = value;
                });
                _updateConstat();
              },
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '5. Témoins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            _buildYesNoQuestion(
              'Y a-t-il des témoins ?',
              _temoins,
              (value) {
                if (mounted) setState(() {
                  _temoins = value;
                });
                _updateConstat();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoQuestion(String question, bool? value, Function(bool?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Oui'),
                value: true,
                groupValue: value,
                onChanged: onChanged,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Non'),
                value: false,
                groupValue: value,
                onChanged: onChanged,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehiclesInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Véhicules impliqués',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...widget.constat.parties.map((partie) => _buildVehicleCard(partie)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(ConstatPartieModel partie) {
    final color = _getPartieColor(partie.partieId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                partie.partieId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  partie.numeroImmatriculation ?? 'Immatriculation non renseignée',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${partie.marqueVehicule ?? ''} ${partie.typeVehicule ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                if (partie.nomConducteur != null)
                  Text(
                    'Conducteur: ${partie.prenomConducteur ?? ''} ${partie.nomConducteur}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (partie.isEditable)
            Icon(Icons.edit, color: color)
          else
            Icon(Icons.visibility, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Color _getPartieColor(String partieId) {
    switch (partieId) {
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.purple;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateHeure(String value) {
    final updatedConstat = widget.constat.copyWith(heureAccident: value);
    widget.onChanged(updatedConstat);
  }

  void _updateLieu(String value) {
    final updatedConstat = widget.constat.copyWith(lieuAccident: value);
    widget.onChanged(updatedConstat);
  }

  void _updateConstat() {
    final updatedConstat = widget.constat.copyWith(
      blesses: _blesses,
      degatsMateriels: _degatsMateriels,
      temoins: _temoins,
    );
    widget.onChanged(updatedConstat);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}


