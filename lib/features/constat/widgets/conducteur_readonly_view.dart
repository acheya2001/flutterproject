import 'package:flutter/material.dart';
import '../models/conducteur_session_info.dart';

/// 👁️ Widget de visualisation en lecture seule des informations d'un conducteur
/// 
/// Permet à un conducteur de voir les informations saisies par un autre
/// conducteur sans pouvoir les modifier.
class ConducteurReadonlyView extends StatelessWidget {
  final ConducteurSessionInfo conducteurInfo;
  final String position;
  final String title;

  const ConducteurReadonlyView({
    Key? key,
    required this.conducteurInfo,
    required this.position,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (conducteurInfo.hasJoined && conducteurInfo.conducteurInfo != null) ...[
            _buildConducteurSection(context),
            if (conducteurInfo.vehiculeInfo != null) _buildVehiculeSection(context),
            if (conducteurInfo.assuranceInfo != null) _buildAssuranceSection(context),
            if (!conducteurInfo.isProprietaire && conducteurInfo.proprietaireInfo != null)
              _buildProprietaireSection(context),
            if (conducteurInfo.circonstances?.isNotEmpty == true) _buildCirconstancesSection(context),
            if (conducteurInfo.degatsApparents?.isNotEmpty == true) _buildDegatsSection(context),
            if (conducteurInfo.temoins?.isNotEmpty == true) _buildTemoinsSection(context),
            if (conducteurInfo.observations?.isNotEmpty == true) _buildObservationsSection(context),
            _buildPhotosSection(context),
            _buildStatusSection(context),
          ] else ...[
            _buildNotJoinedSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPositionColor(position),
            _getPositionColor(position).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              position,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      conducteurInfo.hasJoined ? Icons.check_circle : Icons.pending,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      conducteurInfo.hasJoined 
                          ? (conducteurInfo.isCompleted ? 'Terminé' : 'En cours')
                          : 'En attente',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (conducteurInfo.isCompleted)
            const Icon(
              Icons.verified,
              color: Colors.white,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildConducteurSection(BuildContext context) {
    final info = conducteurInfo.conducteurInfo!;
    return _buildSection(
      context,
      'Informations du conducteur',
      Icons.person,
      [
        _buildInfoRow('Nom', '${info.prenom} ${info.nom}'),
        _buildInfoRow('Adresse', info.adresse),
        _buildInfoRow('Téléphone', info.telephone),
        _buildInfoRow('Permis N°', info.numeroPermis),
      ],
    );
  }

  Widget _buildVehiculeSection(BuildContext context) {
    final info = conducteurInfo.vehiculeInfo!;
    return _buildSection(
      context,
      'Véhicule',
      Icons.directions_car,
      [
        _buildInfoRow('Marque', info.marque),
        _buildInfoRow('Type', info.type),
        _buildInfoRow('Immatriculation', info.numeroImmatriculation),
        if (info.venantDe.isNotEmpty) _buildInfoRow('Venant de', info.venantDe),
        if (info.allantA.isNotEmpty) _buildInfoRow('Allant à', info.allantA),
      ],
    );
  }

  Widget _buildAssuranceSection(BuildContext context) {
    final info = conducteurInfo.assuranceInfo!;
    return _buildSection(
      context,
      'Assurance',
      Icons.security,
      [
        _buildInfoRow('Société', info.societeAssurance),
        _buildInfoRow('N° Contrat', info.numeroContrat),
        _buildInfoRow('Agence', info.agence),
      ],
    );
  }

  Widget _buildProprietaireSection(BuildContext context) {
    final info = conducteurInfo.proprietaireInfo!;
    return _buildSection(
      context,
      'Propriétaire du véhicule',
      Icons.person_outline,
      [
        _buildInfoRow('Nom', '${info.prenom ?? ''} ${info.nom ?? ''}'),
        _buildInfoRow('Adresse', info.adresse ?? ''),
        _buildInfoRow('Téléphone', info.telephone ?? ''),
      ],
    );
  }

  Widget _buildCirconstancesSection(BuildContext context) {
    return _buildSection(
      context,
      'Circonstances',
      Icons.list_alt,
      conducteurInfo.circonstances!.map((c) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(c.toString(), style: const TextStyle(fontSize: 14))),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildDegatsSection(BuildContext context) {
    return _buildSection(
      context,
      'Dégâts apparents',
      Icons.build,
      conducteurInfo.degatsApparents!.map((d) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(d, style: const TextStyle(fontSize: 14))),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildTemoinsSection(BuildContext context) {
    return _buildSection(
      context,
      'Témoins',
      Icons.people,
      conducteurInfo.temoins!.map((t) =>
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (t.adresse.isNotEmpty) Text('Adresse: ${t.adresse}'),
              if (t.telephone?.isNotEmpty == true) Text('Tél: ${t.telephone}'),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildObservationsSection(BuildContext context) {
    return _buildSection(
      context,
      'Observations',
      Icons.note,
      [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            conducteurInfo.observations!,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    final photos = <String, String?>{
      'Photos accident': conducteurInfo.photosAccidentUrls?.join(', '),
      'Permis de conduire': conducteurInfo.photoPermisUrl,
      'Carte grise': conducteurInfo.photoCarteGriseUrl,
      'Attestation assurance': conducteurInfo.photoAttestationUrl,
      'Signature': conducteurInfo.signatureUrl,
    };

    final availablePhotos = photos.entries.where((e) => e.value?.isNotEmpty == true).toList();

    if (availablePhotos.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context,
      'Documents et photos',
      Icons.photo_library,
      availablePhotos.map((entry) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 14))),
              const Icon(Icons.visibility, color: Colors.blue, size: 16),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: conducteurInfo.isCompleted 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: conducteurInfo.isCompleted ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            conducteurInfo.isCompleted ? Icons.check_circle : Icons.pending,
            color: conducteurInfo.isCompleted ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conducteurInfo.isCompleted 
                  ? 'Constat terminé et validé'
                  : 'Constat en cours de saisie',
              style: TextStyle(
                color: conducteurInfo.isCompleted ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (conducteurInfo.completedAt != null)
            Text(
              'Le ${_formatDate(conducteurInfo.completedAt!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildNotJoinedSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.pending,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'En attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            conducteurInfo.email != null 
                ? 'Invitation envoyée à ${conducteurInfo.email}'
                : 'Ce conducteur n\'a pas encore rejoint la session',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey,
                fontStyle: value.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'A': return const Color(0xFF2196F3); // Bleu
      case 'B': return const Color(0xFF4CAF50); // Vert
      case 'C': return const Color(0xFFFF9800); // Orange
      case 'D': return const Color(0xFF9C27B0); // Violet
      case 'E': return const Color(0xFFF44336); // Rouge
      case 'F': return const Color(0xFF607D8B); // Bleu gris
      default: return const Color(0xFF757575); // Gris
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
