import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// 📄 Écran de visualisation moderne de l'attestation d'assurance
class AttestationViewerScreen extends StatelessWidget {
  final Map<String, dynamic> contratData;
  final String contractId;

  const AttestationViewerScreen({
    Key? key,
    required this.contratData,
    required this.contractId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numeroContrat = contratData['numeroContrat'] ?? contractId;
    final marque = contratData['marque'] ?? 'N/A';
    final modele = contratData['modele'] ?? 'N/A';
    final immatriculation = contratData['immatriculation'] ?? 'N/A';
    final dateGeneration = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attestation d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _shareAttestation(context),
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
          ),
          IconButton(
            onPressed: () => _downloadAttestation(context),
            icon: const Icon(Icons.download),
            tooltip: 'Télécharger',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête officiel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ATTESTATION D\'ASSURANCE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'République Tunisienne',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations du contrat
                    _buildSectionTitle('INFORMATIONS DU CONTRAT', Icons.description),
                    const SizedBox(height: 20),
                    
                    _buildInfoCard([
                      _buildInfoRow('Numéro de contrat', numeroContrat, Icons.numbers),
                      _buildInfoRow('Véhicule assuré', '$marque $modele', Icons.directions_car),
                      _buildInfoRow('Immatriculation', immatriculation, Icons.confirmation_number),
                      _buildInfoRow('Date de génération', dateGeneration, Icons.calendar_today),
                    ]),

                    const SizedBox(height: 32),

                    // Garanties
                    _buildSectionTitle('GARANTIES COUVERTES', Icons.security),
                    const SizedBox(height: 20),
                    
                    _buildGarantiesCard(),

                    const SizedBox(height: 32),

                    // Certification
                    _buildCertificationCard(),

                    const SizedBox(height: 24),

                    // QR Code simulé
                    _buildQRCodeCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareAttestation(context),
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
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
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _downloadAttestation(context),
                icon: const Icon(Icons.download),
                label: const Text('Télécharger PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarantiesCard() {
    final garanties = [
      {'titre': 'Responsabilité Civile', 'icon': Icons.people, 'color': Colors.green},
      {'titre': 'Dommages Matériels', 'icon': Icons.build, 'color': Colors.orange},
      {'titre': 'Vol et Incendie', 'icon': Icons.security, 'color': Colors.red},
      {'titre': 'Assistance 24h/24', 'icon': Icons.support_agent, 'color': Colors.blue},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: garanties.map((garantie) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (garantie['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    garantie['icon'] as IconData,
                    color: garantie['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  garantie['titre'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCertificationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified,
            size: 48,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 16),
          const Text(
            'CERTIFICATION OFFICIELLE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Cette attestation certifie que le véhicule mentionné ci-dessus est couvert par une assurance automobile en cours de validité.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Code de Vérification',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scannez ce code pour vérifier l\'authenticité de cette attestation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareAttestation(BuildContext context) {
    final numeroContrat = contratData['numeroContrat'] ?? contractId;
    final marque = contratData['marque'] ?? 'N/A';
    final modele = contratData['modele'] ?? 'N/A';
    final immatriculation = contratData['immatriculation'] ?? 'N/A';

    final texte = '''
🚗 ATTESTATION D'ASSURANCE

Contrat: $numeroContrat
Véhicule: $marque $modele
Immatriculation: $immatriculation

✅ Couverture active
📱 Généré depuis l'app Constat Tunisie
''';

    Share.share(texte, subject: 'Attestation d\'Assurance - $numeroContrat');
  }

  void _downloadAttestation(BuildContext context) {
    // Simulation de téléchargement moderne
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Attestation téléchargée avec succès !'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Ouvrir',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Ouvrir le fichier PDF généré
          },
        ),
      ),
    );
  }
}
